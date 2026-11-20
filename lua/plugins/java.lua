---@module "plugins.java"
--- Configuración del ecosistema Java: LSP (nvim-jdtls) y utilidades de scaffolding (java-creator-nvim)

local uv = vim.uv or vim.loop

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

return {
  -- Configuración y personalización del Language Server (JDTLS)
  {
    "mfussenegger/nvim-jdtls",
    optional = true,
    opts = function(_, opts)
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
        opts.settings = vim.tbl_deep_extend("force", opts.settings or {}, {
          java = {
            home = java_home,
          },
        })
      end

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

      return opts
    end,
  },

  -- Generador de clases, interfaces, records y enums para Java
  {
    "alessio-vivaldelli/java-creator-nvim",
    ft = "java",
    dependencies = {
      { "rcarriga/nvim-notify", optional = true },
    },
    opts = {
      options = {
        java_version = 21,
        auto_open = true,
        use_notify = true,
        custom_src_path = "backend/src/main/java",
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
        java_enum = "<leader>je",
        java_record = "<leader>jr",
      },
      default_imports = {
        record = { "java.util.*" },
      },
    },
  },
}
