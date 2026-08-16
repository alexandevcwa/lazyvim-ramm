-- ============================================================================
-- Keymaps (Mapeos y Atajos de Teclado)
-- ============================================================================
-- Los atajos se cargan automáticamente en el evento 'VeryLazy'.
-- Atajos predeterminados de LazyVim:
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

local map = vim.keymap.set

-- ----------------------------------------------------------------------------
-- Registro de Grupos en Which-Key
-- ----------------------------------------------------------------------------
local ok_wk, wk = pcall(require, "which-key")
if ok_wk then
  wk.add({
    { "<leader>a", group = "Antigravity (AGY)", icon = "🚀" },
    { "<leader>j", group = "Java Creator", icon = "☕" },
    { "<leader>o", group = "Octo (GitHub)", icon = "🐙" },
  })
end

-- ============================================================================
-- Antigravity CLI: Integración de Flujo de Trabajo con IA
-- ============================================================================

--- Analizar el archivo actual en una terminal flotante de AGY
map("n", "<leader>af", function()
  local file = vim.fn.expand("%:p")
  if file == "" then
    vim.notify("No hay ningún archivo abierto en el búfer actual", vim.log.levels.WARN, { title = "Antigravity" })
    return
  end
  Snacks.terminal.open("agy run " .. vim.fn.shellescape(file), {
    win = { style = "float", border = "rounded", width = 0.85, height = 0.85 },
  })
end, { desc = "Analizar archivo actual con AGY" })

--- Enviar el texto seleccionado en modo visual directamente a AGY
map("v", "<leader>as", function()
  vim.cmd('noau normal! "vy')
  local selection = vim.fn.getreg("v")
  local cmd = string.format("echo %s | agy", vim.fn.shellescape(selection))
  Snacks.terminal.open(cmd, {
    win = { style = "float", border = "rounded", width = 0.85, height = 0.85 },
  })
end, { desc = "Enviar texto seleccionado a AGY" })
