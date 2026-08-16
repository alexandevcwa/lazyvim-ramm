---@module "plugins.colorscheme"
--- Configuración del esquema de color principal (OneDark)
return {
  {
    "navarasu/onedark.nvim",
    priority = 1000, -- Cargar antes que los demás plugins para evitar parpadeos
    config = function()
      require("onedark").setup({
        style = "darker", -- Opciones: 'dark', 'darker', 'cool', 'deep', 'warm', 'warmer', 'light'
      })
      require("onedark").load()
    end,
  },
}
