---@module "plugins.antigravity"
--- ============================================================================
--- Integración Profesional de Antigravity CLI (agy) para LazyVim + snacks.nvim
--- ============================================================================
--- Este módulo conecta Neovim con una sesión interactiva persistente de `agy`
--- mediante canales PTY (nvim_chan_send) y la terminal flotante de snacks.nvim.
---
--- Características principales:
---   1. Sesión única persistente (`count = 1`): todos los atajos comparten la
---      misma instancia de `agy` sin abrir procesos duplicados.
---   2. Edición contextual (`<leader>ae`): captura archivo relativo (`@archivo`),
---      rango de líneas (`L10-L25`), código seleccionado y tu comentario/prompt.
---   3. Sincronización segura con disco: guarda el búfer antes de enviar la
---      orden a `agy` para evitar conflictos entre memoria y disco.
---   4. Integración con LSP (`<leader>ad`): extrae diagnósticos (errores/warnings)
---      del búfer actual y los envía a `agy` para su corrección automática.
--- ============================================================================

--- Opciones base de la ventana flotante para la terminal de AGY.
--- Se fija `count = 1` para que Snacks.terminal reutilice siempre el mismo ID
--- de terminal incluso tras selecciones visuales con prefijo numérico.
---@param width? number Proporción de ancho (0.0 a 1.0, por defecto 0.90)
---@param height? number Proporción de alto (0.0 a 1.0, por defecto 0.90)
---@return snacks.terminal.Opts
local function agy_term_opts(width, height)
  return {
    count = 1,
    interactive = true,
    win = {
      style = "float",
      border = "rounded",
      width = width or 0.90,
      height = height or 0.90,
      title = " 🚀 Antigravity CLI (agy) ",
      title_pos = "center",
    },
  }
end

--- Verifica que el binario `agy` esté instalado y disponible en el PATH.
---@return boolean
local function ensure_agy()
  if vim.fn.executable("agy") == 1 then
    return true
  end
  vim.notify("No se encontró el ejecutable 'agy' en el PATH", vim.log.levels.ERROR, { title = "Antigravity" })
  return false
end

--- Valida que el búfer actual corresponda a un archivo real en disco y lo guarda
--- si tiene cambios pendientes para que `agy` lea siempre la versión actualizada.
---@return string|nil rel_path Ruta relativa al directorio de trabajo actual
local function get_and_save_current_file()
  local full_path = vim.api.nvim_buf_get_name(0)
  if full_path == "" or vim.bo.buftype ~= "" then
    vim.notify(
      "El búfer actual no corresponde a un archivo guardado en disco",
      vim.log.levels.WARN,
      { title = "Antigravity" }
    )
    return nil
  end

  -- Guardar cambios pendientes de forma silenciosa antes de que agy lea el archivo
  if vim.bo.modified and vim.bo.modifiable and not vim.bo.readonly then
    vim.cmd("silent! update")
  end

  return vim.fn.fnamemodify(full_path, ":.")
end

--- Captura el rango de líneas y el texto seleccionado en modo Visual o Normal.
--- Si se invoca desde modo Visual, limpia el modo visual para actualizar las posiciones.
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

    -- Salir de modo visual limpiamente
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)

    return {
      start_line = start_line,
      end_line = end_line,
      text = table.concat(lines, "\n"),
    }
  end

  -- En modo Normal, toma la línea actual bajo el cursor
  local cur_line = vim.api.nvim_win_get_cursor(0)[1]
  local line_text = vim.api.nvim_get_current_line()
  return {
    start_line = cur_line,
    end_line = cur_line,
    text = line_text,
  }
end

--- Envía un prompt a la sesión interactiva persistente de `agy`.
--- Si la terminal aún no existe, la crea y espera a que la TUI inicie antes de
--- inyectar el mensaje. Si ya existe, la muestra y envía el prompt al canal PTY.
---@param prompt string Texto o instrucción que se enviará a agy
local function send_to_agy(prompt)
  if not ensure_agy() then
    return
  end

  local opts = agy_term_opts(0.90, 0.90)
  local term, created = Snacks.terminal.get("agy", opts)
  if not term or not term.buf or not vim.api.nvim_buf_is_valid(term.buf) then
    vim.notify("No fue posible inicializar la terminal de Antigravity", vim.log.levels.ERROR, { title = "Antigravity" })
    return
  end

  -- Mostrar y enfocar la ventana flotante de agy para ver la respuesta en vivo
  term:show()
  term:focus()

  -- Normalizar el prompt en una sola línea lógica si contiene saltos para evitar
  -- que la TUI interprete saltos intermedios como envíos prematuros, y luego
  -- enviar Enter (\r) con un breve retardo para confirmar el envío.
  local sanitized = prompt:gsub("\r\n", "\n"):gsub("\n+", " ")

  local function dispatch()
    if not vim.api.nvim_buf_is_valid(term.buf) then
      return
    end
    local chan = vim.bo[term.buf].channel
    if not chan or chan <= 0 then
      return
    end

    -- 1. Enviar el contenido del prompt al input de la TUI
    vim.api.nvim_chan_send(chan, sanitized)

    -- 2. Enviar <Enter> tras 150ms para que la TUI procese el texto antes del submit
    vim.defer_fn(function()
      if vim.api.nvim_buf_is_valid(term.buf) and vim.bo[term.buf].channel > 0 then
        vim.api.nvim_chan_send(vim.bo[term.buf].channel, "\r")
        vim.cmd("startinsert")
      end
    end, 150)
  end

  -- Si la terminal acaba de crearse, dar tiempo a que la TUI de agy cargue
  if created then
    vim.defer_fn(dispatch, 1800)
  else
    vim.defer_fn(dispatch, 80)
  end
