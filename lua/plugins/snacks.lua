---@module "plugins.snacks"
--- Configuración centralizada de snacks.nvim (Dashboard y Picker)
return {
  "folke/snacks.nvim",
  opts = {
    dashboard = {
      preset = {
        header = [[
   ▄▄▄▄███▄▄▄▄      ▄████████  ▄████████    ▄█    █▄     ▄█  ███▄▄▄▄      ▄████████ 
 ▄██▀▀▀███▀▀▀██▄   ███    ███ ███    ███   ███    ███   ███  ███▀▀▀██▄   ███    ███ 
 ███   ███   ███   ███    ███ ███    █▀    ███    ███   ███▌ ███   ███   ███    █▀  
 ███   ███   ███   ███    ███ ███         ▄███▄▄▄▄███▄▄ ███▌ ███   ███  ▄███▄▄▄     
 ███   ███   ███ ▀███████████ ███        ▀▀███▀▀▀▀███▀  ███▌ ███   ███ ▀▀███▀▀▀     
 ███   ███   ███   ███    ███ ███    █▄    ███    ███   ███  ███   ███   ███    █▄  
 ███   ███   ███   ███    ███ ███    ███   ███    ███   ███  ███   ███   ███    ███ 
  ▀█   ███   █▀    ███    █▀  ████████▀    ███    █▀    █▀    ▀█   █▀    ██████████ 
        ]],
      },
    },
    picker = {
      sources = {
        files = {
          hidden = true, -- Muestra archivos ocultos (dotfiles)
          ignored = false, -- Cambia a true si también quieres ver los ignorados por .gitignore
        },
      },
    },
  },
}
