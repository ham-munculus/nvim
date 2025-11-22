-- Detect a .venv starting from the current working directory.
-- If not found, fall back to a global python executable.
local function get_python_path()
  local cwd = vim.fn.getcwd()

  -- Project-local .venv
  local venv_paths = {
    cwd .. "/.venv/bin/python", -- POSIX
    cwd .. "/.venv/Scripts/python.exe", -- Windows
    cwd .. "/.venv/Scripts/python", -- some Windows setups
  }

  for _, path in ipairs(venv_paths) do
    if vim.fn.filereadable(path) == 1 then
      return path
    end
  end

  -- Optional: walk up to find a .venv in parent dirs
  local parent = cwd
  while true do
    local next_parent = vim.fn.fnamemodify(parent, ":h")
    if next_parent == parent then
      break
    end
    parent = next_parent
    local parent_venv_paths = {
      parent .. "/.venv/bin/python",
      parent .. "/.venv/Scripts/python.exe",
      parent .. "/.venv/Scripts/python",
    }
    for _, path in ipairs(parent_venv_paths) do
      if vim.fn.filereadable(path) == 1 then
        return path
      end
    end
  end

  -- Fallback: system python
  -- Adjust this if you prefer a specific one.
  if vim.fn.executable("python") == 1 then
    return "python"
  elseif vim.fn.executable("python3") == 1 then
    return "python3"
  end

  -- Last resort: nil (basedpyright will use its default)
  return nil
end

local python = get_python_path()

return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts = opts or {}
      opts.servers = opts.servers or {}

      -- Lua
      opts.servers.lua_ls = {
        settings = {
          Lua = {
            hint = {
              enable = false,
            },
          },
        },
      }

      -- basedpyright for type checking
      opts.servers.basedpyright = {
        settings = {
          python = {
            -- This will be the .venv Python if present, otherwise global
            pythonPath = python,
          },
          basedpyright = {
            disableOrganizeImports = true,
            analysis = {
              -- ignore = { "*" },
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              diagnosticMode = "openFilesOnly",
              typeCheckingMode = "basic",
              diagnosticSeverityOverrides = {
                reportOptionalMemberAccess = false, --warning
              },
              inlayHints = {
                variableTypes = false,
                functionReturnTypes = false,
                parameterTypes = false,
                callArgumentNames = false,
                genericTypes = false,
              },
            },
          },
        },
      }

      -- disable hover from ruff (only basedpyright)
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp_attach_disable_ruff_hover", { clear = true }),
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client == nil then
            return
          end
          if client.name == "ruff" then
            -- Disable hover in favor of basedpyright
            client.server_capabilities.hoverProvider = false
          end
        end,
        desc = "LSP: Disable hover capability from Ruff",
      })

      -- Ruff LSP for linting diagnostics
      opts.servers.ruff = {
        init_options = {
          settings = {
            lint = { enable = false },
            args = {
              "--line-length=88",
              "--select=E,F,I,B,UP,SIM,ARG",
            },
          },
        },
      }

      opts.servers.jsonls = opts.servers.jsonls or {}
      opts.servers.yamlls = opts.servers.yamlls or {}
      opts.servers.rust_analyzer = opts.servers.rust_analyzer or {}

      -- keep your “remove gr keymap” logic
      opts.servers["*"] = opts.servers["*"] or {}
      local keys = opts.servers["*"].keys or {}
      local filtered = {}
      for _, key in ipairs(keys) do
        if key[1] ~= "gr" then
          table.insert(filtered, key)
        end
      end
      opts.servers["*"].keys = filtered

      return opts
    end,
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "stylua",
        "ruff",
        "basedpyright",
      },
    },
  },
}
