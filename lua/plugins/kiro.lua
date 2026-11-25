---@module "plugins.kiro"
--- ============================================================================
--- Integración de Kiro CLI (kiro-cli) para LazyVim + snacks.nvim
--- ============================================================================
--- Módulo paralelo e independiente de `antigravity.lua`. Conecta Neovim con una
--- sesión interactiva persistente de `kiro-cli chat` mediante canales PTY
--- (nvim_chan_send) y la terminal flotante de snacks.nvim.
---
--- Características principales:
---   1. Sesión única persistente: todos los atajos comparten la misma
---      instancia de `kiro-cli chat` (distinta de la de `agy`).
---   2. Arranca con `--trust-workspace` para confiar en el proyecto abierto en
---      Neovim. No fija `--agent` ni `--model`: se usan los de la herramienta.
---   3. Edición contextual (`<leader>ke`/`<leader>ka`): archivo relativo, rango
---      de líneas e instrucción del usuario.
---   4. Sincronización con disco: guarda el búfer antes de enviar el prompt.
---   5. Diagnósticos LSP (`<leader>kd`) y reanudación de sesión (`<leader>kr`).
---   6. Indicador de sesión activa en Lualine.
---
--- La recarga de búfers modificados por Kiro la cubre el autocmd `AgentAutoRead`
--- de lua/config/autocmds.lua.
--- ============================================================================

local TITLE = "Kiro CLI"

--- Comandos de arranque. Se usan listas (sin shell) para evitar problemas de
--- comillas en Windows. Ambos comparten el mismo identificador visual.
local CMD_DEFAULT = { "kiro-cli", "chat", "--trust-workspace" }
local CMD_RESUME = { "kiro-cli", "chat", "--trust-workspace", "--resume" }

--- Retardos (ms) para dar tiempo a la TUI antes de inyectar el prompt.
local DELAY_NEW = 2500 -- terminal recién creada
local DELAY_EXISTING = 80 -- terminal ya abierta
local DELAY_SUBMIT = 150 -- entre el texto y el <Enter>

--- Opciones base de la ventana flotante para la terminal de Kiro.
--- `count = 2` evita colisionar con la terminal de AGY (`count = 1`).
---@param create? boolean false para consultar sin crear
---@return snacks.terminal.Opts
local function kiro_term_opts(create)
  return {
    count = 2,
    interactive = true,
    create = create,
    win = {
      style = "float",
      border = "rounded",
      width = 0.90,
      height = 0.90,
      title = " 🤖 Kiro CLI ",
      title_pos = "center",
    },
  }
end

--- Verifica que `kiro-cli` esté instalado y disponible en el PATH.
---@return boolean
local function ensure_kiro()
  if vim.fn.executable("kiro-cli") == 1 then
    return true
  end
  vim.notify("No se encontró el ejecutable 'kiro-cli' en el PATH", vim.log.levels.ERROR, { title = TITLE })
  return false
end

--- Valida que el búfer actual sea un archivo real y lo guarda si tiene cambios.
---@return string|nil rel_path Ruta relativa al directorio de trabajo actual
local function get_and_save_current_file()
  local full_path = vim.api.nvim_buf_get_name(0)
  if full_path == "" or vim.bo.buftype ~= "" then
    vim.notify("El búfer actual no corresponde a un archivo guardado en disco", vim.log.levels.WARN, { title = TITLE })
    return nil
  end

  if vim.bo.modified and vim.bo.modifiable and not vim.bo.readonly then
    vim.cmd("silent! update")
  end

  local rel = vim.fn.fnamemodify(full_path, ":.")
  -- Rutas con espacios: entrecomillar para que el prompt las interprete bien
  if rel:find("%s") then
    rel = '"' .. rel .. '"'
  end
  return rel
end

--- Captura el rango de líneas y el texto seleccionado en modo Visual o Normal.
---@return { start_line: integer, end_line: integer, text: string }
local function capture_selection()
  local mode = vim.fn.mode()
  local is_visual = mode:find("[vV\22]") ~= nil

  if is_visual then
    local pos_v = vim.fn.getpos("v")
    local pos_cur = vim.fn.getpos(".")
    local lines = vim.fn.getregion(pos_v, pos_cur, { type = mode })
    local start_line = math.min(pos_v[2], pos_cur[2])
    local end_line = math.max(pos_v[2], pos_cur[2])

    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)

    return { start_line = start_line, end_line = end_line, text = table.concat(lines, "\n") }
  end

  local cur_line = vim.api.nvim_win_get_cursor(0)[1]
  return { start_line = cur_line, end_line = cur_line, text = vim.api.nvim_get_current_line() }
