---@module "plugins.antigravity"
--- ============================================================================
--- Integración Profesional de Antigravity CLI (agy) para LazyVim + snacks.nvim
--- ============================================================================
--- Este módulo conecta Neovim con una sesión interactiva persistente de `agy`
--- mediante canales PTY (nvim_chan_send) y la terminal de snacks.nvim.
---
--- Características principales:
---   1. Sesión única persistente (`count = 1`) anclada a la raíz del proyecto
---      (`LazyVim.root()`): todos los atajos comparten la misma instancia de `agy`.
---   2. Auto-recarga de búferes (`checktime`): cualquier edición que `agy` haga
---      en disco se refleja inmediatamente en Neovim al ocultar/salir de la TUI.
---   3. Vista dual (Flotante `<leader>ag` o Split Lateral `<leader>av`) sobre
---      la misma sesión activa.
---   4. Edición, consulta y generación de tests contextuales (`<leader>ae`,
---      `<leader>aa`, `<leader>at`) con fragmento de código seleccionado.
---   5. Diagnósticos LSP priorizados por severidad (`<leader>ad`), contexto
---      multi-archivo / Quickfix (`<leader>aq`), revisión Git (`<leader>ar`) y
---      selector interactivo de Slash Commands de AGY (`<leader>as`).
--- ============================================================================

--- Estado del modo de ventana actual ("float" | "right")
local current_layout = "float"

--- Obtiene el directorio raíz del proyecto actual de forma segura.
---@return string
local function get_project_root()
  if _G.LazyVim and LazyVim.root then
    return LazyVim.root()
  end
  return vim.fn.getcwd()
end

--- Convierte una ruta absoluta a relativa respecto a la raíz del proyecto
--- para que coincida siempre con el `cwd` donde se ejecuta `agy`.
---@param full_path string
---@return string
local function to_root_relative(full_path)
  local root = vim.fs.normalize(get_project_root())
  local norm_path = vim.fs.normalize(full_path)
  if norm_path:sub(1, #root + 1) == root .. "/" then
    return norm_path:sub(#root + 2)
  end
  return vim.fn.fnamemodify(full_path, ":.")
end

--- Opciones de la ventana para la terminal de AGY (Flotante o Split Lateral).
--- Se fija `count = 1` y `cwd = get_project_root()` para que Snacks.terminal
--- reutilice siempre el mismo ID de terminal incluso tras selecciones visuales.
---@param layout? "float"|"right" Diseño de ventana (por defecto `current_layout`)
---@return snacks.terminal.Opts
local function agy_term_opts(layout)
  layout = layout or current_layout

  ---@type snacks.win.Config
  local win_opts
  if layout == "right" then
    win_opts = {
      position = "right",
      width = 0.42,
      title = " 🚀 Antigravity CLI (agy) ",
      title_pos = "center",
    }
  else
    win_opts = {
      style = "float",
      border = "rounded",
      width = 0.90,
      height = 0.90,
      title = " 🚀 Antigravity CLI (agy) ",
      title_pos = "center",
    }
  end

  win_opts.on_win = function(win)
    vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave", "WinClosed" }, {
      buffer = win.buf,
      callback = function()
        vim.schedule(function()
          vim.cmd("silent! checktime")
        end)
      end,
    })
  end

  return {
    count = 1,
    cwd = get_project_root(),
    interactive = true,
    win = win_opts,
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
---@return string|nil rel_path Ruta relativa a la raíz del proyecto
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

  return to_root_relative(full_path)
end

--- Captura el rango de líneas y el texto seleccionado en modo Visual o Normal.
--- Si se invoca desde modo Visual, limpia el modo visual para actualizar las posiciones.
---@return { start_line: integer, end_line: integer, text: string, is_visual: boolean }
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
      is_visual = true,
    }
  end

  -- En modo Normal, toma la línea actual bajo el cursor
  local cur_line = vim.api.nvim_win_get_cursor(0)[1]
  local line_text = vim.api.nvim_get_current_line()
  return {
    start_line = cur_line,
    end_line = cur_line,
    text = line_text,
    is_visual = false,
  }
