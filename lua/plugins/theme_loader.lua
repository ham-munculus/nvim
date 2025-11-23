-- lua/plugins/theme_loader.lua

local M = {}

local function extract_colorscheme(spec)
  if type(spec) ~= "table" then
    return nil
  end

  for _, entry in ipairs(spec) do
    if type(entry) == "table" then
      -- Case 1: LazyVim spec with opts.colorscheme
      if
        entry[1] == "LazyVim/LazyVim"
        and type(entry.opts) == "table"
        and type(entry.opts.colorscheme) == "string"
      then
        return entry.opts.colorscheme
      end

      -- Case 2: theme plugin spec with explicit name
      -- { "everviolet/nvim", name = "evergarden", ... }
      if type(entry[1]) == "string" and type(entry.name) == "string" then
        return entry.name
      end
    end
  end

  return nil
end

function M.setup()
  local ok, spec = pcall(require, "plugins.theme")
  if not ok then
    vim.notify(
      "Omarchy theme spec (plugins.theme) not found: " .. tostring(spec),
      vim.log.levels.WARN
    )
    return
  end

  local colorscheme = extract_colorscheme(spec)
  if not colorscheme then
    vim.notify(
      "Could not infer colorscheme from Omarchy theme spec.",
      vim.log.levels.WARN
    )
    return
  end

  -- Debug: uncomment if needed
  -- print("Theme loader applying colorscheme:", colorscheme)

  local ok_cs, err = pcall(vim.cmd.colorscheme, colorscheme)
  if not ok_cs then
    vim.notify(
      ("Error loading colorscheme '%s': %s"):format(
        colorscheme,
        tostring(err)
      ),
      vim.log.levels.ERROR
    )
  end
end

return M
