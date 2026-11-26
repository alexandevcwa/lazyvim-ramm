---@module "plugins.java"
--- ============================================================================
--- Ecosistema Profesional de Java y Spring Boot para LazyVim
--- ============================================================================
--- Características principales:
---   1. LSP avanzado (`mfussenegger/nvim-jdtls`): resolución dinámica de JAVA_HOME
---      y detección multi-JDK desde SDKMAN, soporte Lombok, Inlay Hints,
---      static imports de Spring Boot / JUnit 5 / Mockito / AssertJ / MockMvc.
---   2. Integración Spring Tools 4 (`JavaHello/spring-boot.nvim`): autocompletado,
---      validación y navegación en `application.properties`, `application.yml` y
---      anotaciones de Spring Boot (`@Bean`, `@RestController`, `@Value`, etc.).
---   3. Motor Nativo de `.env` Automático:
---      - Parsea en caliente `.env`, `.env.local` y `.env.<profile>` en la raíz
---        del proyecto (soporta `export`, comillas, comentarios `#` e interpolación).
---      - Inyecta automáticamente las variables en `nvim-dap` (`on_config`) al
---        depurar con `<leader>dc`, `<leader>jd` o tests de JDTLS.
---      - Runner interactivo de Spring Boot (`Snacks.terminal`) que inyecta
---        todas las variables del `.env` y `JAVA_HOME` al ejecutar Maven o Gradle.
---   4. Testing (`rcasia/neotest-java`), Scaffolding (`java-creator-nvim`),
---      Spring Initializr TUI (`jkeresman01/spring-initializr.nvim`) y
---      generación de Javadoc (`neogen`).
--- ============================================================================

local uv = vim.uv or vim.loop

--- Marcadores de raíz de proyecto Java / Spring Boot
local JAVA_ROOT_MARKERS = {
  "mvnw",
  "gradlew",
  "pom.xml",
  "build.gradle",
  "build.gradle.kts",
  "settings.gradle",
  "settings.gradle.kts",
  ".project",
  ".git",
}

--- Patrones de nombres de variables sensibles para enmascarar en la vista de inspección
local SENSITIVE_KEY_PATTERNS = {
  "SECRET",
  "PASSWORD",
  "PASSWD",
  "PASS",
  "TOKEN",
  "API_KEY",
  "PRIVATE_KEY",
  "CREDENTIAL",
  "AUTH",
  "PWD",
}

--- ============================================================================
--- 1. Resolución de JAVA_HOME y Descubrimiento Multi-JDK (SDKMAN / Sistema)
--- ============================================================================

--- Resuelve dinámicamente el directorio JAVA_HOME activo (env -> SDKMAN current -> PATH)
---@return string|nil
local function resolve_java_home()
  local candidates = {}

  if vim.env.JAVA_HOME and vim.env.JAVA_HOME ~= "" then
    table.insert(candidates, vim.env.JAVA_HOME)
  end

  local sdkman_dir = vim.env.SDKMAN_DIR or ((vim.env.HOME or "") .. "/.sdkman")
  if sdkman_dir ~= "" then
    table.insert(candidates, sdkman_dir .. "/candidates/java/current")
  end

  local java_in_path = vim.fn.exepath("java")
  if java_in_path ~= "" then
    local real_java = uv.fs_realpath(java_in_path) or java_in_path
    table.insert(candidates, vim.fn.fnamemodify(real_java, ":h:h"))
  end

  for _, home in ipairs(candidates) do
    local real_home = uv.fs_realpath(home) or home
    if uv.fs_stat(real_home .. "/bin/java") then
      return real_home
    end
  end

  return nil
end

--- Descubre los JDK instalados en SDKMAN para poblar `java.configuration.runtimes`
--- permitiendo que JDTLS compile proyectos en Java 8, 11, 17, 21, etc.
---@param active_java_home string|nil
---@return table[]
local function discover_java_runtimes(active_java_home)
  local runtimes = {}
  local seen_versions = {}
  local sdkman_java_dir = (vim.env.SDKMAN_DIR or ((vim.env.HOME or "") .. "/.sdkman")) .. "/candidates/java"

  local handle = uv.fs_scandir(sdkman_java_dir)
  if handle then
    while true do
      local name, ftype = uv.fs_scandir_next(handle)
      if not name then
        break
      end
      if name ~= "current" and (ftype == "directory" or ftype == "link") then
        local jdk_path = sdkman_java_dir .. "/" .. name
        local real_path = uv.fs_realpath(jdk_path) or jdk_path
        if uv.fs_stat(real_path .. "/bin/java") then
          local major = name:match("^(%d+)")
          if major then
            local runtime_name = major == "8" and "JavaSE-1.8" or ("JavaSE-" .. major)
            if not seen_versions[runtime_name] then
              seen_versions[runtime_name] = true
              table.insert(runtimes, {
                name = runtime_name,
                path = real_path,
                default = (active_java_home ~= nil and real_path == active_java_home) or false,
              })
            end
          end
        end
      end
    end
  end

  -- Si no se detectaron candidatos por versión pero existe JAVA_HOME activo, registrarlo como JavaSE-21
  if #runtimes == 0 and active_java_home then
    table.insert(runtimes, {
      name = "JavaSE-21",
      path = active_java_home,
      default = true,
    })
  end

  return runtimes
end

