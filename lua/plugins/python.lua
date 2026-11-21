---@module "plugins.python"
--- Configuración profesional del ecosistema Python (Backend, APIs y Scripting):
--- LSP (basedpyright + ruff), formateo (Conform), linting condicional (mypy),
--- depuración (nvim-dap-python + debugpy), testing (neotest-python + pytest) y docstrings (neogen).

local uv = vim.uv or vim.loop

--- Resuelve la ruta del adaptador debugpy gestionado por Mason o disponible en PATH
---@return string
local function resolve_debugpy_adapter()
  local in_path = vim.fn.exepath("debugpy-adapter")
  if in_path ~= "" then
    return in_path
  end

  local mason_path = vim.fn.stdpath("data") .. "/mason"
  local candidates = {
    mason_path .. "/bin/debugpy-adapter",
    mason_path .. "/packages/debugpy/venv/bin/python",
  }

  for _, path in ipairs(candidates) do
    if uv.fs_stat(path) then
      return path
    end
  end

  return "debugpy-adapter"
end

--- Resuelve el binario de mypy dentro del entorno virtual activo o del proyecto
---@param start_dir string|nil
---@return string|nil
local function resolve_project_mypy(start_dir)
  if vim.env.VIRTUAL_ENV and vim.env.VIRTUAL_ENV ~= "" then
    local env_mypy = vim.env.VIRTUAL_ENV .. "/bin/mypy"
    if uv.fs_stat(env_mypy) then
      return env_mypy
    end
  end

  if not start_dir or start_dir == "" then
    return nil
  end

  local venv = vim.fs.find({ ".venv", "venv" }, { path = start_dir, upward = true, type = "directory" })[1]
  if venv then
    local venv_mypy = venv .. "/bin/mypy"
    if uv.fs_stat(venv_mypy) then
      return venv_mypy
    end
  end

  return nil
end

--- Comprueba si el proyecto cuenta con configuración explícita de mypy
---@param start_dir string|nil
---@return boolean
local function has_mypy_config(start_dir)
  if not start_dir or start_dir == "" then
    return false
  end

  if vim.fs.find({ "mypy.ini", ".mypy.ini" }, { path = start_dir, upward = true })[1] then
    return true
  end

  local pyproject = vim.fs.find({ "pyproject.toml" }, { path = start_dir, upward = true })[1]
  if pyproject then
    local ok, lines = pcall(vim.fn.readfile, pyproject)
    if ok then
      for _, line in ipairs(lines) do
        if line:match("^%s*%[tool%.mypy") then
          return true
        end
      end
    end
  end

  return false
end

return {
  -- Garantizar instalación de herramientas Python/TOML vía Mason
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "basedpyright",
        "debugpy",
        "ruff",
        "taplo",
      },
    },
  },

  -- Configuración fina de LSP: basedpyright (tipos/hover/inlay hints) + ruff (lint/actions)
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        basedpyright = {
          settings = {
            basedpyright = {
              -- Delegar la organización de imports a Ruff para evitar duplicidad
              disableOrganizeImports = true,
              analysis = {
                autoSearchPaths = true,
                autoImportCompletions = true,
                diagnosticMode = "openFilesOnly",
                typeCheckingMode = "standard",
                inlayHints = {
                  variableTypes = true,
                  callArgumentNames = true,
                  functionReturnTypes = true,
                  genericTypes = false,
                },
              },
            },
          },
        },
        ruff = {
          init_options = {
            settings = {
              logLevel = "error",
              organizeImports = true,
              fixAll = true,
              lint = {
                enable = true,
              },
            },
          },
        },
      },
    },
  },

  -- Formateo y ordenamiento de imports al guardar con Ruff (Conform)
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        python = { "ruff_organize_imports", "ruff_format" },
      },
    },
  },

  -- Linting condicional con mypy del .venv del proyecto (solo si el proyecto usa mypy)
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        python = { "mypy" },
      },
      linters = {
        mypy = {
          cmd = function()
            local dir = vim.fn.expand("%:p:h")
            return resolve_project_mypy(dir) or "mypy"
          end,
          condition = function(ctx)
            if not resolve_project_mypy(ctx.dirname) then
              return false
            end
            return has_mypy_config(ctx.dirname)
          end,
        },
      },
    },
  },

  -- Depuración Python (DAP) con resolución defensiva de debugpy y pytest por defecto
  {
    "mfussenegger/nvim-dap-python",
    optional = true,
    config = function()
      local dap_python = require("dap-python")
      dap_python.setup(resolve_debugpy_adapter())
      dap_python.test_runner = "pytest"
    end,
  },

  -- Ejecución y depuración de tests con Neotest + pytest
  {
    "nvim-neotest/neotest",
    optional = true,
    opts = {
      adapters = {
        ["neotest-python"] = {
          dap = { justMyCode = false },
          args = { "-vv", "--tb=short" },
          runner = "pytest",
        },
      },
    },
  },

  -- Generación de docstrings Python en formato Google (Neogen)
  {
    "danymat/neogen",
    optional = true,
    opts = {
      languages = {
        python = {
          template = {
            annotation_convention = "google",
          },
        },
      },
    },
  },
}
