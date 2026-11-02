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
vim.g.molten_enter_output_behavior = "open_and_enter" -- <leader>co opens AND focuses the float
vim.g.molten_wrap_output = true
vim.g.molten_virt_text_max_lines = 20
vim.g.molten_output_win_max_height = 20
vim.g.molten_image_provider = "none" -- plots/images: see notes in the summary
vim.g.molten_use_border_highlights = true
vim.g.molten_cover_empty_lines = false

-- Make REPL output look different from code/comments. Derived from the active colorscheme
-- and re-applied on :colorscheme. Molten paints each output line as one highlight chunk, so the
-- background covers the text only (ragged right edge), not the full window width.
local function hl_color(group, attr)
	local ok, h = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
	return ok and h[attr] or nil
end

local function blend(a, b, t) -- mix colour a toward b by t (0..1); ints 0xRRGGBB
	local function ch(c, sh) return bit.band(bit.rshift(c, sh), 0xff) end
	local function mix(sh) return math.floor(ch(a, sh) + (ch(b, sh) - ch(a, sh)) * t + 0.5) end
	return bit.lshift(mix(16), 16) + bit.lshift(mix(8), 8) + mix(0)
end

local function apply_output_hl()
	local fg = hl_color("Special", "fg") or hl_color("DiagnosticInfo", "fg")
	local base = hl_color("Normal", "bg") or hl_color("CursorLine", "bg")
	local bg = base and fg and blend(base, fg, 0.12) or hl_color("CursorLine", "bg")
	vim.api.nvim_set_hl(0, "MoltenVirtualText", { fg = fg, bg = bg, italic = false })
	vim.api.nvim_set_hl(0, "CellRule", { link = "FloatBorder" }) -- the ═ line above output
	vim.api.nvim_set_hl(0, "MoltenOutputWin", { link = "NormalFloat" })
	vim.api.nvim_set_hl(0, "MoltenOutputBorder", { link = "FloatBorder" })
	vim.api.nvim_set_hl(0, "MoltenOutputBorderSuccess", { link = "DiagnosticOk" })
	vim.api.nvim_set_hl(0, "MoltenOutputBorderFail", { link = "DiagnosticError" })
end
apply_output_hl()
vim.api.nvim_create_autocmd("ColorScheme", {
	group = vim.api.nvim_create_augroup("PythonCellsHl", { clear = true }),
	desc = "Re-derive REPL output colours",
	callback = apply_output_hl,
})

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
-- Rule lines above and below inline output (same ═ look as the <leader>tt bottom terminal)
---------------------------------------------------------------------------
-- A separate virt_lines extmark on the cell's last line. Stacking of virt_lines on one row is
-- NOT decided by id/creation order; left gravity (right_gravity=false) makes our mark sort before
-- Molten's (right-gravity) one deterministically (12/12 headless runs; right gravity was random).
-- Rules whose output Molten has dropped are pruned, so a stale rule can linger only briefly.

local rule_ns = vim.api.nvim_create_namespace("python-cells-rule") -- above the output
local rule_end_ns = vim.api.nvim_create_namespace("python-cells-rule-end") -- below the output

local function output_rows(buf)
	local rows = {}
	local ns = vim.api.nvim_get_namespaces()["molten-extmarks"]
	if ns then
		for _, m in ipairs(vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })) do
			if m[4].virt_lines and #m[4].virt_lines > 0 then
				rows[m[2]] = true
			end
		end
	end
	return rows
end

local function prune_rules(buf)
	if not vim.api.nvim_buf_is_valid(buf) then
		return
	end
	local rows = output_rows(buf)
	for _, m in ipairs(vim.api.nvim_buf_get_extmarks(buf, rule_ns, 0, -1, {})) do
		if not rows[m[2]] then
			vim.api.nvim_buf_del_extmark(buf, rule_ns, m[1])
		end
	end
	-- end rule sits on the NEXT line (drawn above it), or on the last line when the cell is at EOF
	local count = vim.api.nvim_buf_line_count(buf)
	for _, m in ipairs(vim.api.nvim_buf_get_extmarks(buf, rule_end_ns, 0, -1, {})) do
		local out_row = m[2] == count - 1 and rows[m[2]] and m[2] or m[2] - 1
		if not rows[out_row] then
			vim.api.nvim_buf_del_extmark(buf, rule_end_ns, m[1])
		end
	end
end

local function place_rule(buf, row1) -- row1: 1-based last line of the evaluated code
	local count = vim.api.nvim_buf_line_count(buf)
	local row = math.min(row1, count) - 1
	for _, ns in ipairs({ rule_ns, rule_end_ns }) do
		for _, r in ipairs({ row, row + 1 }) do
			for _, m in ipairs(vim.api.nvim_buf_get_extmarks(buf, ns, { r, 0 }, { r, -1 }, {})) do
				vim.api.nvim_buf_del_extmark(buf, ns, m[1])
			end
		end
	end
	local win = vim.fn.bufwinid(buf)
	local info = win ~= -1 and vim.fn.getwininfo(win)[1]
	local width = info and (info.width - info.textoff) or vim.o.columns
	local line = { { { string.rep("═", width), "CellRule" } } }
	-- Stacking of virt_lines on one row is NOT decided by id/creation order. Left gravity makes
	-- our top mark sort before Molten's (right-gravity) one (12/12 headless runs; right gravity
	-- was random). The end rule is drawn "above" the next line, i.e. after all virt_lines of
	-- the cell's last line; at EOF there is no next line, so it falls back to a mark below it.
	vim.api.nvim_buf_set_extmark(buf, rule_ns, row, 0, { virt_lines = line, right_gravity = false })
	if row + 1 < count then
		vim.api.nvim_buf_set_extmark(buf, rule_end_ns, row + 1, 0, { virt_lines = line, virt_lines_above = true })
	else
		vim.api.nvim_buf_set_extmark(buf, rule_end_ns, row, 0, { virt_lines = line, right_gravity = true })
	end
	vim.defer_fn(function()
		prune_rules(buf)
	end, 800)
