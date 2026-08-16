---@module "plugins.octo"
--- Integración completa con GitHub (Issues, PRs, Revisiones, Notificaciones)
return {
  "pwntester/octo.nvim",
  cmd = "Octo",
  opts = {
    picker = "snacks", -- Utiliza el selector nativo de snacks.nvim de LazyVim
    enable_builtin = true, -- El comando :Octo abre un menú selector interactivo
  },
  keys = {
    {
      "<leader>oi",
      "<CMD>Octo issue list<CR>",
      desc = "Listar Issues de GitHub",
    },
    {
      "<leader>op",
      "<CMD>Octo pr list<CR>",
      desc = "Listar Pull Requests",
    },
    {
      "<leader>od",
      "<CMD>Octo discussion list<CR>",
      desc = "Listar Discusiones",
    },
    {
      "<leader>on",
      "<CMD>Octo notification list<CR>",
      desc = "Listar Notificaciones de GitHub",
    },
    {
      "<leader>os",
      function()
        require("octo.utils").create_base_search_command({ include_current_repo = true })
      end,
      desc = "Buscar en GitHub (Repo Actual)",
    },
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "folke/snacks.nvim",
    "nvim-tree/nvim-web-devicons",
  },
}
