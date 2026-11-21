---@module "plugins.render-markdown"
--- Renderizado enriquecido en el búfer para archivos Markdown (README, notas, etc.)
return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
  },
  ft = { "markdown", "norg", "rmd", "org" },
  ---@module 'render-markdown'
  ---@type render.md.UserConfig
  opts = {
    code = {
      sign = false,
      width = "block",
      right_pad = 1,
    },
    heading = {
      sign = false,
    },
  },
  config = function(_, opts)
    require("render-markdown").setup(opts)
    if Snacks and Snacks.toggle then
      Snacks.toggle({
        name = "Render Markdown",
        get = require("render-markdown").get,
        set = require("render-markdown").set,
      }):map("<leader>um")
    else
      vim.keymap.set("n", "<leader>um", "<cmd>RenderMarkdown toggle<cr>", { desc = "Alternar Render Markdown" })
    end
  end,
}
