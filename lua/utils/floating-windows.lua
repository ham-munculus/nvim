local M = {}

function M.create_floating_window(width, height)
  width = width or math.floor(vim.o.columns * 0.9)
  height = height or math.floor(vim.o.lines * 0.6)
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)

  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
  })

  return { buf = buf, win = win }
end

M.floating_state = { buf = -1, win = -1 }
M.bottom_state = { buf = -1, win = -1 }

function M.toggle_floating_terminal()
  if vim.api.nvim_win_is_valid(M.floating_state.win) then
    vim.api.nvim_win_hide(M.floating_state.win)
  else
    M.floating_state = M.create_floating_window()
    if vim.bo[M.floating_state.buf].buftype ~= "terminal" then
      vim.cmd.term()
    end
  end
end

function M.toggle_bottom_terminal()
  if vim.api.nvim_win_is_valid(M.bottom_state.win) then
    vim.api.nvim_win_hide(M.bottom_state.win)
    M.bottom_state.win = -1
    return
  end

  local height = math.floor(vim.o.lines * 0.3)
  M.bottom_state.buf = vim.api.nvim_buf_is_valid(M.bottom_state.buf) and M.bottom_state.buf
    or vim.api.nvim_create_buf(false, true)
  M.bottom_state.win = vim.api.nvim_open_win(M.bottom_state.buf, true, {
    relative = "editor",
    width = vim.o.columns,
    height = height,
    row = vim.o.lines - height - 2,
    col = 0,
    style = "minimal",
    border = { "", "═", "", "", "", "", "", "" },
  })

  if vim.bo[M.bottom_state.buf].buftype ~= "terminal" then
    vim.cmd("terminal")
  end
  vim.cmd("startinsert")
end

function M.show_messages()
  local output = vim.fn.execute("messages")
  local lines = vim.split(output, "\n", { plain = true })
  lines = #lines > 0 and lines or { "" }

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_call(buf, function()
    vim.opt_local.bufhidden = "wipe"
    vim.opt_local.buftype = "nofile"
    vim.opt_local.swapfile = false
  end)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local ui = vim.api.nvim_list_uis()[1]
  local max_len = 0
  for _, l in ipairs(lines) do
    max_len = math.max(max_len, #l)
  end

  local width = math.max(1, math.min(max_len, ui.width - 4))
  local height = math.max(1, math.min(#lines, ui.height / 2))
  local row = math.floor((ui.height - height) / 2)
  local col = math.floor((ui.width - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
  })

  vim.api.nvim_win_call(win, function()
    vim.wo.wrap = false
  end)

  vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf, silent = true })
end

return M
