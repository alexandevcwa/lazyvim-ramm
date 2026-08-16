-- ============================================================================
-- Autocmds (Comandos Automáticos)
-- ============================================================================
-- Se cargan automáticamente en el evento 'VeryLazy'.
-- Autocmds por defecto en LazyVim:
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

-- ============================================================================
-- Antigravity / Modificaciones Externas: Autorecarga de Búfers
-- ============================================================================
-- Recarga automáticamente los archivos cuando herramientas externas o
-- subagentes de Antigravity los modifican en el sistema de archivos.
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave", "CursorHold" }, {
  group = vim.api.nvim_create_augroup("AgentAutoRead", { clear = true }),
  desc = "Recarga automática del búfer si el archivo fue modificado externamente",
  callback = function()
    -- Evitar recargar si el usuario se encuentra en la línea de comandos de Neovim
    if vim.fn.mode() ~= "c" then
      vim.cmd("checktime")
    end
  end,
})
