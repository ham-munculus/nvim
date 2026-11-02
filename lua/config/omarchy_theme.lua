-- Omarchy emits Lazy-style specs; translate their options for our vim.pack config.
local group = vim.api.nvim_create_augroup("OmarchyTheme", { clear = true })
local paths = {
	vim.fn.expand("~/.local/state/omarchy/current/theme/neovim.lua"),
	vim.fn.expand("~/.config/omarchy/current/theme/neovim.lua"),
}
local last_source
local transparent_groups = {
	"Normal", "NormalNC", "NormalFloat", "FloatBorder", "FloatTitle",
	"SignColumn", "LineNr", "CursorLineNr", "FoldColumn", "EndOfBuffer",
	"StatusLine", "StatusLineNC", "WinSeparator", "TabLine", "TabLineFill",
	"TabLineSel", "Pmenu", "PmenuSel", "PmenuSbar", "PmenuThumb",
	"WhichKeyFloat", "NotifyBackground", "LazyNormal", "MasonNormal",
}

local function apply_transparency()
	for _, name in ipairs(transparent_groups) do
		-- Preserve foregrounds, styles and resolved links.
		local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
		hl.bg = nil
		hl.ctermbg = nil
		vim.api.nvim_set_hl(0, name, hl)
	end
end

local function read_theme()
	for _, path in ipairs(paths) do
		if vim.fn.filereadable(path) == 1 then
			local source = table.concat(vim.fn.readfile(path), "\n")
			return source, path
		end
	end
end

local function apply_theme(force)
	local source, path = read_theme()
	if not force and source == last_source then
		return
	end
	-- Cache failed versions too, so a bad theme does not notify every second.
	last_source = source
	local ok, err = pcall(function()
		if not source then
			vim.cmd.colorscheme("tokyonight")
			return
		end
		local chunk, parse_error = loadstring(source, "@" .. path)
		assert(chunk, parse_error)
		local specs = chunk()
		if type(specs) == "string" then
			vim.cmd.colorscheme(specs)
			return
		end
		assert(type(specs) == "table", "Expected an Omarchy theme spec")
		local colorscheme
		for _, spec in ipairs(specs) do
			if type(spec) == "table" and spec.opts and spec.opts.colorscheme then
				colorscheme = spec.opts.colorscheme
			end
		end
		assert(type(colorscheme) == "string", "Theme has no colorscheme")
		-- Omarchy's Catppuccin spec uses a LazyVim alias, not a colors file.
		if colorscheme == "catppuccin-nvim" then
			colorscheme = "catppuccin"
		end
		vim.o.background = (colorscheme:match("light") or colorscheme:match("latte")
			or colorscheme:match("dawn")) and "light" or "dark"
		for _, spec in ipairs(specs) do
			if type(spec) == "table" and type(spec.opts) == "table"
				and spec[1] ~= "LazyVim/LazyVim" then
				local module = spec.main or spec.name or spec[1]:match("/([^/]+)$")
				module = module:gsub("%.git$", ""):gsub("%.nvim$", ""):gsub("%-nvim$", "")
				require(module).setup(vim.deepcopy(spec.opts))
			end
		end
		vim.cmd.colorscheme(colorscheme)
	end)
	if not ok then
		vim.notify("Omarchy theme: " .. tostring(err), vim.log.levels.WARN)
		if not vim.g.colors_name then
			vim.cmd.colorscheme("tokyonight")
		end
	end
	apply_transparency()
end

vim.api.nvim_create_user_command("OmarchyThemeReload", function()
	apply_theme(true)
end, { desc = "Reload the current Omarchy palette", force = true })
vim.api.nvim_create_autocmd("ColorScheme", {
	group = group,
	callback = apply_transparency,
})
vim.api.nvim_create_autocmd("FocusGained", {
	group = group,
	callback = function() apply_theme(false) end,
})
-- Poll the file contents: Omarchy replaces the whole theme directory atomically,
-- which invalidates a watcher attached directly to the old file/directory.
if _G.omarchy_theme_timer then
	_G.omarchy_theme_timer:stop()
	_G.omarchy_theme_timer:close()
end
local timer = assert(vim.uv.new_timer())
_G.omarchy_theme_timer = timer
timer:start(1000, 1000, vim.schedule_wrap(function() apply_theme(false) end))
vim.api.nvim_create_autocmd("VimLeavePre", {
	group = group,
	callback = function()
		timer:stop()
		timer:close()
		_G.omarchy_theme_timer = nil
	end,
})
apply_theme(true)
