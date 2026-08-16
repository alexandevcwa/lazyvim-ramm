---@module "plugins.dadbod"
--- Configuración de la interfaz de base de datos (vim-dadbod-ui)
return {
  "kristijanhusak/vim-dadbod-ui",
  dependencies = {
    { "tpope/vim-dadbod", lazy = true },
    { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
  },
  cmd = {
    "DBUI",
    "DBUIToggle",
    "DBUIAddConnection",
    "DBUIFindBuffer",
  },
  init = function()
    -- Habilitar iconos Nerd Font en el explorador de base de datos
    vim.g.db_ui_use_nerd_fonts = 1

    -- Directorio personalizado para almacenar consultas SQL guardadas
    local ok_plenary, plenary_path = pcall(require, "plenary.path")
    local sep = ok_plenary and plenary_path.path.sep or "/"
    vim.g.db_ui_save_location = vim.fn.stdpath("config") .. sep .. "db_ui"
  end,
}
