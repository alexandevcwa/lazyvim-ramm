---@module "plugins.antigravity"
--- Integración de Antigravity (AGY CLI) con la terminal flotante de snacks.nvim
return {
  {
    "folke/snacks.nvim",
    opts = {
      terminal = {
        win = {
          style = "float",
          border = "rounded",
        },
      },
    },
    keys = {
      {
        "<leader>ag",
        function()
          Snacks.terminal.toggle("agy", {
            interactive = true, -- Recibe entradas interactivas del usuario
            win = {
              style = "float",
              border = "rounded",
              width = 0.90,
              height = 0.90,
            },
            on_show = function()
              vim.cmd("startinsert") -- Inicia directamente en modo inserción/terminal
            end,
          })
        end,
        desc = "Toggle Terminal AGY CLI",
      },
    },
  },
}
