-- En lua/plugins/spring-boot.lua
return {
  "JavaHello/spring-boot.nvim",
  dependencies = {
    "mfussenegger/nvim-jdtls",
    "neovim/nvim-lspconfig",
  },
  ft = { "java", "yaml", "properties" },
  opts = {},
}
