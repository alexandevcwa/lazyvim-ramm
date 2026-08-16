return {
  {
    "folke/snacks.nvim",
    keys = {
      {
        "<leader>ag",
        function()
          Snacks.terminal.toggle("agy", {
            interactive = true, -- Asegura que reciba las teclas directamente
            win = {
              style = "float",
              border = "rounded",
              width = 0.90,
              height = 0.90,
            },
            on_show = function()
              vim.cmd("startinsert") -- Entra en modo terminal automáticamente
            end,
          })
        end,
        -- mode = { "n", "t" }, -- n = Normal, t = Terminal
        desc = "Abrir AGY CLI",
      },
    },
  },
}
