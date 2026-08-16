-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.lsp.config("jdtls", {
  cmd = {
    vim.fn.stdpath("data") .. "/mason/bin/jdtls",
    "--java-executable=/home/rmachicm/.sdkman/candidates/java/21.0.12-oracle/bin/java",
  },
  settings = {
    java = {
      -- Ruta al directorio raíz de tu JDK 21 (NO a /bin/java, sino a la carpeta del JDK)
      home = "/home/rmachicm/.sdkman/candidates/java/21.0.12-oracle/",
    },
  },
})

vim.lsp.enable("jdtls")
