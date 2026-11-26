-- ============================================================================
-- Options (Opciones Generales de Neovim)
-- ============================================================================
-- Este archivo se carga automáticamente ANTES del inicio de lazy.nvim.
-- Opciones predeterminadas de LazyVim:
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

-- Ecosistema Python (leído por lazyvim.plugins.extras.lang.python)
vim.g.lazyvim_python_lsp = "basedpyright"
vim.g.lazyvim_python_ruff = "ruff"

-- Ecosistema Rust (leído por lazyvim.plugins.extras.lang.rust)
vim.g.lazyvim_rust_diagnostics = "rust-analyzer"

-- Opciones personalizadas adicionales
-- local opt = vim.opt
-- opt.relativenumber = true -- Números de línea relativos (ya activo por defecto en LazyVim)
-- opt.wrap = false           -- Deshabilitar salto de línea visual
-- opt.scrolloff = 8          -- Margen de líneas al hacer scroll
