-- Python cells (`# %%`) run in a persistent Jupyter kernel with inline output.
--
-- Backend:  molten-nvim (kernel client/manager + inline virtual-text output).
-- This file: cell detection, per-project kernelspec (project interpreter), keymaps.
-- Kernelspecs are written to stdpath("state")/jupyter/kernels (via JUPYTER_DATA_DIR),
-- never to the project or the global Jupyter dirs.
--
-- Two different Pythons are involved:
--   * Neovim's provider venv (pynvim + jupyter_client) -> runs Molten itself.
--   * The project's interpreter (utils.python)          -> runs YOUR code, via ipykernel.
-- Setup of the provider venv:
--   uv venv ~/.local/share/nvim/pynvim-venv
--   uv pip install --python ~/.local/share/nvim/pynvim-venv/bin/python pynvim jupyter_client
--   then run :UpdateRemotePlugins once and restart nvim.
local pyenv = require("utils.python")

-- Private Jupyter data dir: kernelspecs + runtime connection files live here, not in
-- ~/.local/share/jupyter or the project. (Molten expects runtime/ to exist.)
local jupyter_dir = vim.fn.stdpath("state") .. "/jupyter"
vim.fn.mkdir(jupyter_dir .. "/runtime", "p")
vim.fn.mkdir(jupyter_dir .. "/kernels", "p")
vim.env.JUPYTER_DATA_DIR = jupyter_dir

local provider = vim.fn.stdpath("data") .. "/pynvim-venv/bin/python"
if vim.fn.executable(provider) == 1 then
	vim.g.python3_host_prog = provider
end

vim.g.molten_auto_init_behavior = "raise" -- never prompt for a kernel; we init explicitly
vim.g.molten_virt_text_output = true -- inline output under the cell
vim.g.molten_virt_lines_off_by_1 = false
vim.g.molten_auto_open_output = false
vim.g.molten_wrap_output = true
vim.g.molten_virt_text_max_lines = 20
vim.g.molten_output_win_max_height = 20
vim.g.molten_image_provider = "none" -- plots/images: see notes in the summary
vim.g.molten_use_border_highlights = true
vim.g.molten_cover_empty_lines = false

vim.api.nvim_create_autocmd("PackChanged", {
	desc = "Re-register molten remote plugin",
	callback = function(ev)
		if ev.data.spec.name == "molten-nvim" and ev.data.kind ~= "delete" then
			if not ev.data.active then
				vim.cmd.packadd("molten-nvim")
			end
			vim.cmd("silent! UpdateRemotePlugins")
		end
	end,
})

local M = {}

local SEP = "^#%s*%%%%" -- `# %%` and `#%%`, optional title after
local ipykernel_ok = {} -- python -> true
local ready = {} -- kernel name -> true once MoltenKernelReady fired
local waiting = {} -- "name\0buf" -> callbacks queued while the kernel starts

local function notify(msg, level)
	vim.notify(msg, level or vim.log.levels.INFO, { title = "Python cells" })
end

---------------------------------------------------------------------------
-- Cells
---------------------------------------------------------------------------

--- Cell around `lnum` (1-based) as first, last (body lines, separator excluded).
--- Code before the first separator is its own cell; no separators = whole file.
function M.cell_range(buf, lnum)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local first = 1
	for i = lnum, 1, -1 do
		if lines[i]:match(SEP) then
			first = i + 1
			break
		end
	end
	local last = #lines
	for i = lnum + (lines[lnum]:match(SEP) and 1 or 0), #lines do
		if lines[i]:match(SEP) then
			last = i - 1
			break
		end
	end
	return first, last, lines
end

local function jump(dir)
	local cur = vim.api.nvim_win_get_cursor(0)[1]
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	for i = cur + dir, dir > 0 and #lines or 1, dir do
		if lines[i]:match(SEP) then
			vim.api.nvim_win_set_cursor(0, { i, 0 })
			return true
		end
	end
	return false
end

---------------------------------------------------------------------------
-- Kernel lifecycle
---------------------------------------------------------------------------

local function project(buf)
	local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(buf))
	local root = pyenv.root(dir)
	local python, source = pyenv.resolve(dir)
	return root, python, source
end

local function kernel_name(root, python)
	return "cells-" .. vim.fn.sha256(root .. "\0" .. python):sub(1, 12)
end

