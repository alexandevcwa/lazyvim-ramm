---@module "plugins.dadbod"
--- Extensión del extra lazyvim.plugins.extras.lang.sql para vim-dadbod-ui
return {
  "kristijanhusak/vim-dadbod-ui",
  optional = true,
  init = function()
    local data_path = vim.fn.stdpath("data")
    vim.g.db_ui_auto_execute_table_helpers = 1
    -- Mantener las conexiones y consultas guardadas dentro de ~/.config/nvim/db_ui
    vim.g.db_ui_save_location = vim.fn.stdpath("config") .. "/db_ui"
    vim.g.db_ui_show_database_icon = 1
    vim.g.db_ui_tmp_query_location = data_path .. "/dadbod_ui/tmp"
    vim.g.db_ui_use_nerd_fonts = 1
    vim.g.db_ui_use_nvim_notify = 1
    -- Evitar ejecución accidental de consultas al guardar manualmente un buffer SQL
    vim.g.db_ui_execute_on_save = 0
  end,
}
