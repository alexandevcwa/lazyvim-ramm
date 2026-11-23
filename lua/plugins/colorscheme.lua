---@module "plugins.colorscheme"
--- Configuración del esquema de color principal (OneDark)
return {
  {
    "ribru17/bamboo.nvim",
    priority = 1000, -- Cargar antes que los demás plugins para evitar parpadeos
    opts = {
      --style = "darker", -- Opciones: 'dark', 'darker', 'cool', 'deep', 'warm', 'warmer', 'light'
      --transparent = false, -- Permite apreciar la opacidad (0.50) y el blur configurados en Kitty
      --term_colors = true,
      --lualine = {
      --  transparent = false,
      --},
    },
    config = function(_, opts)
      require("bamboo").setup(opts)
      require("bamboo").load()
    end,
  },
}
