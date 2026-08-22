return {
  "folke/snacks.nvim",
  opts = {
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
