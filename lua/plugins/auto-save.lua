return {
  "okuuva/auto-save.nvim",
  cmd = "ASToggle",
  event = { "InsertLeave", "TextChanged" },
  opts = {
    enabled = true,
    -- Fundamental: evita disparar el formateador (Conform) en cada autoguardado
    noautocmd = true,
    execution_message = {
      message = function()
        return ("Autoguardado a las " .. vim.fn.strftime("%H:%M:%S"))
      end,
      dim = 0.18,
      cleaning_interval = 1250,
    },
  },
  keys = {
    { "<leader>ua", "<cmd>ASToggle<cr>", desc = "Alternar AutoSave" },
  },
}
