---@module "plugins.rust"
--- ============================================================================
--- Ecosistema Profesional de Rust para LazyVim (Backend, Sistemas, CLI y Wasm)
--- ============================================================================
--- Arquitectura oficial basada en `lazyvim.plugins.extras.lang.rust`:
---   1. LSP y herramientas avanzadas: `mrcjkb/rustaceanvim` + `rust-analyzer` (vía rustup).
---   2. Gestión inteligente de Cargo.toml: `Saecki/crates.nvim` (LSP en proceso + blink.cmp).
---   3. Depuración nativa (DAP): `codelldb` (vía Mason) con pretty-printers de tipos Rust.
---   4. Ejecución de tests: `rustaceanvim.neotest` integrado en `neotest` (cargo-nextest / test).
---   5. Formateo y documentación: `rustfmt` (`conform.nvim`) y `rustdoc` (`neogen`).
---   6. Blindaje activo (Guardrails) de 4 capas contra plugins obsoletos y servidores LSP duplicados.
--- ============================================================================

local uv = vim.uv or vim.loop

---@type table<string, boolean>
local notified_messages = {}

--- Emite una notificación única por sesión para evitar mensajes repetitivos
---@param msg string
---@param level integer
local function notify_once(msg, level)
  if notified_messages[msg] then
    return
  end
  notified_messages[msg] = true
  vim.schedule(function()
    vim.notify(msg, level, { title = "Rust (LazyVim)" })
  end)
end

--- Capa 3 de Blindaje: Detecta si existe un binario sombra de rust-analyzer en Mason
--- que pueda interferir en el PATH con la versión del toolchain activo de rustup.
local function check_mason_shadow_binary()
  local mason_ra = vim.fn.stdpath("data") .. "/mason/bin/rust-analyzer"
  if uv.fs_stat(mason_ra) then
    notify_once(
      "Se detectó 'rust-analyzer' instalado en Mason (~/.local/share/nvim/mason/bin/rust-analyzer).\n"
        .. "Ejecuta :MasonUninstall rust-analyzer para evitar conflictos de ABI con rustup.",
      vim.log.levels.WARN
    )
  end
end

--- Capa 4 de Blindaje: Resuelve el ejecutable de rust-analyzer directamente desde rustup
--- respetando archivos `rust-toolchain.toml` del proyecto e ignorando binarios de Mason.
---@return string[]
local function resolve_rust_analyzer_cmd()
  if vim.fn.executable("rustup") == 1 then
    local cwd = uv.cwd()
    local ok, proc = pcall(vim.system, { "rustup", "which", "rust-analyzer" }, { text = true, cwd = cwd })
    if ok and proc then
      local res = proc:wait(1500)
      if res and res.code == 0 and res.stdout then
        local bin = vim.trim(res.stdout)
        if bin ~= "" and uv.fs_stat(bin) then
          return { bin }
        end
      else
        notify_once(
          "El componente 'rust-analyzer' no está instalado en el toolchain activo de rustup.\n"
            .. "Ejecuta en tu terminal: rustup component add rust-analyzer",
          vim.log.levels.ERROR
        )
      end
    end
  end

  local fallback = vim.fn.exepath("rust-analyzer")
  if fallback ~= "" then
    return { fallback }
  end
  return { "rust-analyzer" }
end

--- Envuelve los argumentos de `codelldb terminal-agent` para silenciar el falso error
--- `Error("EOF while parsing a value", line: 1, column: 0)` al cerrar el socket TCP
--- cuando el binario depurado finaliza, preservando intacto el PTY (`/dev/pts/*`).
---@param args any
---@return any
local function wrap_codelldb_terminal_args(args)
  if type(args) == "table" and args[2] == "terminal-agent" then
    local wrapped = { "sh", "-c", '"$@" 2>/dev/null; exit 0', "codelldb-terminal" }
    vim.list_extend(wrapped, args)
    return wrapped
  end
  return args
end

local codelldb_eof_fix_installed = false

