local M = {}

M.config = {
  keymap_reference = "<leader>cl",
  keymap_selection = "<leader>cs",
  split_direction = "-h",
}

local compose_buf = nil

local function find_claude_pane()
  local result = vim.fn.system("tmux list-panes -s -F '#{pane_id} #{pane_current_command}' 2>/dev/null")
  for line in result:gmatch("[^\r\n]+") do
    local id, cmd = line:match("(%%[%d]+)%s+(.+)")
    if id and cmd == "claude" then
      return id
    end
  end
  return nil
end

local function ensure_claude_pane()
  local pane_id = find_claude_pane()
  if pane_id then
    return pane_id
  end
  local result = vim.fn.system(string.format(
    "tmux split-window %s -P -F '#{pane_id}' 'claude'", M.config.split_direction))
  vim.fn.system("tmux last-pane")
  return result:gsub("%s+", "")
end

local function send_buffer_to_claude()
  if not compose_buf or not vim.api.nvim_buf_is_valid(compose_buf) then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(compose_buf, 0, -1, false)
  local content = table.concat(lines, "\n")

  if content:match("^%s*$") then
    vim.notify("Buffer is empty", vim.log.levels.WARN)
    return
  end

  local pane_id = ensure_claude_pane()
  vim.fn.system("tmux load-buffer -", content)
  vim.fn.system(string.format("tmux paste-buffer -t '%s'", pane_id))
  vim.fn.system(string.format("tmux send-keys -t '%s' Enter", pane_id))

  vim.api.nvim_buf_set_lines(compose_buf, 0, -1, false, {})
  vim.bo[compose_buf].modified = false
  vim.notify("Sent to Claude Code", vim.log.levels.INFO)
end

local function ensure_compose_buffer()
  if compose_buf and vim.api.nvim_buf_is_valid(compose_buf) then
    return
  end

  compose_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(compose_buf, "Claude Compose")
  vim.bo[compose_buf].buftype = "acwrite"

  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = compose_buf,
    callback = send_buffer_to_claude,
  })
end

local function open_compose_window()
  ensure_compose_buffer()

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == compose_buf then
      return
    end
  end

  vim.cmd("botright split")
  vim.api.nvim_win_set_buf(vim.api.nvim_get_current_win(), compose_buf)
  vim.api.nvim_win_set_height(0, 15)
end

local function append_to_compose(text)
  ensure_compose_buffer()
  local current_win = vim.api.nvim_get_current_win()

  local lines = vim.api.nvim_buf_get_lines(compose_buf, 0, -1, false)
  local new_lines = vim.split(text, "\n", { plain = true })

  if #lines == 1 and lines[1] == "" then
    lines = new_lines
  else
    table.insert(lines, "")
    vim.list_extend(lines, new_lines)
  end
  vim.api.nvim_buf_set_lines(compose_buf, 0, -1, false, lines)

  open_compose_window()
  vim.api.nvim_set_current_win(current_win)
end

local function add_file_reference()
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")
  local filename = vim.fn.expand("%:p")

  if filename == "" then
    vim.notify("No file open", vim.log.levels.ERROR)
    return
  end

  local relative_path = vim.fn.fnamemodify(filename, ":.")
  local text
  if start_line == end_line then
    text = string.format("@%s:%d", relative_path, start_line)
  else
    text = string.format("@%s:%d-%d", relative_path, start_line, end_line)
  end

  append_to_compose(text)
end

local function add_selection()
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")
  local lines = vim.fn.getline(start_line, end_line)

  if type(lines) == "string" then
    lines = { lines }
  end

  local text = table.concat(lines, "\n")
  append_to_compose(text)
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  vim.keymap.set("v", M.config.keymap_reference, ":<C-u>lua require('nvim-claudecode-tmux').add_reference()<CR>",
    { desc = "Add file reference to Claude compose buffer" })
  vim.keymap.set("v", M.config.keymap_selection, ":<C-u>lua require('nvim-claudecode-tmux').add_selection()<CR>",
    { desc = "Add selected text to Claude compose buffer" })
end

M.add_reference = add_file_reference
M.add_selection = add_selection

return M
