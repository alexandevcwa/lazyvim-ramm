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
    -- Tu configuración inicial de la UI
    vim.g.db_ui_use_nerd_fonts = 1

    -- Carpeta donde se guardarán tus consultas SQL
    vim.g.db_ui_save_location = vim.fn.stdpath("config") .. require("plenary.path").path.sep .. "db_ui"

    -- Conexiones a base de datos
  end,
}
