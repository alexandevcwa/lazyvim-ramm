-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

-- ==========================================
-- Antigravity CLI: Atajos y Envíos
-- ==========================================
local map = vim.keymap.set
local wk = require("which-key")

-- Registrar el menú flotante en Which-Key
wk.add({
  { "<leader>a", group = "Antigravity", icon = "🚀" },
})

-- <leader>af: Analizar el archivo actual en AGY
map("n", "<leader>af", function()
  local file = vim.fn.expand("%:p")
  if file == "" then
    vim.notify("No hay un archivo abierto", vim.log.levels.WARN)
    return
  end
  Snacks.terminal.open("agy run " .. vim.fn.shellescape(file), {
    win = { style = "float", border = "rounded", width = 0.85, height = 0.85 },
  })
end, { desc = "Analizar archivo actual" })

-- <leader>as: Enviar el texto seleccionado a AGY (Modo Visual)
map("v", "<leader>as", function()
  vim.cmd('noau normal! "vy')
  local selection = vim.fn.getreg("v")
  local cmd = string.format("echo %s | agy", vim.fn.shellescape(selection))
  Snacks.terminal.open(cmd, {
    win = { style = "float", border = "rounded", width = 0.85, height = 0.85 },
  })
end, { desc = "Enviar selección a AGY" })
