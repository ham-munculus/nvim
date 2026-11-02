-- Project Python interpreter detection (used by LSP and the cell runner).
-- NOT the interpreter of Neovim's own Python provider (see plugins/molten.lua).
local M = {}

M.override = nil -- explicit interpreter path, set via :PythonEnv

local function exe(path)
	return path and vim.fn.executable(path) == 1
end

local function venv_python(dir)
	for _, rel in ipairs({ "/bin/python", "/Scripts/python.exe" }) do
		if exe(dir .. rel) then
			return dir .. rel
		end
	end
end

--- Resolve the project's interpreter for a directory.
--- Order: override > $VIRTUAL_ENV > nearest .venv upward > $CONDA_PREFIX.
--- Returns path, source  — or nil, reason. Never falls back to a global python.
function M.resolve(start)
	if M.override then
		if exe(M.override) then
			return M.override, "override"
		end
		return nil, "override is not executable: " .. M.override
	end

	local venv = vim.env.VIRTUAL_ENV
	if venv and venv ~= "" then
		local py = venv_python(venv)
		if py then
			return py, "$VIRTUAL_ENV"
		end
	end

	start = start or vim.fn.getcwd()
	local found = vim.fs.find(".venv", { path = start, upward = true, type = "directory" })[1]
	if found then
		local py = venv_python(found)
		if py then
			return py, ".venv"
		end
	end

	local conda = vim.env.CONDA_PREFIX
	if conda and conda ~= "" then
		local py = exe(conda .. "/bin/python") and conda .. "/bin/python" or nil
		if py then
			return py, "$CONDA_PREFIX"
		end
	end

	return nil, "no $VIRTUAL_ENV, .venv or $CONDA_PREFIX found (set one, or use :PythonEnv <python>)"
end

--- Project root: dir holding .venv / pyproject.toml / .git, else the file's dir.
function M.root(start)
	start = start or vim.fn.getcwd()
	local m = vim.fs.find({ ".venv", "pyproject.toml", ".git" }, { path = start, upward = true })[1]
	return m and vim.fs.dirname(m) or start
end

return M