--- Instala el filtro anti-EOF para `codelldb terminal-agent` en `nvim-dap`
local function install_codelldb_eof_fix()
  if codelldb_eof_fix_installed then
    return
  end
  codelldb_eof_fix_installed = true

  -- 1. Interceptar reverse request `runInTerminal` en `dap.session` si está disponible
  local ok_session, Session = pcall(require, "dap.session")
  if ok_session and type(Session) == "table" and type(Session.handle_body) == "function" then
    local orig_handle_body = Session.handle_body
    Session.handle_body = function(self, body)
      if type(body) == "table" and body.type == "request" and body.command == "runInTerminal" then
        if type(body.arguments) == "table" then
          body.arguments.args = wrap_codelldb_terminal_args(body.arguments.args)
        end
      end
      return orig_handle_body(self, body)
    end
  end

  -- 2. Respaldo en `jobstart` / `termopen` por si `dap.session` se carga después
  for _, fn_name in ipairs({ "jobstart", "termopen" }) do
    local ok_fn, orig_fn = pcall(function()
      return vim.fn[fn_name]
    end)
    if ok_fn and type(orig_fn) == "function" then
      vim.fn[fn_name] = function(cmd, ...)
        return orig_fn(wrap_codelldb_terminal_args(cmd), ...)
      end
    end
  end
end

--- Resuelve de forma defensiva las rutas de CodeLLDB (`codelldb` y `liblldb`) instaladas por Mason
---@return string|nil codelldb_path
---@return string|nil liblldb_path
local function resolve_codelldb_paths()
  local ext_path = vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension/"
  local codelldb_path = ext_path .. "adapter/codelldb"
  if not uv.fs_stat(codelldb_path) then
    return nil, nil
  end

  local sysname = uv.os_uname().sysname
  local liblldb_path
  if sysname == "Darwin" then
    liblldb_path = ext_path .. "lldb/lib/liblldb.dylib"
  elseif sysname:find("Windows") then
    liblldb_path = ext_path .. "lldb/bin/liblldb.dll"
  else
    liblldb_path = ext_path .. "lldb/lib/liblldb.so"
  end

  if not uv.fs_stat(liblldb_path) then
    return nil, nil
  end
  return codelldb_path, liblldb_path
end

--- Registra atajos contextuales avanzados de RustLsp exclusivos para búfers `.rs`
---@param bufnr integer
local function register_rust_keymaps(bufnr)
  local map = function(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { silent = true, buffer = bufnr, desc = desc })
  end

  map("<leader>Re", function()
    vim.cmd.RustLsp("expandMacro")
  end, "Expandir macro recursivamente (Rust)")

  map("<leader>RE", function()
    vim.cmd.RustLsp({ "explainError", "current" })
  end, "Explicar código de error actual (rustc)")

  map("<leader>Rd", function()
    vim.cmd.RustLsp({ "renderDiagnostic", "current" })
  end, "Renderizar diagnóstico completo (Cargo)")

  map("<leader>Rc", function()
    vim.cmd.RustLsp("openCargo")
  end, "Abrir Cargo.toml del crate")

  map("<leader>RD", function()
    vim.cmd.RustLsp("externalDocs")
  end, "Abrir documentación externa (docs.rs)")

  map("<leader>Rp", function()
    vim.cmd.RustLsp("parentModule")
  end, "Ir al módulo padre (Rust)")

  map("<leader>Rm", function()
    vim.cmd.RustLsp("rebuildProcMacros")
  end, "Reconstruir proc-macros (Rust)")

  map("<leader>Rr", function()
    vim.cmd.RustLsp("runnables")
  end, "Ejecutar binario (Cargo Runnables)")

  map("<leader>Rl", function()
    vim.cmd.RustLsp({ "runnables", bang = true })
  end, "Repetir último ejecutable de Cargo (Rust)")

  map("<leader>RL", function()
    vim.cmd.RustLsp({ "debuggables", bang = true })
  end, "Repetir última sesión de depuración (Rust)")

  map("<leader>RJ", function()
    vim.cmd.RustLsp("joinLines")
  end, "Unir líneas inteligentemente (Rust)")
end

