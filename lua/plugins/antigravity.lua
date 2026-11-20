---@module "plugins.antigravity"
--- Integración de Antigravity (AGY CLI) con la terminal flotante de snacks.nvim

--- Construye las opciones de ventana flotante para las terminales de AGY
---@param width number
---@param height number
---@return table
local function agy_float_win(width, height)
  return {
    style = "float",
    border = "rounded",
    width = width,
    height = height,
  }
end

--- Verifica que el binario agy esté disponible en el PATH
---@return boolean
local function ensure_agy()
  if vim.fn.executable("agy") == 1 then
    return true
  end
  vim.notify("No se encontró el ejecutable 'agy' en el PATH", vim.log.levels.ERROR, { title = "Antigravity" })
  return false
end

return {
  {
    "folke/snacks.nvim",
    keys = {
      {
        "<leader>ag",
        function()
          if not ensure_agy() then
            return
          end
          Snacks.terminal.toggle("agy", {
            interactive = true,
            win = agy_float_win(0.90, 0.90),
            on_show = function()
              vim.cmd("startinsert")
            end,
          })
        end,
        desc = "Toggle Terminal AGY CLI",
      },
      {
        "<leader>af",
        function()
          if not ensure_agy() then
            return
          end
          local file = vim.api.nvim_buf_get_name(0)
          if file == "" or vim.bo.buftype ~= "" then
            vim.notify(
              "No hay ningún archivo guardado abierto en el búfer actual",
              vim.log.levels.WARN,
              { title = "Antigravity" }
            )
            return
          end
          Snacks.terminal.open("agy run " .. vim.fn.shellescape(file), {
            win = agy_float_win(0.85, 0.85),
          })
        end,
        desc = "Analizar archivo actual con AGY",
      },
      {
        "<leader>as",
        function()
          if not ensure_agy() then
            return
          end
          local lines = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = vim.fn.mode() })
          local selection = table.concat(lines, "\n")
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)

          if selection == "" then
            vim.notify("No hay texto seleccionado para enviar a AGY", vim.log.levels.WARN, { title = "Antigravity" })
            return
          end

          local cmd = string.format("printf '%%s\\n' %s | agy", vim.fn.shellescape(selection))
          Snacks.terminal.open(cmd, {
            win = agy_float_win(0.85, 0.85),
          })
        end,
        mode = "x",
        desc = "Enviar texto seleccionado a AGY",
      },
    },
  },
}
