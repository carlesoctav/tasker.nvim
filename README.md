# Bufstash.nvim

![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua)

A Neovim plugin for stash-based file buffer navigation. Similar to Harpoon, but organized around stashes where each stash maintains its own set of file buffers.

## Features

- **Stash-based organization**: Create stashes and organize file buffers within each stash
- **Per-directory storage**: Each working directory maintains its own set of stashes
- **Interactive UI**: Floating windows for stash and buffer management with intuitive keybindings
- **Quick navigation**: Rapidly switch between buffered files within a stash
- **Buffer management**: Pin all open buffers to a stash or open all buffers at once

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "your-username/bufstash.nvim",
  config = function()
    require("bufstash").setup({
      save_on_toggle = true,
      save_on_change = true,
      excluded_filetypes = { "harpoon", "alpha", "dashboard", "neo-tree" },
    })
  end,
}
```

## Usage

### Commands

| Command | Description |
|---------|-------------|
| `:BufstashCreateStash <name>` | Create a new stash |
| `:BufstashSelectStash <name>` | Select an existing stash |
| `:BufstashDeleteStash <name>` | Delete a stash |
| `:BufstashToggleStashList` | Show/hide stash list |
| `:BufstashAddBuf <file_path>` | Add a file buffer to current stash |
| `:BufstashAddBufCurrBuf` | Add current buffer to current stash |
| `:BufstashSelectBuf <id>` | Open buffer by index |
| `:BufstashDeleteBuf <id>` | Delete buffer by index |
| `:BufstashToggleBufList` | Show/hide buffer list |
| `:BufstashPinCurrentState` | Add all open buffers to current stash |
| `:BufstashSelectAllBuf` | Open all buffers in current stash |

### Interactive Lists

#### Stash List (`BufstashToggleStashList`)
- `Enter`: Select stash
- `%`: Create new stash (prompts for name)
- `D`: Delete stash
- `q`/`Esc`: Close

#### Buffer List (`BufstashToggleBufList`)
- `Enter`: Open buffer
- `D`: Delete buffer
- `q`/`Esc`: Close

### Workflow Example

```lua
-- Create a new stash
:BufstashCreateStash feature-auth

-- Add current buffer to the stash
:BufstashAddBufCurrBuf

-- Add specific files
:BufstashAddBuf src/auth.lua
:BufstashAddBuf tests/auth_spec.lua

-- View and navigate buffers
:BufstashToggleBufList

-- Switch to another stash
:BufstashCreateStash bugfix-login
:BufstashSelectStash bugfix-login

-- Pin all currently open buffers
:BufstashPinCurrentState
```

## Configuration

```lua
require("bufstash").setup({
  -- Save buffers when toggling lists
  save_on_toggle = true,
  
  -- Save buffers when changing stashes
  save_on_change = true,
  
  -- Filetypes to exclude from buffering
  excluded_filetypes = { "harpoon", "alpha", "dashboard", "neo-tree" },
})
```

## API

The plugin exposes a Lua API for programmatic access:

```lua
local bufstash = require("bufstash")

-- Stash management
bufstash.create_stash("my-stash")
bufstash.select_stash("my-stash")
bufstash.delete_stash("my-stash")

-- Buffer management
bufstash.add_buf("/path/to/file.lua")
bufstash.add_buf_curr_buf()
bufstash.select_buf(1)
bufstash.delete_buf(1)

-- Utility functions
bufstash.pin_current_state()
bufstash.select_all_buf()

-- UI
bufstash.toggle_stash_list()
bufstash.toggle_buf_list()
```
$ gh repo create my-plugin -p ellisonleao/nvim-plugin-template
```

Via github web page:

Click on `Use this template`

![](https://docs.github.com/assets/cb-36544/images/help/repository/use-this-template-button.png)

## Features and structure

- 100% Lua
- Github actions for:
  - running tests using [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) and [busted](https://olivinelabs.com/busted/)
  - check for formatting errors (Stylua)
  - vimdocs autogeneration from README.md file
  - luarocks release (LUAROCKS_API_KEY secret configuration required)

### Plugin structure

```
.
├── lua
│   ├── plugin_name
│   │   └── module.lua
│   └── plugin_name.lua
├── Makefile
├── plugin
│   └── plugin_name.lua
├── README.md
├── tests
│   ├── minimal_init.lua
│   └── plugin_name
│       └── plugin_name_spec.lua
```