--- Write (idempotently) a kernelspec that runs ipykernel with `python`, cwd = project root.
local function write_kernelspec(name, root, python)
	local dir = ("%s/kernels/%s"):format(jupyter_dir, name)
	vim.fn.mkdir(dir, "p")
	local boot = "import os,sys;os.chdir(sys.argv[1]);sys.argv=sys.argv[1:];"
		.. "from ipykernel import kernelapp;kernelapp.launch_new_instance()"
	local spec = {
		argv = { python, "-c", boot, root, "-f", "{connection_file}" },
		display_name = "Python (" .. root .. ")",
		language = "python",
	}
	vim.fn.writefile({ vim.json.encode(spec) }, dir .. "/kernel.json")
end

local function check_ipykernel(python, cb)
	if ipykernel_ok[python] then
		return cb(true)
	end
	vim.system({ python, "-c", "import ipykernel" }, {}, function(res)
		vim.schedule(function()
			if res.code == 0 then
				ipykernel_ok[python] = true
				cb(true)
			else
				notify(
					("ipykernel is not installed in %s.\nInstall it into that environment (this config never does it for you):\n  uv add --dev ipykernel     # uv project\n  uv pip install ipykernel   # or plain venv"):format(
						python
					),
					vim.log.levels.ERROR
				)
				cb(false)
			end
		end)
	end)
end

local function molten_ready()
	if vim.fn.exists(":MoltenInit") == 2 then
		return true
	end
	notify(
		"Molten is not registered. Make sure the provider venv exists (see lua/plugins/molten.lua header), "
			.. "then run :UpdateRemotePlugins and restart Neovim.",
		vim.log.levels.ERROR
	)
	return false
end

--- Run cb() once the kernel `name` reports ready (evaluating earlier misplaces output in Molten).
local function when_ready(name, cb)
	if ready[name] then
		return cb()
	end
	local done = false
	local id
	id = vim.api.nvim_create_autocmd("User", {
		pattern = "MoltenKernelReady",
		callback = function(ev)
			if ev.data and ev.data.kernel_id == name then
				done = true
				ready[name] = true
				vim.schedule(cb)
				return true
			end
		end,
	})
	vim.defer_fn(function()
		if not done then
			pcall(vim.api.nvim_del_autocmd, id)
			notify("Kernel did not become ready within 20s", vim.log.levels.ERROR)
		end
	end, 20000)
end

--- Attach `buf` to its project's kernel (starting it if needed), then call cb().
function M.ensure(buf, cb)
	if not molten_ready() then
		return
	end
	local root, python, source = project(buf)
	if not python then
		return notify("No Python environment: " .. source, vim.log.levels.ERROR)
	end
	local name = kernel_name(root, python)

	if vim.b[buf].cells_kernel == name then
		return when_ready(name, cb)
	end

	local key = name .. "\0" .. buf
	if waiting[key] then
		return table.insert(waiting[key], cb)
	end
	waiting[key] = { cb }

	check_ipykernel(python, function(ok)
		local cbs = waiting[key]
		waiting[key] = nil
		if not ok or not vim.api.nvim_buf_is_valid(buf) then
			return
		end
		write_kernelspec(name, root, python)
		vim.api.nvim_buf_call(buf, function()
			if vim.b[buf].cells_kernel then -- interpreter changed: drop the old kernel
				pcall(vim.cmd, "MoltenDeinit")
			end
			if ready[name] then
				vim.cmd("MoltenInit shared " .. name) -- second buffer of the same project
			else
				notify(("Starting kernel: %s (%s)"):format(python, source))
				vim.cmd("MoltenInit " .. name)
			end
		end)
		vim.b[buf].cells_kernel = name
		for _, f in ipairs(cbs) do
			when_ready(name, f)
		end
	end)
end

local function current_kernel()
	local buf = vim.api.nvim_get_current_buf()
	local name = vim.b[buf].cells_kernel
	if not name then
		notify("No kernel attached to this buffer", vim.log.levels.WARN)
	end
	return name
end

function M.restart()
	local name = current_kernel()
	if not name then
		return
	end
	ready[name] = nil
	vim.cmd("MoltenRestart!") -- restarts the kernel (state cleared) and drops cell outputs
	when_ready(name, function()
		notify("Kernel restarted (state cleared)")
	end)
end

function M.interrupt()
	if current_kernel() then
		vim.cmd("MoltenInterrupt")
		notify("Interrupt sent")
	end
end