--- Registra atajos contextuales de `crates.nvim` exclusivos para archivos `Cargo.toml`
---@param bufnr integer
local function register_crates_keymaps(bufnr)
  local crates = require("crates")
  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { silent = true, buffer = bufnr, desc = desc })
  end

  map("n", "<leader>Rt", crates.toggle, "Alternar información virtual de crates")
  map("n", "<leader>Rr", crates.reload, "Recargar metadatos de crates.io")
  map("n", "<leader>Rv", crates.show_versions_popup, "Ver versiones disponibles del crate")
  map("n", "<leader>Rf", crates.show_features_popup, "Ver y activar features del crate")
  map("n", "<leader>Rd", crates.show_dependencies_popup, "Ver dependencias del crate")
  map("n", "<leader>Ru", crates.update_crate, "Actualizar crate en rango compatible")
  map("v", "<leader>Ru", crates.update_crates, "Actualizar crates seleccionados")
  map("n", "<leader>RU", crates.update_all_crates, "Actualizar todos los crates (compatible)")
  map("n", "<leader>Ra", crates.upgrade_crate, "Subir crate a última versión mayor (upgrade)")
  map("v", "<leader>Ra", crates.upgrade_crates, "Subir crates seleccionados a última versión")
  map("n", "<leader>RA", crates.upgrade_all_crates, "Subir todos los crates a última versión")
  map("n", "<leader>RH", crates.open_homepage, "Abrir página principal del crate")
  map("n", "<leader>RR", crates.open_repository, "Abrir repositorio Git del crate")
  map("n", "<leader>RD", crates.open_documentation, "Abrir documentación en docs.rs")
  map("n", "<leader>RC", crates.open_crates_io, "Abrir ficha en crates.io")
end