end

--- Solicita al usuario una instrucción mediante el input flotante de Neovim/Snacks
--- y la envía a `agy` junto con la ubicación exacta del código seleccionado.
---@param action_type "edit"|"ask" Tipo de acción ("edit" para modificar, "ask" para consultar)
local function prompt_with_selection(action_type)
  if not ensure_agy() then
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
      and string.format("🚀 Editar con AGY (%s:%s): ", rel_file, range_label)
    or string.format("💬 Consultar a AGY (%s:%s): ", rel_file, range_label)

  vim.ui.input({ prompt = prompt_title }, function(instruction)
    if not instruction or vim.trim(instruction) == "" then
      return
    end

    local message
    if action_type == "edit" then
      message = string.format(
        "En el archivo @%s (líneas %d a %d), realiza el siguiente cambio directamente en el archivo: %s",
        rel_file,
        sel.start_line,
        sel.end_line,
        vim.trim(instruction)
      )
    else
      message = string.format(
        "Respecto al archivo @%s (líneas %d a %d): %s",
        rel_file,
        sel.start_line,
        sel.end_line,
        vim.trim(instruction)
      )
    end

    send_to_agy(message)
  end)
end

return {
  -- Integración de menú e iconos en Which-Key al presionar <leader>a
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>a", group = "Antigravity (AGY)", icon = "🚀", mode = { "n", "x" } },
        { "<leader>ag", desc = "Toggle Terminal AGY CLI", icon = "🖥️", mode = "n" },
        { "<leader>ae", desc = "Editar selección/línea con comentario (AGY)", icon = "✏️", mode = { "n", "x" } },
        { "<leader>aa", desc = "Preguntar a AGY sobre selección/línea", icon = "💬", mode = { "n", "x" } },
        { "<leader>af", desc = "Enviar archivo actual a AGY", icon = "📄", mode = "n" },
        { "<leader>ad", desc = "Corregir diagnósticos LSP actuales con AGY", icon = "🩺", mode = "n" },
      },
    },
  },

  {
    "folke/snacks.nvim",
    keys = {
      -- 1. Mostrar / Ocultar la terminal flotante de Antigravity (Funciona en Normal y dentro de la Terminal)
      {
        "<leader>ag",
        function()
          if not ensure_agy() then
            return
          end
          Snacks.terminal.toggle("agy", agy_term_opts(0.90, 0.90))
        end,
        mode = { "n", "t" },
        desc = "Toggle Terminal AGY CLI",
      },

      -- 2. Seleccionar código + escribir comentario para que AGY edite el archivo directamente
      {
        "<leader>ae",
        function()
          prompt_with_selection("edit")
        end,
        mode = { "n", "x" },
        desc = "Editar selección/línea con comentario (AGY)",
      },

      -- 3. Seleccionar código + hacer una pregunta o pedir explicación a AGY
      {
        "<leader>aa",
        function()
          prompt_with_selection("ask")
        end,
        mode = { "n", "x" },
        desc = "Preguntar a AGY sobre selección/línea",
      },

      -- 4. Enviar el archivo actual completo con una instrucción opcional
      {
        "<leader>af",
        function()
          if not ensure_agy() then
            return
          end
          local rel_file = get_and_save_current_file()
          if not rel_file then
            return
          end

          vim.ui.input({
            prompt = string.format("📄 Instrucción para @%s (Enter = analizar archivo): ", rel_file),
          }, function(instruction)
            if instruction == nil then
              return -- Cancelado con <Esc>
            end
            local clean = vim.trim(instruction)
            local msg = clean ~= "" and string.format("En el archivo @%s: %s", rel_file, clean)
              or string.format("Analiza el archivo @%s, revisa posibles mejoras o errores y dime un resumen.", rel_file)
            send_to_agy(msg)
          end)
        end,
        mode = "n",
        desc = "Enviar archivo actual a AGY",
      },

      -- 5. Enviar diagnósticos LSP (errores/warnings) del archivo actual para que AGY los corrija
      {
        "<leader>ad",
        function()
          if not ensure_agy() then
            return
          end
          local rel_file = get_and_save_current_file()
          if not rel_file then
            return
          end

          local diags = vim.diagnostic.get(0)
          if #diags == 0 then
            vim.notify("No hay diagnósticos (errores/warnings) activos en este archivo", vim.log.levels.INFO, {
              title = "Antigravity",
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

          local prompt = string.format(
            "Corrige los siguientes diagnósticos LSP en el archivo @%s: %s",
            rel_file,
            table.concat(summary, " ; ")
          )
          send_to_agy(prompt)
        end,
        mode = "n",
        desc = "Corregir diagnósticos LSP actuales con AGY",
      },
    },
  },
}
