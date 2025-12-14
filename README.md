# nvim-claudecode-tmux

Send file references and text selections to Claude Code running in a tmux pane.

## Installation & Configuration

### lazy.nvim

Values inside `opts` are defaults. If you don't want to change them, `opts` can be `{}`.

```lua
{
    "evilwaveforms/nvim-claudecode-tmux",
    opts = {
        keymap_reference = "<leader>cl",
        keymap_selection = "<leader>cs",
        keymap_toggle = "<leader>cc",
        split_direction = "-h",
    },
},
```

## Keymaps

| Keymap | Mode | Description |
|--------|------|-------------|
| `<leader>cc` | Normal | Toggle the compose buffer window |
| `<leader>cl` | Visual | Add file reference (e.g., `@file.lua:10-20`) to compose buffer |
| `<leader>cs` | Visual | Add selected text to compose buffer |

## Usage

1. Select text in visual mode
2. Press `<leader>cl` to add a file reference or `<leader>cs` to add the selected text
3. A compose buffer opens at the bottom
4. Edit the content if needed
5. Save the buffer (`:w`) to send to Claude Code and submit

## fzf.vim Integration

Send relative file paths from fzf to the compose buffer:

```lua
vim.g.fzf_action = {
  ['ctrl-c'] = function(files)
    require('nvim-claudecode-tmux').add_files(files)
  end,
}
```

1. Open fzf (`Ctrl+P` or `:Files`)
2. Select files with `Tab`
3. Press `Ctrl+C` to add file references (e.g., `@src/main.lua`)