end

--- Obtiene (o crea) la terminal de Kiro.
---@param cmd string[]
---@return snacks.win|nil term, boolean|nil created
local function get_term(cmd)
  local term, created = Snacks.terminal.get(cmd, kiro_term_opts())
  if not term or not term.buf or not vim.api.nvim_buf_is_valid(term.buf) then
    vim.notify("No fue posible inicializar la terminal de Kiro", vim.log.levels.ERROR, { title = TITLE })
    return nil, nil
  end
  return term, created
end

--- Envía un prompt a la sesión interactiva persistente de `kiro-cli`.
---@param prompt string
local function send_to_kiro(prompt)
  if not ensure_kiro() then
    return
  end

  local term, created = get_term(CMD_DEFAULT)
  if not term then
    return
  end

  term:show()
  term:focus()

  -- Una sola línea lógica para evitar envíos prematuros por saltos de línea
  local sanitized = prompt:gsub("\r\n", "\n"):gsub("\n+", " ")

  local function dispatch()
    if not vim.api.nvim_buf_is_valid(term.buf) then
      return
    end
    local chan = vim.bo[term.buf].channel
    if not chan or chan <= 0 then
      return
    end

    vim.api.nvim_chan_send(chan, sanitized)

    vim.defer_fn(function()
      if vim.api.nvim_buf_is_valid(term.buf) and vim.bo[term.buf].channel > 0 then
        vim.api.nvim_chan_send(vim.bo[term.buf].channel, "\r")
        vim.cmd("startinsert")
      end
    end, DELAY_SUBMIT)
  end

  vim.defer_fn(dispatch, created and DELAY_NEW or DELAY_EXISTING)
end

--- Solicita una instrucción y la envía a Kiro junto con la ubicación del código.
---@param action_type "edit"|"ask"
local function prompt_with_selection(action_type)
  if not ensure_kiro() then
    return
  end

  local sel = capture_selection()
  local rel_file = get_and_save_current_file()
  if not rel_file then
    return
  end

  local range_label = sel.start_line == sel.end_line and string.format("L%d", sel.start_line)
    or string.format("L%d-L%d", sel.start_line, sel.end_line)

  local prompt_title = action_type == "edit"
      and string.format("🤖 Editar con Kiro (%s:%s): ", rel_file, range_label)
    or string.format("💬 Consultar a Kiro (%s:%s): ", rel_file, range_label)

  vim.ui.input({ prompt = prompt_title }, function(instruction)
    if not instruction or vim.trim(instruction) == "" then
      return
    end

    local template = action_type == "edit"
        and "En el archivo %s (líneas %d a %d), realiza el siguiente cambio directamente en el archivo: %s"
      or "Respecto al archivo %s (líneas %d a %d): %s"

    send_to_kiro(string.format(template, rel_file, sel.start_line, sel.end_line, vim.trim(instruction)))
  end)
end

--- Indica si hay una sesión de Kiro con el proceso vivo (sin crearla).
---@return boolean
local function kiro_is_active()
  local ok, terms = pcall(function()
    return Snacks.terminal.list()
  end)
  if not ok or type(terms) ~= "table" then
    return false
  end
  for _, term in ipairs(terms) do
    local buf = term.buf
    if buf and vim.api.nvim_buf_is_valid(buf) then
      local name = vim.api.nvim_buf_get_name(buf)
      if name:find("kiro%-cli") then
        local job = vim.b[buf].terminal_job_id
        if job and vim.fn.jobwait({ job }, 0)[1] == -1 then
          return true
        end
      end
    end
  end
  return false
end