end

--- Formatea un resumen compacto del fragmento seleccionado para dar contexto
--- inmediato a `agy` sin saturar la línea del prompt si la selección es grande.
---@param sel { start_line: integer, end_line: integer, text: string }
---@return string
local function format_snippet_hint(sel)
  local trimmed = vim.trim(sel.text or "")
  if trimmed == "" then
    return ""
  end
  local single_line = trimmed:gsub("%s+", " ")
  if #single_line > 140 then
    single_line = single_line:sub(1, 137) .. "..."
  end
  return string.format(" [fragmento: `%s`]", single_line)
end

--- Envía un prompt a la sesión interactiva persistente de `agy`.
--- Si la terminal aún no existe, la crea y espera a que la TUI inicie antes de
--- inyectar el mensaje. Si ya existe, la muestra y envía el prompt al canal PTY.
---@param prompt string Texto o instrucción que se enviará a agy
local function send_to_agy(prompt)
  if not ensure_agy() then
    return
  end

  local opts = agy_term_opts(current_layout)
  local term, created = Snacks.terminal.get("agy", opts)
  if not term or not term.buf or not vim.api.nvim_buf_is_valid(term.buf) then
    vim.notify("No fue posible inicializar la terminal de Antigravity", vim.log.levels.ERROR, { title = "Antigravity" })
    return
  end

  -- Mostrar y enfocar la ventana de agy para ver la respuesta en vivo
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

--- Alterna la terminal de AGY en el layout solicitado ("float" o "right").
--- Si estaba abierta en otro layout, la cierra y la reabre en el nuevo layout
--- conservando intacto el mismo búfer y proceso PTY de `agy`.
---@param target_layout "float"|"right"
local function toggle_agy_layout(target_layout)
  if not ensure_agy() then
    return
  end

  local layout_changed = current_layout ~= target_layout
  current_layout = target_layout
  local opts = agy_term_opts(target_layout)

  if layout_changed then
    local existing = Snacks.terminal.get("agy", vim.tbl_extend("force", opts, { create = false }))
    if existing and existing:win_valid() then
      existing:hide()
    end
  end

  Snacks.terminal.toggle("agy", opts)
end

