return {
  {
    "barrett-ruth/live-server.nvim",
    build = "npm install -g live-server", -- Lo instala globalmente si no lo tienes
    cmd = { "LiveServerStart", "LiveServerStop" },
    config = true,
    keys = {
      -- <leader>ls para iniciar el servidor
      { "<leader>ls", "<cmd>LiveServerStart<cr>", desc = "Iniciar Live Server" },
      -- <leader>lx para detener el servidor
      { "<leader>lx", "<cmd>LiveServerStop<cr>", desc = "Detener Live Server" },
    },
  },
}