function M.shutdown()
	local name = current_kernel()
	if not name then
		return
	end
	pcall(vim.cmd, "MoltenDeinit")
	ready[name] = nil
	for _, b in ipairs(vim.api.nvim_list_bufs()) do
		if vim.b[b].cells_kernel == name then
			vim.b[b].cells_kernel = nil
		end
	end
	notify("Kernel stopped")
end

function M.info()
	local buf = vim.api.nvim_get_current_buf()
	local root, python, source = project(buf)
	local name = vim.b[buf].cells_kernel
	notify(table.concat({
		"Project root   : " .. root,
		"Project python : " .. (python and ("%s  [%s]"):format(python, source) or ("NONE — " .. source)),
		"Provider python: " .. (vim.g.python3_host_prog or "(unset: Molten cannot run)"),
		"Kernel         : " .. (name and (ready[name] and "running (" or "starting (") .. name .. ")" or "not started"),
	}, "\n"))
end

---------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------

function M.run_cell(advance)
	local buf = vim.api.nvim_get_current_buf()
	local cur = vim.api.nvim_win_get_cursor(0)[1]
	local first, last, lines = M.cell_range(buf, cur)
	if table.concat(vim.list_slice(lines, first, last), "\n"):match("^%s*$") then
		notify("Cell is empty", vim.log.levels.WARN)
	else
		M.ensure(buf, function()
			vim.fn.MoltenEvaluateRange(first, last)
		end)
	end
	if advance and not jump(1) then
		notify("Last cell")
	end
end

function M.run_visual()
	vim.cmd("normal! \27") -- leave visual mode so '< and '> are set; Molten reads them
	M.ensure(vim.api.nvim_get_current_buf(), function()
		vim.cmd("MoltenEvaluateVisual")
	end)
end

function M.clear()
	pcall(vim.cmd, "MoltenDelete!")
	pcall(vim.cmd, "MoltenHideOutput")
end

---------------------------------------------------------------------------
-- Commands & keymaps (python buffers only)
---------------------------------------------------------------------------

vim.api.nvim_create_user_command("PythonEnv", function(opts)
	if opts.args ~= "" then
		pyenv.override = opts.args ~= "auto" and vim.fn.expand(opts.args) or nil
	end
	M.info()
end, {
	nargs = "?",
	complete = "file",
	desc = "Show project python/kernel; `:PythonEnv <python>` overrides, `:PythonEnv auto` resets",
})
vim.api.nvim_create_user_command("KernelRestart", M.restart, { desc = "Restart Python kernel (clears state)" })
vim.api.nvim_create_user_command("KernelInterrupt", M.interrupt, { desc = "Interrupt running cell" })
vim.api.nvim_create_user_command("KernelStop", M.shutdown, { desc = "Stop Python kernel" })

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("PythonCells", { clear = true }),
	pattern = "python",
	callback = function(ev)
		local function map(mode, lhs, fn, desc)
			vim.keymap.set(mode, lhs, fn, { buffer = ev.buf, silent = true, desc = desc })
		end
		-- <leader>c: ca/cl/cs are taken (code action, cloak, trouble symbols)
		map("n", "<leader>cc", function() M.run_cell(false) end, "Cells: run current cell")
		map("n", "<C-S-CR>", function() M.run_cell(false) end, "Cells: run current cell") -- needs kitty/CSI-u keys in terminal
		map("n", "<leader>cn", function() M.run_cell(true) end, "Cells: run cell and advance")
		map("x", "<leader>cc", M.run_visual, "Cells: run selection")
		map("x", "<C-S-CR>", M.run_visual, "Cells: run selection")
		map("n", "<leader>cL", function() M.ensure(ev.buf, function() vim.cmd("MoltenEvaluateLine") end) end, "Cells: run line")
		map("n", "<leader>cr", M.restart, "Cells: restart kernel (clear state)")
		map("n", "<leader>ci", M.interrupt, "Cells: interrupt")
		map("n", "<leader>cd", M.clear, "Cells: dismiss/clear output")
		map("n", "<leader>co", "<cmd>noautocmd MoltenEnterOutput<CR>", "Cells: open/enter output window")
		map("n", "<leader>ce", M.info, "Cells: show environment / kernel")
		map("n", "<leader>cq", M.shutdown, "Cells: stop kernel")
		map("n", "]]", function() jump(1) end, "Next cell")
		map("n", "[[", function() jump(-1) end, "Previous cell")
	end,
})

return M