--- Solicita al usuario una instrucción mediante el input flotante de Neovim/Snacks
--- y la envía a `agy` junto con la ubicación exacta y fragmento del código seleccionado.
---@param action_type "edit"|"ask"|"test" Tipo de acción
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
  local snippet_hint = format_snippet_hint(sel)

  if action_type == "test" then
    vim.ui.input({
      prompt = string.format("🧪 Tests con AGY (%s:%s) [Enter = generar y ejecutar]: ", rel_file, range_label),
    }, function(instruction)
      if instruction == nil then
        return
      end
      local extra = vim.trim(instruction) ~= "" and (" Instrucciones adicionales: " .. vim.trim(instruction)) or ""
      local message = string.format(
        "Para el código en @%s (líneas %d a %d)%s: genera o actualiza los tests unitarios cubriendo casos principales y de borde, y ejecuta la suite correspondiente.%s",
        rel_file,
        sel.start_line,
        sel.end_line,
        snippet_hint,
        extra
      )
      send_to_agy(message)
    end)
    return
  end

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
        "En el archivo @%s (líneas %d a %d)%s, realiza el siguiente cambio directamente en el archivo: %s",
        rel_file,
        sel.start_line,
        sel.end_line,
        snippet_hint,
        vim.trim(instruction)
      )
    else
      message = string.format(
        "Respecto al archivo @%s (líneas %d a %d)%s: %s",
        rel_file,
        sel.start_line,
        sel.end_line,
        snippet_hint,
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
        { "<leader>ag", desc = "Toggle AGY Flotante", icon = "🖥️", mode = "n" },
        { "<leader>av", desc = "Toggle AGY Split Lateral", icon = "🪟", mode = "n" },
        { "<leader>ae", desc = "Editar selección/línea con AGY", icon = "✏️", mode = { "n", "x" } },
        { "<leader>aa", desc = "Preguntar a AGY sobre selección/línea", icon = "💬", mode = { "n", "x" } },
        { "<leader>at", desc = "Generar/ejecutar tests de selección", icon = "🧪", mode = { "n", "x" } },
        { "<leader>af", desc = "Enviar archivo actual a AGY", icon = "📄", mode = "n" },
        { "<leader>ad", desc = "Corregir diagnósticos LSP con AGY", icon = "🩺", mode = "n" },
        { "<leader>aq", desc = "Enviar Quickfix o búferes abiertos a AGY", icon = "📚", mode = "n" },
        { "<leader>ar", desc = "Revisar Git Diff / Commit con AGY", icon = "🔍", mode = "n" },
        { "<leader>as", desc = "Comandos Slash de AGY (/plan, /boost...)", icon = "⚡", mode = { "n", "x" } },
      },
    },
  },

  {
    "folke/snacks.nvim",
    keys = {
      -- 1. Mostrar / Ocultar la terminal flotante de Antigravity
      {
        "<leader>ag",
        function()
          toggle_agy_layout("float")
        end,
        mode = { "n", "t" },
        desc = "Toggle AGY Flotante",
      },

      -- 2. Mostrar / Ocultar la misma sesión de Antigravity en un Split Lateral Derecho
      {
        "<leader>av",
        function()
          toggle_agy_layout("right")
        end,
        mode = { "n", "t" },
        desc = "Toggle AGY Split Lateral",
      },

      -- 3. Seleccionar código + escribir comentario para que AGY edite el archivo directamente
      {
        "<leader>ae",
        function()
          prompt_with_selection("edit")
        end,
        mode = { "n", "x" },
        desc = "Editar selección/línea con AGY",
      },

      -- 4. Seleccionar código + hacer una pregunta o pedir explicación a AGY
      {
        "<leader>aa",
        function()
          prompt_with_selection("ask")
        end,
        mode = { "n", "x" },
        desc = "Preguntar a AGY sobre selección/línea",
      },

      -- 5. Generar o actualizar tests unitarios para la función/selección actual
      {
        "<leader>at",
        function()
          prompt_with_selection("test")
        end,
        mode = { "n", "x" },
        desc = "Generar/ejecutar tests de selección",
      },

      -- 6. Enviar el archivo actual completo con una instrucción opcional
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

      -- 7. Enviar diagnósticos LSP ordenados por severidad (ERROR > WARN > INFO > HINT)
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

          -- Priorizar errores críticos y warnings primero, y luego por número de línea
          table.sort(diags, function(a, b)
            local sa = a.severity or vim.diagnostic.severity.HINT
            local sb = b.severity or vim.diagnostic.severity.HINT
            if sa ~= sb then
              return sa < sb
            end
            return (a.lnum or 0) < (b.lnum or 0)
          end)

          local severity_names = {
            [vim.diagnostic.severity.ERROR] = "ERROR",
            [vim.diagnostic.severity.WARN] = "WARN",
            [vim.diagnostic.severity.INFO] = "INFO",
            [vim.diagnostic.severity.HINT] = "HINT",
          }

          local summary = {}
          for i, d in ipairs(diags) do
            if i <= 12 then
              local sev = severity_names[d.severity] or "DIAG"
              local msg = d.message:gsub("%s+", " ")
              local src = d.source and (" (" .. d.source .. ")") or ""
              table.insert(summary, string.format("[L%d %s%s] %s", d.lnum + 1, sev, src, msg))
            end
          end

          local prompt = string.format(
            "Corrige los siguientes diagnósticos LSP (%d total) en el archivo @%s: %s",
            #diags,
            rel_file,
            table.concat(summary, " ; ")
          )
          send_to_agy(prompt)
        end,
        mode = "n",
        desc = "Corregir diagnósticos LSP con AGY",
      },

      -- 8. Enviar archivos de la lista Quickfix (si tiene elementos) o todos los búferes abiertos
      {
        "<leader>aq",
        function()
          if not ensure_agy() then
            return
          end

          -- Guardar todos los búferes modificados antes de enviar contexto multi-archivo
          vim.cmd("silent! wall")

          local qf_list = vim.fn.getqflist()
          local refs = {}
          local seen = {}
          local context_label = ""

          if #qf_list > 0 then
            context_label = string.format("Quickfix (%d items)", #qf_list)
            local qf_details = {}
            for i, item in ipairs(qf_list) do
              if item.bufnr and item.bufnr > 0 and vim.api.nvim_buf_is_valid(item.bufnr) then
                local name = vim.api.nvim_buf_get_name(item.bufnr)
                if name ~= "" then
                  local rel = to_root_relative(name)
                  if not seen[rel] then
                    seen[rel] = true
                    table.insert(refs, "@" .. rel)
                  end
                  if i <= 10 then
                    local text = vim.trim(item.text or ""):gsub("%s+", " ")
                    table.insert(qf_details, string.format("[%s:L%d] %s", rel, item.lnum or 1, text))
                  end
                end
              end
            end

            if #refs > 0 then
              vim.ui.input({
                prompt = string.format("📚 Quickfix (%d archivos) -> Instrucción (Enter = resolver items): ", #refs),
              }, function(instruction)
                if instruction == nil then
                  return
                end
                local action = vim.trim(instruction) ~= "" and vim.trim(instruction)
                  or "Revisa y resuelve los siguientes puntos de la lista Quickfix"
                local msg = string.format(
                  "Contexto de archivos %s — %s: %s",
                  table.concat(refs, " "),
                  action,
                  table.concat(qf_details, " ; ")
                )
                send_to_agy(msg)
              end)
              return
            end
          end

          -- Fallback: recolectar todos los búferes de archivos reales abiertos en la sesión
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted and vim.bo[buf].buftype == "" then
              local name = vim.api.nvim_buf_get_name(buf)
              if name ~= "" then
                local rel = to_root_relative(name)
                if not seen[rel] then
                  seen[rel] = true
                  table.insert(refs, "@" .. rel)
                end
              end
            end
          end

          if #refs == 0 then
            vim.notify("No hay búferes de archivos ni lista Quickfix activa", vim.log.levels.WARN, {
              title = "Antigravity",
            })
            return
          end

          context_label = string.format("%d búferes abiertos", #refs)
          vim.ui.input({
            prompt = string.format("📚 Enviar %s (%s): ", context_label, table.concat(refs, " ")),
          }, function(instruction)
            if not instruction or vim.trim(instruction) == "" then
              return
            end
            local msg = string.format("Considerando los archivos %s: %s", table.concat(refs, " "), vim.trim(instruction))
            send_to_agy(msg)
          end)
        end,
        mode = "n",
        desc = "Enviar Quickfix o búferes abiertos a AGY",
      },

      -- 9. Flujos de Git con AGY (Code Review de git diff, mensaje de commit, análisis de conflictos)
      {
        "<leader>ar",
        function()
          if not ensure_agy() then
            return
          end
          vim.cmd("silent! wall")

          local actions = {
            {
              label = "🔍 Code Review de cambios actuales (git diff)",
              prompt = "Ejecuta `git status` y `git diff` (incluyendo staged) para revisar mis cambios actuales. Señala posibles bugs, regresiones, casos de borde o mejoras antes de hacer commit.",
            },
            {
              label = "📝 Sugerir / redactar Conventional Commit",
              prompt = "Analiza los cambios actuales en git (`git status` y `git diff`) y propón un mensaje de commit claro siguiendo Conventional Commits.",
            },
            {
              label = "🛠️ Resolver conflictos de merge actuales",
              prompt = "Busca archivos con conflictos de merge en git (`git status`), analiza ambas ramas y ayúdame a resolverlos limpiamente.",
            },
            {
              label = "📊 Explicar los últimos commits de la rama",
              prompt = "Revisa los últimos 5 commits del repositorio (`git log -n 5 --stat`) y dame un resumen ejecutivo de qué cambió.",
            },
          }

          vim.ui.select(actions, {
            prompt = "🔍 Acción de Git con Antigravity:",
            format_item = function(item)
              return item.label
            end,
          }, function(choice)
            if choice then
              send_to_agy(choice.prompt)
            end
          end)
        end,
        mode = "n",
        desc = "Revisar Git Diff / Commit con AGY",
      },

      -- 10. Selector interactivo de Slash Commands nativos de Antigravity CLI
      {
        "<leader>as",
        function()
          if not ensure_agy() then
            return
          end

          local sel = capture_selection()
          local full_path = vim.api.nvim_buf_get_name(0)
          local rel_file = (full_path ~= "" and vim.bo.buftype == "") and get_and_save_current_file() or nil

          local context_suffix = ""
          if rel_file then
            if sel.is_visual then
              context_suffix = string.format(
                "en @%s (líneas %d a %d)%s",
                rel_file,
                sel.start_line,
                sel.end_line,
                format_snippet_hint(sel)
              )
            else
              context_suffix = string.format("en @%s", rel_file)
            end
          end

          local slash_commands = {
            {
              cmd = "/plan",
              label = "🗺️  /plan     — Planificar paso a paso antes de escribir código",
              needs_input = true,
            },
            {
              cmd = "/boost",
              label = "🔥 /boost    — Razonamiento profundo, múltiples perspectivas y verificación",
              needs_input = true,
            },
            {
              cmd = "/grill-me",
              label = "🎯 /grill-me — Entrevista interactiva para alinear decisiones de diseño",
              needs_input = true,
            },
            {
              cmd = "/goal",
              label = "🏁 /goal     — Ejecución exhaustiva hasta cumplir la meta por completo",
              needs_input = true,
            },
            {
              cmd = "/teamwork",
              label = "🤝 /teamwork — Orquestar equipo de subagentes autónomos en paralelo",
              needs_input = true,
            },
            {
              cmd = "/learn",
              label = "🧠 /learn    — Guardar aprendizaje o convención para futuras sesiones",
              needs_input = true,
            },
            {
              cmd = "/compact",
              label = "🧹 /compact  — Compactar y resumir el historial para liberar ventana de contexto",
              needs_input = false,
            },
          }

          vim.ui.select(slash_commands, {
            prompt = "⚡ Comando Slash de Antigravity:",
            format_item = function(item)
              return item.label
            end,
          }, function(choice)
            if not choice then
              return
            end

            if not choice.needs_input then
              send_to_agy(choice.cmd)
              return
            end

            local input_prompt = context_suffix ~= ""
                and string.format("%s (%s): ", choice.cmd, context_suffix)
              or string.format("%s -> Objetivo: ", choice.cmd)

            vim.ui.input({ prompt = input_prompt }, function(instruction)
              if not instruction or vim.trim(instruction) == "" then
                return
              end
              local msg = context_suffix ~= ""
                  and string.format("%s %s: %s", choice.cmd, context_suffix, vim.trim(instruction))
                or string.format("%s %s", choice.cmd, vim.trim(instruction))
              send_to_agy(msg)
            end)
          end)
        end,
        mode = { "n", "x" },
        desc = "Comandos Slash de AGY (/plan, /boost...)",
      },
    },
  },
}
