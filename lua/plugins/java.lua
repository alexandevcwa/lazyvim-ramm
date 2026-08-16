---@module "plugins.java"
--- Configuración del ecosistema Java: LSP (nvim-jdtls) y utilidades de scaffolding (java-creator-nvim)
return {
  -- Configuración y personalización del Language Server (JDTLS)
  {
    "mfussenegger/nvim-jdtls",
    opts = function(_, opts)
      -- Ruta al binario del JDK y ruta home de SDKMAN
      local java_bin = "/home/rmachicm/.sdkman/candidates/java/21.0.12-oracle/bin/java"
      local java_home = "/home/rmachicm/.sdkman/candidates/java/21.0.12-oracle"

      -- Configurar comando jdtls con el ejecutable de Java y soporte para Lombok
      local mason_path = vim.fn.stdpath("data") .. "/mason"
      local lombok_jar = mason_path .. "/share/jdtls/lombok.jar"
      if not (vim.uv or vim.loop).fs_stat(lombok_jar) then
        lombok_jar = mason_path .. "/packages/jdtls/lombok.jar"
      end

      opts.cmd = {
        mason_path .. "/bin/jdtls",
        "--java-executable=" .. java_bin,
      }

      if (vim.uv or vim.loop).fs_stat(lombok_jar) then
        table.insert(opts.cmd, string.format("--jvm-arg=-javaagent:%s", lombok_jar))
      end

      -- Ajustes de Java LSP
      opts.settings = vim.tbl_deep_extend("force", opts.settings or {}, {
        java = {
          home = java_home,
        },
      })
    end,
  },

  -- Generador de clases, interfaces, records y enums para Java
  {
    "alessio-vivaldelli/java-creator-nvim",
    ft = "java",
    event = "VeryLazy",
    dependencies = {
      { "rcarriga/nvim-notify", optional = true },
    },
    config = function()
      require("java-creator-nvim").setup({
        options = {
          java_version = 21,
          auto_open = true,
          use_notify = true,
          custom_src_path = "backend/src/main/java",
          src_patterns = { "src/main/java", "src/test/java", "src" },
          project_markers = {
            "pom.xml",
            "build.gradle",
            "build.gradle.kts",
            "settings.gradle",
            "settings.gradle.kts",
            ".project",
          },
          notification_timeout = 3000,
        },
        keymaps = {
          java_new = "<leader>jn",
          java_class = "<leader>jc",
          java_interface = "<leader>ji",
          java_enum = "<leader>je",
          java_record = "<leader>jr",
        },
        default_imports = {
          record = { "java.util.*" },
        },
      })

      vim.keymap.set("i", "<C-space>", 'pumvisible() ? "\\<C-n>" : "\\<C-x>\\<C-u>"', {
        expr = true,
        desc = "Autocompletado omni en modo inserción",
      })
    end,
  },
}
