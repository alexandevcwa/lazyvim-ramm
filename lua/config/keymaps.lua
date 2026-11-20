-- ============================================================================
-- Keymaps (Mapeos y Atajos de Teclado)
-- ============================================================================
-- Los atajos se cargan automáticamente en el evento 'VeryLazy'.
-- Atajos predeterminados de LazyVim:
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

-- ----------------------------------------------------------------------------
-- Registro de Grupos en Which-Key
-- ----------------------------------------------------------------------------
local ok_wk, wk = pcall(require, "which-key")
if ok_wk then
  wk.add({
    { "<leader>a", group = "Antigravity (AGY)", icon = "🚀", mode = { "n", "x" } },
    { "<leader>j", group = "Java Creator", icon = "☕" },
    { "<leader>o", group = "Octo (GitHub)", icon = "🐙" },
  })
end

-- Nota: los atajos de Antigravity (<leader>ag, <leader>af, <leader>as) se definen
-- junto a su integración con snacks.nvim en lua/plugins/antigravity.lua.