--- Añade un argumento a cmd solo si ningún elemento existente comienza con el prefijo dado
---@param cmd string[]
---@param prefix string
---@param value string
local function append_flag_once(cmd, prefix, value)
  for _, arg in ipairs(cmd) do
    if vim.startswith(arg, prefix) then
      return
    end
  end
  table.insert(cmd, prefix .. value)
end

--- ============================================================================
--- 2. Motor Nativo de Lectura e Inyección Automática de Archivos `.env`
--- ============================================================================

--- Obtiene el directorio raíz del proyecto Java/Spring Boot actual
---@param start_path? string
---@return string
local function resolve_project_root(start_path)
  local search_from = start_path
  if not search_from or search_from == "" then
    local buf_name = vim.api.nvim_buf_get_name(0)
    if buf_name ~= "" and vim.bo.buftype == "" then
      search_from = vim.fn.fnamemodify(buf_name, ":p:h")
    end
  end
  search_from = search_from or uv.cwd() or vim.fn.getcwd()

  local found = vim.fs.find(JAVA_ROOT_MARKERS, { path = search_from, upward = true })[1]
  if found then
    return vim.fn.fnamemodify(found, ":p:h")
  end

  if _G.LazyVim and LazyVim.root then
    return LazyVim.root()
  end
  return uv.cwd() or vim.fn.getcwd()
end

--- Resuelve el directorio donde reside el proyecto de construcción (raíz o subcarpeta `backend/`)
---@param root? string
---@return string
local function resolve_spring_workdir(root)
  root = root or resolve_project_root()
  local root_markers = { "pom.xml", "mvnw", "build.gradle", "build.gradle.kts", "gradlew" }
  for _, m in ipairs(root_markers) do
    if uv.fs_stat(root .. "/" .. m) then
      return root
    end
  end
  for _, m in ipairs(root_markers) do
    if uv.fs_stat(root .. "/backend/" .. m) then
      return root .. "/backend"
    end
  end
  return root
end

