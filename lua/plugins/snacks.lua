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
        -- Explorador lateral (<Space>e): oculta los dotfiles e ignorados por defecto,
        -- pero muestra SIEMPRE los archivos ocultos de la lista blanca (include)
        explorer = {
          hidden = false,
          ignored = false,
          include = {
            ".cargo",
            ".env*",
            ".gitignore",
            ".dockerignore",
            ".github",
            ".gitlab-ci.yml",
            ".editorconfig",
            ".prettierrc*",
            ".eslintrc*",
          },
          exclude = {
            ".git",
            ".DS_Store",
            "__pycache__",
            ".pytest_cache",
            ".mypy_cache",
            ".ruff_cache",
          },
        },
        -- Buscador de archivos (<Space><Space>):
        files = {
          hidden = true, -- Muestra archivos ocultos (dotfiles)
          ignored = false, -- Cambia a true si también quieres ver los ignorados por .gitignore
          exclude = {
            ".git",
            ".DS_Store",
            "__pycache__",
            ".pytest_cache",
            ".mypy_cache",
            ".ruff_cache",
            ".venv",
            "node_modules",
            "target",
          },
        },
      },
    },
  },
}
