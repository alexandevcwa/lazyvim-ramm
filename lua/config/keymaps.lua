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
    -- Grupo principal y submenú de Antigravity (AGY) con iconos en Which-Key
    { "<leader>a", group = "Antigravity (AGY)", icon = "🚀", mode = { "n", "x" } },
    { "<leader>ag", desc = "Toggle Terminal AGY CLI", icon = "🖥️", mode = "n" },
    { "<leader>ae", desc = "Editar selección/línea con comentario (AGY)", icon = "✏️", mode = { "n", "x" } },
    { "<leader>aa", desc = "Preguntar a AGY sobre selección/línea", icon = "💬", mode = { "n", "x" } },
    { "<leader>af", desc = "Enviar archivo actual a AGY", icon = "📄", mode = "n" },
    { "<leader>ad", desc = "Corregir diagnósticos LSP actuales con AGY", icon = "🩺", mode = "n" },

    -- Otros grupos personalizados
    { "<leader>j", group = "Java Creator", icon = "☕" },
    { "<leader>o", group = "Octo (GitHub)", icon = "🐙" },
    { "<leader>R", group = "Rust / Cargo", icon = "🦀", mode = { "n", "v" } },
  })
end

-- Nota: los atajos de Antigravity (<leader>ag, <leader>ae, <leader>aa, <leader>af, <leader>ad)
-- se definen junto a su integración con snacks.nvim en lua/plugins/antigravity.lua.