return {
  -- Integración de menú e iconos en Which-Key al presionar <leader>k
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>k", group = "Kiro CLI", icon = "🤖", mode = { "n", "x" } },
        { "<leader>kk", desc = "Toggle Terminal Kiro CLI", icon = "🖥️", mode = "n" },
        { "<leader>ke", desc = "Editar selección/línea con comentario (Kiro)", icon = "✏️", mode = { "n", "x" } },
        { "<leader>ka", desc = "Preguntar a Kiro sobre selección/línea", icon = "💬", mode = { "n", "x" } },
        { "<leader>kf", desc = "Enviar archivo actual a Kiro", icon = "📄", mode = "n" },
        { "<leader>kd", desc = "Corregir diagnósticos LSP actuales con Kiro", icon = "🩺", mode = "n" },
        { "<leader>kr", desc = "Reanudar última sesión de Kiro", icon = "🔁", mode = "n" },
      },
    },
  },

  {
    "folke/snacks.nvim",
    keys = {
      -- 1. Mostrar / Ocultar la terminal flotante de Kiro (Normal y Terminal)
      {
        "<leader>kk",
        function()
          if not ensure_kiro() then
            return
          end
          Snacks.terminal.toggle(CMD_DEFAULT, kiro_term_opts())
        end,
        mode = { "n", "t" },
        desc = "Toggle Terminal Kiro CLI",
      },

      -- 2. Editar la selección/línea con una instrucción
      {
        "<leader>ke",
        function()
          prompt_with_selection("edit")
        end,
        mode = { "n", "x" },
        desc = "Editar selección/línea con comentario (Kiro)",
      },

      -- 3. Preguntar sobre la selección/línea
      {
        "<leader>ka",
        function()
          prompt_with_selection("ask")
        end,
        mode = { "n", "x" },
        desc = "Preguntar a Kiro sobre selección/línea",
      },

      -- 4. Enviar el archivo actual con una instrucción opcional
      {
        "<leader>kf",
        function()
          if not ensure_kiro() then
            return
          end
          local rel_file = get_and_save_current_file()
          if not rel_file then
            return
          end

          vim.ui.input({
            prompt = string.format("📄 Instrucción para %s (Enter = analizar archivo): ", rel_file),
          }, function(instruction)
            if instruction == nil then
              return -- Cancelado con <Esc>
            end
            local clean = vim.trim(instruction)
            local msg = clean ~= "" and string.format("En el archivo %s: %s", rel_file, clean)
              or string.format("Analiza el archivo %s, revisa posibles mejoras o errores y dime un resumen.", rel_file)
            send_to_kiro(msg)
          end)
        end,
        mode = "n",
        desc = "Enviar archivo actual a Kiro",
      },

      -- 5. Enviar diagnósticos LSP del archivo actual para que Kiro los corrija
      {
        "<leader>kd",
        function()
          if not ensure_kiro() then
            return
          end
          local rel_file = get_and_save_current_file()
          if not rel_file then
            return
          end

          local diags = vim.diagnostic.get(0)
          if #diags == 0 then
            vim.notify("No hay diagnósticos (errores/warnings) activos en este archivo", vim.log.levels.INFO, {
              title = TITLE,
            })
            return
          end

          local severity_names = {
            [vim.diagnostic.severity.ERROR] = "ERROR",
            [vim.diagnostic.severity.WARN] = "WARN",
            [vim.diagnostic.severity.INFO] = "INFO",
            [vim.diagnostic.severity.HINT] = "HINT",
          }

          local summary = {}
          for i, d in ipairs(diags) do
            if i <= 10 then
              local sev = severity_names[d.severity] or "DIAG"
              local msg = d.message:gsub("%s+", " ")
              table.insert(summary, string.format("[L%d %s] %s", d.lnum + 1, sev, msg))
            end
          end

          send_to_kiro(
            string.format(
              "Corrige los siguientes diagnósticos LSP en el archivo %s: %s",
              rel_file,
              table.concat(summary, " ; ")
            )
          )
        end,
        mode = "n",
        desc = "Corregir diagnósticos LSP actuales con Kiro",
      },

      -- 6. Abrir Kiro reanudando la conversación más reciente de este directorio
      {
        "<leader>kr",
        function()
          if not ensure_kiro() then
            return
          end
          local term = get_term(CMD_RESUME)
          if term then
            term:show()
            term:focus()
            vim.cmd("startinsert")
          end
        end,
        mode = "n",
        desc = "Reanudar última sesión de Kiro",
      },
    },
  },

  -- Indicador de sesión activa de Kiro en Lualine (sección X, junto al de AGY)
  {
    "nvim-lualine/lualine.nvim",
    optional = true,
    opts = function(_, opts)
      opts.sections = opts.sections or {}
      opts.sections.lualine_x = opts.sections.lualine_x or {}

      table.insert(opts.sections.lualine_x, 1, {
        function()
          return "🤖 Kiro"
        end,
        cond = kiro_is_active,
        color = { fg = "#7aa2f7" },
      })
    end,
  },
}