return {
  -- ==========================================================================
  -- Capa 1 de Blindaje: Deshabilitar explícitamente plugins obsoletos/redundantes
  -- Impide que dependencias transitivas o configuraciones futuras los instalen.
  -- ==========================================================================
  { "simrat39/rust-tools.nvim", enabled = false }, -- Obsoleto; reemplazado por mrcjkb/rustaceanvim
  { "rouge8/neotest-rust", enabled = false }, -- Redundante; se usa rustaceanvim.neotest integrado
  { "rust-lang/rust.vim", enabled = false }, -- Heredado; colisiona con Treesitter y Conform

  -- ==========================================================================
  -- Capa 2 de Blindaje: Cortocircuito total de rust_analyzer en lspconfig y Mason
  -- Garantiza que SOLO rustaceanvim inicie y administre rust-analyzer.
  -- ==========================================================================
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.rust_analyzer = { enabled = false }

      opts.setup = opts.setup or {}
      opts.setup.rust_analyzer = function()
        return true
      end

      pcall(function()
        if vim.lsp and type(vim.lsp.enable) == "function" then
          vim.lsp.enable("rust_analyzer", false)
        end
      end)
    end,
  },

  {
    "mason-org/mason-lspconfig.nvim",
    optional = true,
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        opts.ensure_installed = vim.tbl_filter(function(srv)
          return srv ~= "rust_analyzer" and srv ~= "rust-analyzer"
        end, opts.ensure_installed)
      end

      if type(opts.automatic_enable) == "table" then
        if type(opts.automatic_enable.exclude) == "table" then
          if not vim.tbl_contains(opts.automatic_enable.exclude, "rust_analyzer") then
            table.insert(opts.automatic_enable.exclude, "rust_analyzer")
          end
        end
      elseif opts.automatic_enable == nil or opts.automatic_enable == true then
        opts.automatic_enable = { exclude = { "rust_analyzer" } }
      end
    end,
  },

  -- ==========================================================================
  -- Herramientas en Mason: instalar codelldb + taplo y purgar rust-analyzer
  -- ==========================================================================
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      for _, pkg in ipairs({ "codelldb", "taplo" }) do
        if not vim.tbl_contains(opts.ensure_installed, pkg) then
          table.insert(opts.ensure_installed, pkg)
        end
      end

      opts.ensure_installed = vim.tbl_filter(function(pkg)
        return pkg ~= "rust-analyzer" and pkg ~= "rust_analyzer"
      end, opts.ensure_installed)
    end,
  },

  -- ==========================================================================
  -- Gramáticas Treesitter para código Rust, archivos RON y manifiestos TOML
  -- ==========================================================================
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "ron",
        "rust",
        "toml",
      },
    },
  },

  -- ==========================================================================
  -- Registro de grupo <leader>R en Which-Key
  -- ==========================================================================
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>R", group = "Rust / Cargo", icon = "🦀", mode = { "n", "v" } },
      },
    },
  },

  -- ==========================================================================
  -- Núcleo Rust: mrcjkb/rustaceanvim (LSP, Clippy, Proc-Macros, Inlay Hints y DAP)
  -- ==========================================================================
  {
    "mrcjkb/rustaceanvim",
    ft = { "rust" },
    opts = function(_, opts)
      install_codelldb_eof_fix()
      opts = opts or {}
      opts.server = opts.server or {}
      opts.server.cmd = resolve_rust_analyzer_cmd

      local prev_on_attach = opts.server.on_attach
      opts.server.on_attach = function(client, bufnr)
        if prev_on_attach then
          prev_on_attach(client, bufnr)
        end
        check_mason_shadow_binary()
        register_rust_keymaps(bufnr)
      end

      opts.server.default_settings = opts.server.default_settings or {}
      local ra = vim.tbl_deep_extend("force", opts.server.default_settings["rust-analyzer"] or {}, {
        cargo = {
          allFeatures = true,
          loadOutDirsFromCheck = true,
          buildScripts = {
            enable = true,
          },
          -- Directorio aislado `target/rust-analyzer` para no bloquear `cargo run/test`
          targetDir = true,
        },
        checkOnSave = true,
        check = {
          command = "clippy",
          extraArgs = { "--no-deps" },
        },
        diagnostics = {
          enable = true,
          experimental = {
            enable = true,
          },
        },
        procMacro = {
          enable = true,
        },
        files = {
          excludeDirs = {
            ".direnv",
            ".git",
            ".github",
            ".gitlab",
            "bin",
            "node_modules",
            "target",
            "venv",
            ".venv",
          },
        },
        inlayHints = {
          bindingModeHints = { enable = false },
          chainingHints = { enable = true },
          closingBraceHints = { enable = true, minLines = 25 },
          closureReturnTypeHints = { enable = "with_block" },
          lifetimeElisionHints = { enable = "never", useParameterNames = true },
          maxLength = 25,
          parameterHints = { enable = true },
          reborrowHints = { enable = "never" },
          renderColons = true,
          typeHints = {
            enable = true,
            hideClosureInitialization = false,
            hideNamedConstructor = false,
          },
        },
      })
      -- Limpiar cualquier lista heredada de proc-macros ignorados (ej. async-trait en Rust moderno)
      ra.procMacro.ignored = {}
      opts.server.default_settings["rust-analyzer"] = ra

      local codelldb_path, liblldb_path = resolve_codelldb_paths()
      if codelldb_path and liblldb_path then
        local ok_cfg, rustacean_cfg = pcall(require, "rustaceanvim.config")
        if ok_cfg then
          opts.dap = {
            adapter = rustacean_cfg.get_codelldb_adapter(codelldb_path, liblldb_path),
          }
        end
      end

      return opts
    end,
  },

  -- ==========================================================================
  -- Gestión inteligente de dependencias en Cargo.toml: Saecki/crates.nvim
  -- ==========================================================================
  {
    "Saecki/crates.nvim",
    event = { "BufRead Cargo.toml" },
    opts = {
      completion = {
        crates = {
          enabled = true,
        },
      },
      lsp = {
        enabled = true,
        on_attach = function(_, bufnr)
          register_crates_keymaps(bufnr)
        end,
        actions = true,
        completion = true,
        hover = true,
      },
      popup = {
        autofocus = true,
        hide_on_select = true,
        border = "rounded",
      },
    },
  },

  -- ==========================================================================
  -- Formateo de código Rust con rustfmt del toolchain activo (Conform)
  -- ==========================================================================
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        rust = { "rustfmt", lsp_format = "fallback" },
      },
    },
  },

  -- ==========================================================================
  -- Testing con Neotest usando el adaptador oficial integrado en rustaceanvim
  -- ==========================================================================
  {
    "nvim-neotest/neotest",
    optional = true,
    opts = function(_, opts)
      opts.adapters = opts.adapters or {}
      opts.adapters["rustaceanvim.neotest"] = opts.adapters["rustaceanvim.neotest"] or {}
      opts.adapters["neotest-rust"] = nil
    end,
  },

  -- ==========================================================================
  -- Generación de comentarios de documentación en formato rustdoc (`///`)
  -- ==========================================================================
  {
    "danymat/neogen",
    optional = true,
    opts = {
      languages = {
        rust = {
          template = {
            annotation_convention = "rustdoc",
          },
        },
      },
    },
  },
}