end

local function clear_rules()
	vim.api.nvim_buf_clear_namespace(0, rule_ns, 0, -1)
	vim.api.nvim_buf_clear_namespace(0, rule_end_ns, 0, -1)
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
	clear_rules()
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
	clear_rules()
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
			place_rule(buf, last)
			vim.fn.MoltenEvaluateRange(first, last)
		end)
	end
	if advance and not jump(1) then
		notify("Last cell")
	end
end

function M.run_line()
	local buf = vim.api.nvim_get_current_buf()
	local row = vim.api.nvim_win_get_cursor(0)[1]
	M.ensure(buf, function()
		place_rule(buf, row)
		vim.cmd("MoltenEvaluateLine")
	end)
end

function M.run_visual()
	vim.cmd("normal! \27") -- leave visual mode so '< and '> are set; Molten reads them
	local buf = vim.api.nvim_get_current_buf()
	local last = vim.fn.line("'>")
	M.ensure(buf, function()
		place_rule(buf, last)
		vim.cmd("MoltenEvaluateVisual")
	end)
end

--- Run fn with the cursor on a body line of the current cell (Molten ignores separator lines).
local function at_cell(fn)
	local buf = vim.api.nvim_get_current_buf()
	local cur = vim.api.nvim_win_get_cursor(0)
	local first, last = M.cell_range(buf, cur[1])
	local moved = cur[1] < first or cur[1] > last
	if moved then
		vim.api.nvim_win_set_cursor(0, { math.min(first, vim.api.nvim_buf_line_count(buf)), 0 })
	end
	local ok, err = pcall(fn)
	if moved then
		vim.api.nvim_win_set_cursor(0, cur)
	end
	if not ok then
		notify(tostring(err), vim.log.levels.ERROR)
	end
end

--- Yank the output of the cell under the cursor (plain text, no header) to " or, with clip, "+.
function M.yank(clip)
	at_cell(function()
		vim.cmd(clip and "MoltenYankOutput!" or "MoltenYankOutput")
	end)
end

local output_buf -- single reusable scratch buffer

--- Open the full output of the current cell in a normal buffer in a vertical split on the right.
function M.open_output()
	local saved = vim.fn.getreginfo('"')
	vim.fn.setreg('"', "")
	at_cell(function()
		vim.cmd("MoltenYankOutput")
	end)
	local text = vim.fn.getreg('"')
	vim.fn.setreg('"', saved)
	if text == "" then
		return notify("No output for this cell", vim.log.levels.WARN)
	end

	if not (output_buf and vim.api.nvim_buf_is_valid(output_buf)) then
		output_buf = vim.api.nvim_create_buf(false, true)
		vim.bo[output_buf].buftype = "nofile"
		vim.bo[output_buf].bufhidden = "hide"
		vim.bo[output_buf].swapfile = false
		vim.bo[output_buf].filetype = "text"
		pcall(vim.api.nvim_buf_set_name, output_buf, "cell-output")
		vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = output_buf, silent = true, desc = "Close cell output" })
	end
	vim.bo[output_buf].modifiable = true
	vim.api.nvim_buf_set_lines(output_buf, 0, -1, false, vim.split(text, "\n", { plain = true }))

	local win = vim.fn.bufwinid(output_buf)
	if win == -1 then
		vim.cmd("botright vsplit")
		win = vim.api.nvim_get_current_win()
		vim.api.nvim_win_set_buf(win, output_buf)
		vim.wo[win].wrap = true
		vim.wo[win].number = false
		vim.wo[win].relativenumber = false
		vim.wo[win].signcolumn = "no"
	else
		vim.api.nvim_set_current_win(win)
	end
	vim.api.nvim_win_set_cursor(win, { 1, 0 })
end

--- Open Molten's output float and focus it (scroll/yank like any buffer; q leaves).
function M.enter_output()
	-- noautocmd: Molten's docs advise it (BufEnter/CursorMoved handlers fight the float)
	vim.cmd("noautocmd MoltenEnterOutput")
	local buf = vim.api.nvim_get_current_buf()
	if vim.bo[buf].filetype == "molten_output" then
		vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf, silent = true, desc = "Close cell output" })
	end
end

function M.clear()
	clear_rules()
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
		map("n", "<leader>cL", M.run_line, "Cells: run line")
		map("n", "<leader>cr", M.restart, "Cells: restart kernel (clear state)")
		map("n", "<leader>ci", M.interrupt, "Cells: interrupt")
		map("n", "<leader>cd", M.clear, "Cells: dismiss/clear output")
		map("n", "<leader>cy", function() M.yank(false) end, "Cells: yank cell output")
		map("n", "<leader>cY", function() M.yank(true) end, "Cells: yank cell output to system clipboard")
		map("n", "<leader>cO", M.open_output, "Cells: open full output in a split buffer (q closes)")
		map("n", "<leader>co", M.enter_output, "Cells: open output float and focus it (q leaves)")
		map("n", "<leader>ce", M.info, "Cells: show environment / kernel")
		map("n", "<leader>cq", M.shutdown, "Cells: stop kernel")
		map("n", "]]", function() jump(1) end, "Next cell")
		map("n", "[[", function() jump(-1) end, "Previous cell")
	end,
})

return M
