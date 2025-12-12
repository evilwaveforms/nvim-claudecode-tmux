if vim.g.loaded_nvim_claudecode_tmux then
  return
end
vim.g.loaded_nvim_claudecode_tmux = true

vim.api.nvim_create_user_command("ClaudeSend", function()
  require("nvim-claudecode-tmux").send()
end, { range = true, desc = "Send selection to Claude Code" })