--- Limpia comillas, secuencias de escape y comentarios inline de un valor `.env`
---@param raw_val string
---@param current_vars table<string, string>
---@return string
local function parse_dotenv_value(raw_val, current_vars)
  local val = vim.trim(raw_val)
  if val == "" then
    return ""
  end

  local first = val:sub(1, 1)
  if first == "'" then
    -- Comillas simples: valor literal sin interpolación
    local close_idx = val:find("'", 2, true)
    if close_idx then
      return val:sub(2, close_idx - 1)
    end
    return val:sub(2)
  elseif first == '"' then
    -- Comillas dobles: soporta escapes (\n, \r, \t, \") e interpolación ${VAR}
    local inner = val:match('^"(.*)"%s*#?.*$') or val:match('^"(.*)"$') or val:sub(2)
    inner = inner:gsub('\\"', '"'):gsub("\\n", "\n"):gsub("\\r", "\r"):gsub("\\t", "\t")
    inner = inner:gsub("%${([%w_]+)}", function(k)
      return current_vars[k] or vim.env[k] or ""
    end)
    return inner
  end

  -- Valor sin comillas: eliminar comentarios inline precedidos de espacio (` # ...`)
  local comment_pos = val:find("%s+#")
  if comment_pos then
    val = vim.trim(val:sub(1, comment_pos - 1))
  end

  -- Interpolación básica ${VAR} o $VAR
  val = val:gsub("%${([%w_]+)}", function(k)
    return current_vars[k] or vim.env[k] or ""
  end)

  return val
end

--- Parsea un archivo `.env` individual y fusiona sus variables en `target_vars`
---@param filepath string
---@param target_vars table<string, string>
---@param ordered_keys string[]
---@return integer added_count
local function parse_env_file(filepath, target_vars, ordered_keys)
  local stat = uv.fs_stat(filepath)
  if not stat or stat.type ~= "file" then
    return 0
  end

  local ok, lines = pcall(vim.fn.readfile, filepath)
  if not ok or type(lines) ~= "table" then
    return 0
  end

  local count = 0
  for _, raw_line in ipairs(lines) do
    local line = vim.trim(raw_line)
    if line ~= "" and not vim.startswith(line, "#") then
      -- Soportar prefijo opcional `export KEY=VALUE`
      if line:match("^export%s+") then
        line = vim.trim(line:gsub("^export%s+", "", 1))
      end

      local key, raw_val = line:match("^([%a_][%w_%.%-]*)%s*=%s*(.*)$")
      if key and raw_val then
        local parsed_val = parse_dotenv_value(raw_val, target_vars)
        if target_vars[key] == nil then
          table.insert(ordered_keys, key)
        end
        target_vars[key] = parsed_val
        count = count + 1
      end
    end
  end

  return count
end

--- Carga automáticamente las variables de `.env`, `.env.local` y `.env.<profile>`
--- buscando tanto en la raíz del proyecto como en el subdirectorio del módulo Spring Boot.
---@param root_dir? string
---@param profile? string|nil
---@return { vars: table<string, string>, keys: string[], files: string[], root: string }
local function load_project_dotenv(root_dir, profile)
  local root = root_dir or resolve_project_root()
  local workdir = resolve_spring_workdir(root)

  local candidate_dirs = { root }
  if workdir ~= root then
    table.insert(candidate_dirs, workdir)
  end

  local active_profile = profile
  local vars = {}
  local ordered_keys = {}
  local loaded_files = {}

  local base_filenames = { ".env", ".env.local" }
  for _, dir in ipairs(candidate_dirs) do
    for _, fname in ipairs(base_filenames) do
      local fpath = dir .. "/" .. fname
      local n = parse_env_file(fpath, vars, ordered_keys)
      if n > 0 then
        table.insert(loaded_files, fpath)
      end
    end
  end

  -- Si el propio .env define SPRING_PROFILES_ACTIVE y no se pasó uno explícito, usarlo
  if (not active_profile or active_profile == "") and vars.SPRING_PROFILES_ACTIVE then
    active_profile = vars.SPRING_PROFILES_ACTIVE
  end

  if active_profile and active_profile ~= "" then
    for _, dir in ipairs(candidate_dirs) do
      for _, fname in ipairs({ ".env." .. active_profile, ".env." .. active_profile .. ".local" }) do
        local fpath = dir .. "/" .. fname
        local n = parse_env_file(fpath, vars, ordered_keys)
        if n > 0 then
          table.insert(loaded_files, fpath)
        end
      end
    end
  end

  return {
    vars = vars,
    keys = ordered_keys,
    files = loaded_files,
    root = root,
  }
end

--- Determina si una clave de entorno contiene información sensible
---@param key string
---@return boolean
local function is_sensitive_key(key)
  local upper = key:upper()
  for _, pat in ipairs(SENSITIVE_KEY_PATTERNS) do
    if upper:find(pat, 1, true) then
      return true
    end
  end
  return false
end

local dap_dotenv_hook_installed = false

--- Instala el interceptor en `nvim-dap` para inyectar automáticamente las variables
--- del archivo `.env` en cualquier sesión de depuración Java (`<leader>dc`, `<leader>jd`, tests).
local function install_dap_dotenv_hook()
  if dap_dotenv_hook_installed then
    return
  end

  local ok_dap, dap = pcall(require, "dap")
  if not ok_dap or type(dap) ~= "table" then
    return
  end

  dap_dotenv_hook_installed = true
  dap.listeners.on_config["java_spring_dotenv"] = function(config)
    if type(config) ~= "table" or config.type ~= "java" then
      return config
    end

    local cfg_copy = vim.deepcopy(config)
    local dotenv = load_project_dotenv()
    if #dotenv.keys > 0 then
      -- Las variables definidas explícitamente en la config DAP tienen prioridad sobre .env
      cfg_copy.env = vim.tbl_extend("keep", cfg_copy.env or {}, dotenv.vars)

      local rel_files = {}
      for _, f in ipairs(dotenv.files) do
        table.insert(rel_files, vim.fn.fnamemodify(f, ":."))
      end
      vim.schedule(function()
        vim.notify(
          string.format(
            "🌱 .env inyectado en Debugger (%d variables desde %s)",
            #dotenv.keys,
            table.concat(rel_files, ", ")
          ),
          vim.log.levels.INFO,
          { title = "Spring Boot DAP (.env)" }
        )
      end)
    end

    return cfg_copy
  end
end

--- ============================================================================
--- 3. Runner Interactivo de Spring Boot (`Snacks.terminal`) con `.env` Automático
--- ============================================================================

local SPRING_TERM_COUNT = 3
local active_spring_cmd = nil

--- Detecta la herramienta de construcción (Maven o Gradle) y el comando para Spring Boot
---@param workdir string
---@param action "boot"|"task"
---@param extra_args? string[]
---@return string[]|nil cmd, string tool_label
local function build_spring_command(workdir, action, extra_args)
  extra_args = extra_args or {}
  local cmd = {}
  local tool_label = ""

  if uv.fs_stat(workdir .. "/mvnw") then
    cmd = { "./mvnw" }
    tool_label = "Maven Wrapper (./mvnw)"
  elseif uv.fs_stat(workdir .. "/pom.xml") then
    if vim.fn.executable("mvn") == 0 then
      vim.notify(
        "Se detectó pom.xml pero no existe './mvnw' ni 'mvn' en el PATH.",
        vim.log.levels.ERROR,
        { title = "Spring Boot" }
      )
      return nil, ""
    end
    cmd = { "mvn" }
    tool_label = "Maven (mvn)"
  elseif uv.fs_stat(workdir .. "/gradlew") then
    cmd = { "./gradlew" }
    tool_label = "Gradle Wrapper (./gradlew)"
  elseif uv.fs_stat(workdir .. "/build.gradle") or uv.fs_stat(workdir .. "/build.gradle.kts") then
    if vim.fn.executable("gradle") == 0 then
      vim.notify(
        "Se detectó build.gradle pero no existe './gradlew' ni 'gradle' en el PATH.",
        vim.log.levels.ERROR,
        { title = "Spring Boot" }
      )
      return nil, ""
    end
    cmd = { "gradle" }
    tool_label = "Gradle (gradle)"
  else
    vim.notify(
      "No se encontró pom.xml ni build.gradle en el proyecto actual (" .. workdir .. ").",
      vim.log.levels.WARN,
      { title = "Spring Boot" }
    )
    return nil, ""
  end

  local is_maven = cmd[1]:find("mvn") ~= nil
  if action == "boot" then
    table.insert(cmd, is_maven and "spring-boot:run" or "bootRun")
  end

  vim.list_extend(cmd, extra_args)
  return cmd, tool_label
end

--- Construye las opciones de ventana y entorno para la terminal de Spring Boot
---@param workdir string
---@param env_vars table<string, string>
---@param title_suffix? string
---@return snacks.terminal.Opts
local function spring_term_opts(workdir, env_vars, title_suffix)
  local suffix = title_suffix and (" [" .. title_suffix .. "]") or ""
  return {
    count = SPRING_TERM_COUNT,
    cwd = workdir,
    env = env_vars,
    interactive = true,
    win = {
      position = "bottom",
      height = 0.38,
      title = " 🍃 Spring Boot" .. suffix .. " ",
      title_pos = "center",
    },
  }
end

--- Cierra cualquier instancia previa de la terminal de Spring Boot antes de un nuevo arranque
local function stop_existing_spring_terminal()
  if not _G.Snacks or not Snacks.terminal then
    return false
  end
  local stopped = false
  local ok, terms = pcall(Snacks.terminal.list)
  if ok and type(terms) == "table" then
    for _, term in ipairs(terms) do
      if term.opts and term.opts.count == SPRING_TERM_COUNT then
        pcall(function()
          term:destroy()
        end)
        stopped = true
      end
    end
  end
  active_spring_cmd = nil
  return stopped
end

--- Arranca el proyecto Spring Boot cargando automáticamente el archivo `.env`
---@param profile? string|nil Perfil opcional para `SPRING_PROFILES_ACTIVE`
---@param custom_args? string[] Argumentos adicionales de Maven/Gradle
local function run_spring_boot_with_dotenv(profile, custom_args)
  if not _G.Snacks or not Snacks.terminal then
    vim.notify("Snacks.terminal no está disponible", vim.log.levels.ERROR, { title = "Spring Boot" })
    return
  end

  -- Guardar archivos modificados antes de compilar/arrancar
  vim.cmd("silent! wall")

  local root = resolve_project_root()
  local workdir = resolve_spring_workdir(root)
  local dotenv = load_project_dotenv(root, profile)

  local cmd, tool_label = build_spring_command(workdir, custom_args and "task" or "boot", custom_args)
  if not cmd then
    return
  end

  local env_to_inject = vim.deepcopy(dotenv.vars)
  local java_home = resolve_java_home()
  if java_home and not env_to_inject.JAVA_HOME then
    env_to_inject.JAVA_HOME = java_home
  end

  if profile and profile ~= "" then
    env_to_inject.SPRING_PROFILES_ACTIVE = profile
  end

  -- Reiniciar limpiamente si ya había un proceso previo en el slot de Spring Boot
  stop_existing_spring_terminal()

  local active_prof = env_to_inject.SPRING_PROFILES_ACTIVE
  local badge_parts = {}
  if #dotenv.keys > 0 then
    table.insert(badge_parts, string.format(".env: %d vars", #dotenv.keys))
  else
    table.insert(badge_parts, "sin .env")
  end
  if active_prof and active_prof ~= "" then
    table.insert(badge_parts, "profile=" .. active_prof)
  end

  local opts = spring_term_opts(workdir, env_to_inject, table.concat(badge_parts, " | "))
  active_spring_cmd = cmd
  Snacks.terminal.open(cmd, opts)

  local env_summary
  if #dotenv.files > 0 then
    local rels = {}
    for _, f in ipairs(dotenv.files) do
      table.insert(rels, vim.fn.fnamemodify(f, ":."))
    end
    env_summary = string.format("🌱 %d variables cargadas desde %s", #dotenv.keys, table.concat(rels, ", "))
  else
    env_summary = "ℹ️ No se encontró archivo .env en la raíz (iniciando con entorno del sistema)"
  end

  vim.notify(
    string.format("Iniciando con %s\n%s", tool_label, env_summary),
    vim.log.levels.INFO,
    { title = "🍃 Spring Boot Runner" }
  )
end

--- Selector interactivo de perfil (`SPRING_PROFILES_ACTIVE`) para arrancar Spring Boot con `.env`
local function select_profile_and_run()
  local presets = {
    { id = "dev", label = "🛠️  dev     — Entorno de desarrollo (.env + .env.dev)" },
    { id = "local", label = "💻 local   — Entorno local (.env + .env.local)" },
    { id = "test", label = "🧪 test    — Entorno de pruebas (.env + .env.test)" },
    { id = "staging", label = "🚀 staging — Entorno de pre-producción (.env + .env.staging)" },
    { id = "prod", label = "🔒 prod    — Entorno de producción (.env + .env.prod)" },
    { id = "__custom__", label = "✏️  Escribir nombre de perfil personalizado..." },
  }

  vim.ui.select(presets, {
    prompt = "🌱 Seleccionar SPRING_PROFILES_ACTIVE (con carga automática de .env):",
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if not choice then
      return
    end
    if choice.id == "__custom__" then
      vim.ui.input({ prompt = "🌱 Nombre del perfil (ej. dev,postgres): " }, function(input)
        if input and vim.trim(input) ~= "" then
          run_spring_boot_with_dotenv(vim.trim(input))
        end
      end)
    else
      run_spring_boot_with_dotenv(choice.id)
    end
  end)
end

--- Selector de tareas Maven / Gradle ejecutadas con las variables del `.env`
local function run_maven_gradle_task()
  local root = resolve_project_root()
  local workdir = resolve_spring_workdir(root)
  local is_maven = uv.fs_stat(workdir .. "/mvnw") ~= nil or uv.fs_stat(workdir .. "/pom.xml") ~= nil

  local tasks
  if is_maven then
    tasks = {
      { args = { "clean", "compile" }, label = "🔨 clean compile              — Limpiar y compilar código fuente" },
      { args = { "test" }, label = "🧪 test                       — Ejecutar suite de tests con .env" },
      { args = { "clean", "package", "-DskipTests" }, label = "📦 clean package -DskipTests  — Empaquetar JAR omitiendo tests" },
      { args = { "clean", "verify" }, label = "✅ clean verify               — Compilar, ejecutar tests y verificar" },
      { args = { "dependency:tree" }, label = "🌳 dependency:tree            — Mostrar árbol de dependencias" },
      { args = { "spring-boot:build-image" }, label = "🐳 spring-boot:build-image    — Construir imagen OCI/Docker" },
      { args = "__custom__", label = "✏️  Comando Maven personalizado..." },
    }
  else
    tasks = {
      { args = { "clean", "classes" }, label = "🔨 clean classes              — Limpiar y compilar clases" },
      { args = { "test" }, label = "🧪 test                       — Ejecutar suite de tests con .env" },
      { args = { "bootJar", "-x", "test" }, label = "📦 bootJar -x test            — Construir JAR ejecutable sin tests" },
      { args = { "check" }, label = "✅ check                      — Ejecutar todas las verificaciones" },
      { args = { "dependencies" }, label = "🌳 dependencies               — Mostrar árbol de dependencias" },
      { args = "__custom__", label = "✏️  Tarea Gradle personalizada..." },
    }
  end

  vim.ui.select(tasks, {
    prompt = "🔨 Ejecutar tarea con variables .env inyectadas:",
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if not choice then
      return
    end
    if choice.args == "__custom__" then
      vim.ui.input({ prompt = "🔨 Argumentos (ej. clean test -Dtest=MiTest): " }, function(input)
        if input and vim.trim(input) ~= "" then
          local parts = vim.split(vim.trim(input), "%s+")
          run_spring_boot_with_dotenv(nil, parts)
        end
      end)
    else
      run_spring_boot_with_dotenv(nil, choice.args)
    end
  end)
end

--- Inicia la depuración DAP de Spring Boot garantizando la carga previa de `.env` y Main Class
local function debug_spring_boot_with_dotenv()
  install_dap_dotenv_hook()

  local ok_dap, dap = pcall(require, "dap")
  if not ok_dap then
    vim.notify("nvim-dap no está disponible", vim.log.levels.ERROR, { title = "Spring Boot DAP" })
    return
  end

  local ok_jdtls_dap, jdtls_dap = pcall(require, "jdtls.dap")
  if ok_jdtls_dap and type(jdtls_dap.setup_dap_main_class_configs) == "function" then
    -- Si aún no se han descubierto las clases @SpringBootApplication, descubrirlas antes de lanzar
    local java_cfgs = dap.configurations.java or {}
    if #java_cfgs == 0 then
      vim.notify("🔍 Descubriendo clase principal (@SpringBootApplication)...", vim.log.levels.INFO, {
        title = "Spring Boot DAP",
      })
      pcall(jdtls_dap.setup_dap_main_class_configs)
    end
  end

  dap.continue()
end

--- Inspecciona y muestra las variables `.env` detectadas en el proyecto actual (enmascarando secretos)
local function inspect_project_dotenv()
  local dotenv = load_project_dotenv()
  if #dotenv.files == 0 or #dotenv.keys == 0 then
    vim.notify(
      "No se encontraron variables en archivos .env dentro de:\n" .. dotenv.root .. "\n\nUsa <leader>jo para crear o abrir el archivo .env.",
      vim.log.levels.WARN,
      { title = "🌱 Inspector .env (Spring Boot)" }
    )
    return
  end

  local lines = { "Archivos cargados:" }
  for _, f in ipairs(dotenv.files) do
    table.insert(lines, "  • " .. vim.fn.fnamemodify(f, ":."))
  end
  table.insert(lines, "")
  table.insert(lines, string.format("Variables detectadas (%d):", #dotenv.keys))

  for _, key in ipairs(dotenv.keys) do
    local val = dotenv.vars[key] or ""
    local display_val
    if is_sensitive_key(key) and val ~= "" then
      display_val = "******** (oculto)"
    elseif #val > 48 then
      display_val = val:sub(1, 45) .. "..."
    else
      display_val = val
    end
    table.insert(lines, string.format("  • %s = %s", key, display_val))
  end

  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, {
    title = "🌱 Variables .env Activas (Spring Boot)",
    timeout = 6000,
  })
end

--- Abre (o crea si no existe) el archivo `.env` en la raíz del proyecto
local function open_project_dotenv()
  local root = resolve_project_root()
  local workdir = resolve_spring_workdir(root)
  local target_env = root .. "/.env"
  if not uv.fs_stat(target_env) and uv.fs_stat(workdir .. "/.env") then
    target_env = workdir .. "/.env"
  end
  vim.cmd("edit " .. vim.fn.fnameescape(target_env))
end

--- Alterna la visibilidad de la consola de Spring Boot
local function toggle_spring_console()
  if not _G.Snacks or not Snacks.terminal then
    return
  end
  if not active_spring_cmd then
    vim.notify(
      "No hay una consola de Spring Boot activa. Usa <leader>jr para iniciar el proyecto.",
      vim.log.levels.INFO,
      { title = "Spring Boot" }
    )
    return
  end
  local root = resolve_project_root()
  local workdir = resolve_spring_workdir(root)
  local dotenv = load_project_dotenv(root)
  Snacks.terminal.toggle(active_spring_cmd, spring_term_opts(workdir, dotenv.vars))
end

--- ============================================================================
--- 4. Recolección Defensiva de Bundles JDTLS (Debug, Test y Spring Boot Tools)
--- ============================================================================

--- Recolecta todos los JARs de extensiones JDTLS instalados en Mason o spring-boot.nvim
---@param mason_path string
---@return string[]
local function collect_jdtls_bundles(mason_path)
  local bundles = {}
  local seen = {}

  local function add_glob(pattern)
    local matches = vim.fn.glob(pattern, true, true)
    for _, jar in ipairs(matches) do
      if jar ~= "" and not seen[jar] and uv.fs_stat(jar) then
        -- Excluir runners internos de vscode-java-test que no son bundles OSGi válidos
        if not jar:match("com%.microsoft%.java%.test%.runner%-jar%-with%-dependencies%.jar$") and not jar:match("jacocoagent%.jar$") then
          seen[jar] = true
          table.insert(bundles, jar)
        end
      end
    end
  end

  -- 1. Java Debug Adapter
  add_glob(mason_path .. "/share/java-debug-adapter/com.microsoft.java.debug.plugin*.jar")
  add_glob(mason_path .. "/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar")

  -- 2. Java Test Runner
  add_glob(mason_path .. "/share/java-test/*.jar")
  add_glob(mason_path .. "/packages/java-test/extension/server/*.jar")

  -- 3. Spring Boot Tools JDTLS Extensions
  local ok_sb, spring_boot = pcall(require, "spring_boot")
  if ok_sb and type(spring_boot.java_extensions) == "function" then
    local ok_ext, sb_jars = pcall(spring_boot.java_extensions)
    if ok_ext and type(sb_jars) == "table" then
      for _, jar in ipairs(sb_jars) do
        if jar ~= "" and not seen[jar] and uv.fs_stat(jar) then
          seen[jar] = true
          table.insert(bundles, jar)
        end
      end
    end
  end

  add_glob(mason_path .. "/share/vscode-spring-boot-tools/jdtls/*.jar")
  add_glob(mason_path .. "/packages/vscode-spring-boot-tools/extension/jars/*.jar")

  return bundles
end

--- Registra atajos contextuales exclusivos para búfers Java al conectar JDTLS
local function register_java_buffer_keymaps()
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("JavaSpringLspKeymaps", { clear = true }),
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if not client or client.name ~= "jdtls" then
        return
      end

      install_dap_dotenv_hook()
      local bufnr = args.buf
      local map = function(lhs, rhs, desc)
        vim.keymap.set("n", lhs, rhs, { silent = true, buffer = bufnr, desc = desc })
      end

      map("<leader>jO", function()
        require("jdtls").organize_imports()
      end, "Organizar Imports (JDTLS)")

      map("<leader>ju", function()
        require("jdtls").update_project_config()
      end, "Actualizar configuración Maven/Gradle (JDTLS)")

      map("<leader>jt", function()
        install_dap_dotenv_hook()
        require("jdtls").test_nearest_method()
      end, "Depurar método de test bajo el cursor (.env)")

      map("<leader>jT", function()
        install_dap_dotenv_hook()
        require("jdtls").test_class()
      end, "Depurar clase de test actual (.env)")
    end,
  })
end

return {
  -- ==========================================================================
  -- 1. Garantizar herramientas Java & Spring Boot en Mason
  -- ==========================================================================
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      local pkgs = {
        "jdtls",
        "java-debug-adapter",
        "java-test",
        "vscode-spring-boot-tools",
        "google-java-format",
      }
      for _, pkg in ipairs(pkgs) do
        if not vim.tbl_contains(opts.ensure_installed, pkg) then
          table.insert(opts.ensure_installed, pkg)
        end
      end
    end,
  },

  -- ==========================================================================
  -- 2. Gramáticas Treesitter para proyectos Java y Spring Boot
  -- ==========================================================================
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "java",
        "javadoc",
        "properties",
        "xml",
        "yaml",
      },
    },
  },

  -- ==========================================================================
  -- 3. Menú e Iconos en Which-Key para Java / Spring Boot (<leader>j)
  -- ==========================================================================
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>j", group = "Java / Spring Boot", icon = "☕", mode = "n" },
        { "<leader>jr", desc = "Ejecutar Spring Boot (con .env)", icon = "▶️", mode = "n" },
        { "<leader>jp", desc = "Ejecutar Spring Boot con Perfil (.env)", icon = "🌱", mode = "n" },
        { "<leader>jd", desc = "Depurar Spring Boot (DAP + .env)", icon = "🐞", mode = "n" },
        { "<leader>js", desc = "Toggle Consola Spring Boot", icon = "🖥️", mode = "n" },
        { "<leader>jS", desc = "Detener Spring Boot", icon = "⏹️", mode = "n" },
        { "<leader>je", desc = "Inspeccionar variables .env activas", icon = "🔐", mode = "n" },
        { "<leader>jo", desc = "Abrir archivo .env del proyecto", icon = "📄", mode = "n" },
        { "<leader>jm", desc = "Tareas Maven / Gradle (con .env)", icon = "🔨", mode = "n" },
        { "<leader>jI", desc = "Spring Initializr (Configurar Proyecto)", icon = "🌱", mode = "n" },
        { "<leader>jG", desc = "Spring Initializr (Generar Proyecto)", icon = "🏗️", mode = "n" },
        { "<leader>jn", desc = "Menú Nuevo Artefacto Java", icon = "✨", mode = "n" },
        { "<leader>jc", desc = "Nueva Clase Java", icon = "📄", mode = "n" },
        { "<leader>ji", desc = "Nueva Interfaz Java", icon = "🔌", mode = "n" },
        { "<leader>jR", desc = "Nuevo Record Java", icon = "📋", mode = "n" },
        { "<leader>jE", desc = "Nuevo Enum Java", icon = "🔢", mode = "n" },
      },
    },
  },

  -- ==========================================================================
  -- 4. Atajos Globales del Runner Spring Boot + Motor .env
  -- ==========================================================================
  {
    "folke/snacks.nvim",
    keys = {
      {
        "<leader>jr",
        function()
          run_spring_boot_with_dotenv()
        end,
        mode = "n",
        desc = "Ejecutar Spring Boot (con .env)",
      },
      {
        "<leader>jp",
        function()
          select_profile_and_run()
        end,
        mode = "n",
        desc = "Ejecutar Spring Boot con Perfil (.env)",
      },
      {
        "<leader>jd",
        function()
          debug_spring_boot_with_dotenv()
        end,
        mode = "n",
        desc = "Depurar Spring Boot (DAP + .env)",
      },
      {
        "<leader>js",
        function()
          toggle_spring_console()
        end,
        mode = { "n", "t" },
        desc = "Toggle Consola Spring Boot",
      },
      {
        "<leader>jS",
        function()
          if stop_existing_spring_terminal() then
            vim.notify("⏹️ Proceso de Spring Boot detenido", vim.log.levels.INFO, { title = "Spring Boot" })
          else
            vim.notify("No hay ningún proceso de Spring Boot en ejecución", vim.log.levels.INFO, { title = "Spring Boot" })
          end
        end,
        mode = "n",
        desc = "Detener Spring Boot",
      },
      {
        "<leader>je",
        function()
          inspect_project_dotenv()
        end,
        mode = "n",
        desc = "Inspeccionar variables .env activas",
      },
      {
        "<leader>jo",
        function()
          open_project_dotenv()
        end,
        mode = "n",
        desc = "Abrir archivo .env del proyecto",
      },
      {
        "<leader>jm",
        function()
          run_maven_gradle_task()
        end,
        mode = "n",
        desc = "Tareas Maven / Gradle (con .env)",
      },
    },
  },

  -- ==========================================================================
  -- 5. Soporte Oficial Spring Boot Tools 4 (JavaHello/spring-boot.nvim)
  -- ==========================================================================
  {
    "JavaHello/spring-boot.nvim",
    ft = { "java", "yaml", "jproperties" },
    dependencies = {
      "mfussenegger/nvim-jdtls",
    },
    opts = function()
      local mason_path = vim.fn.stdpath("data") .. "/mason"
      local ls_candidates = {
        mason_path .. "/packages/vscode-spring-boot-tools/extension/language-server",
        mason_path .. "/share/vscode-spring-boot-tools/language-server",
      }
      local ls_path = nil
      for _, candidate in ipairs(ls_candidates) do
        if uv.fs_stat(candidate) then
          ls_path = candidate
          break
        end
      end

      return {
        ls_path = ls_path,
        java_cmd = (function()
          local jh = resolve_java_home()
          return jh and (jh .. "/bin/java") or nil
        end)(),
        autocmd = true,
      }
    end,
  },

  -- ==========================================================================
  -- 6. Configuración Avanzada del Language Server (mfussenegger/nvim-jdtls)
  -- ==========================================================================
  {
    "mfussenegger/nvim-jdtls",
    optional = true,
    opts = function(_, opts)
      install_dap_dotenv_hook()
      register_java_buffer_keymaps()

      local mason_path = vim.fn.stdpath("data") .. "/mason"
      local jdtls_bin = vim.fn.exepath("jdtls")
      if jdtls_bin == "" then
        jdtls_bin = mason_path .. "/bin/jdtls"
      end

      opts.cmd = opts.cmd or {}
      if #opts.cmd == 0 or opts.cmd[1] == "" then
        opts.cmd[1] = jdtls_bin
      end

      local java_home = resolve_java_home()
      if java_home then
        append_flag_once(opts.cmd, "--java-executable=", java_home .. "/bin/java")
      end

      -- Optimización de memoria y GC para proyectos Spring Boot con Lombok / MapStruct
      append_flag_once(opts.cmd, "--jvm-arg=-Xmx", "4G")
      append_flag_once(opts.cmd, "--jvm-arg=-XX:+", "UseG1GC")
      append_flag_once(opts.cmd, "--jvm-arg=-Dsun.zip.disableMemoryMapping=", "true")

      local lombok_candidates = {
        mason_path .. "/share/jdtls/lombok.jar",
        mason_path .. "/packages/jdtls/lombok.jar",
      }
      for _, lombok_jar in ipairs(lombok_candidates) do
        if uv.fs_stat(lombok_jar) then
          append_flag_once(opts.cmd, "--jvm-arg=-javaagent:", lombok_jar)
          break
        end
      end

      local runtimes = discover_java_runtimes(java_home)

      opts.settings = vim.tbl_deep_extend("force", opts.settings or {}, {
        java = {
          home = java_home,
          eclipse = {
            downloadSources = true,
          },
          maven = {
            downloadSources = true,
          },
          configuration = {
            updateBuildConfiguration = "interactive",
            runtimes = #runtimes > 0 and runtimes or nil,
          },
          implementationsCodeLens = {
            enabled = true,
          },
          referencesCodeLens = {
            enabled = true,
          },
          references = {
            includeDecompiledSources = true,
          },
          signatureHelp = {
            enabled = true,
          },
          contentProvider = {
            preferred = "fernflower",
          },
          inlayHints = {
            parameterNames = {
              enabled = "all",
            },
          },
          compile = {
            nullAnalysis = {
              mode = "automatic",
            },
          },
          sources = {
            organizeImports = {
              starThreshold = 9999,
              staticStarThreshold = 9999,
            },
          },
          codeGeneration = {
            toString = {
              template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
            },
            useBlocks = true,
          },
          completion = {
            favoriteStaticMembers = {
              "org.assertj.core.api.Assertions.*",
              "org.junit.jupiter.api.Assertions.*",
              "org.junit.jupiter.api.Assumptions.*",
              "org.mockito.Mockito.*",
              "org.mockito.ArgumentMatchers.*",
              "org.mockito.Answers.*",
              "org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*",
              "org.springframework.test.web.servlet.result.MockMvcResultMatchers.*",
              "java.util.Objects.requireNonNull",
              "java.util.Objects.requireNonNullElse",
            },
            filteredTypes = {
              "com.sun.*",
              "io.micrometer.shaded.*",
              "java.awt.*",
              "jdk.*",
              "sun.*",
            },
            importOrder = {
              "java",
              "javax",
              "jakarta",
              "org",
              "com",
              "",
            },
          },
        },
      })

      -- Inyectar bundles de Debug, Test y Spring Boot Tools en init_options
      local extra_bundles = collect_jdtls_bundles(mason_path)
      if #extra_bundles > 0 then
        local prev_full_cmd = opts.full_cmd
        opts.jdtls = function(jdtls_opts)
          jdtls_opts.init_options = jdtls_opts.init_options or {}
          local existing = jdtls_opts.init_options.bundles or {}
          local merged = vim.deepcopy(existing)
          for _, b in ipairs(extra_bundles) do
            if not vim.tbl_contains(merged, b) then
              table.insert(merged, b)
            end
          end
          jdtls_opts.init_options.bundles = merged
          return jdtls_opts
        end
        if prev_full_cmd then
          opts.full_cmd = prev_full_cmd
        end
      end

      return opts
    end,
  },

  -- ==========================================================================
  -- 7. Hook automático de .env en nvim-dap (para <leader>dc y sesiones directas)
  -- ==========================================================================
  {
    "mfussenegger/nvim-dap",
    optional = true,
    opts = function()
      install_dap_dotenv_hook()
    end,
  },

  -- ==========================================================================
  -- 8. Testing JUnit 5 / Spring Boot Test con Neotest (rcasia/neotest-java)
  -- ==========================================================================
  {
    "nvim-neotest/neotest",
    optional = true,
    dependencies = {
      "rcasia/neotest-java",
    },
    opts = {
      adapters = {
        ["neotest-java"] = {
          ignore_wrapper = false,
        },
      },
    },
  },

  -- ==========================================================================
  -- 9. Scaffolding de Clases, Interfaces, Records y Enums (java-creator-nvim)
  -- ==========================================================================
  {
    "alessio-vivaldelli/java-creator-nvim",
    ft = "java",
    opts = function()
      local root = resolve_project_root()
      -- Solo usar custom_src_path "backend/src/main/java" si el proyecto es un monorepo con carpeta backend/
      local has_backend_src = uv.fs_stat(root .. "/backend/src/main/java") ~= nil

      return {
        options = {
          java_version = 21,
          auto_open = true,
          use_notify = true,
          custom_src_path = has_backend_src and "backend/src/main/java" or nil,
          src_patterns = { "src/main/java", "src/test/java", "src" },
          project_markers = {
            "pom.xml",
            "build.gradle",
            "build.gradle.kts",
            "settings.gradle",
            "settings.gradle.kts",
            ".project",
          },
          notification_timeout = 3000,
        },
        keymaps = {
          java_new = "<leader>jn",
          java_class = "<leader>jc",
          java_interface = "<leader>ji",
          java_record = "<leader>jR",
          java_enum = "<leader>jE",
        },
        default_imports = {
          record = { "java.util.*" },
        },
      }
    end,
  },

  -- ==========================================================================
  -- 10. Cliente TUI de Spring Initializr (jkeresman01/spring-initializr.nvim)
  -- ==========================================================================
  {
    "jkeresman01/spring-initializr.nvim",
    cmd = {
      "SpringInitializr",
      "SpringGenerateProject",
      "SpringInitializrConfig",
      "SpringInitializrLog",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-telescope/telescope.nvim",
    },
    keys = {
      {
        "<leader>jI",
        "<cmd>SpringInitializr<cr>",
        mode = "n",
        desc = "Spring Initializr (Configurar Proyecto)",
      },
      {
        "<leader>jG",
        "<cmd>SpringGenerateProject<cr>",
        mode = "n",
        desc = "Spring Initializr (Generar Proyecto)",
      },
    },
    opts = {},
  },

  -- ==========================================================================
  -- 11. Generación de Documentación Javadoc (<leader>cn) con Neogen
  -- ==========================================================================
  {
    "danymat/neogen",
    optional = true,
    opts = {
      languages = {
        java = {
          template = {
            annotation_convention = "javadoc",
          },
        },
      },
    },
  },
}
