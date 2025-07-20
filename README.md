# Tasker.nvim

![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua)

A Neovim plugin for task-based file marking and navigation. Similar to Harpoon, but organized around tasks where each task maintains its own set of file marks.

## Features

- **Task-based organization**: Create tasks and organize file marks within each task
- **Per-directory storage**: Each working directory maintains its own set of tasks
- **Interactive UI**: Floating windows for task and mark management with intuitive keybindings
- **Quick navigation**: Rapidly switch between marked files within a task
- **Buffer management**: Pin all open buffers to a task or open all marks at once

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "your-username/tasker.nvim",
  config = function()
    require("tasker").setup({
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
| `:TaskerCreateTask <name>` | Create a new task |
| `:TaskerSelectTask <name>` | Select an existing task |
| `:TaskerDeleteTask <name>` | Delete a task |
| `:TaskerToggleTaskList` | Show/hide task list |
| `:TaskerAddMark <file_path>` | Add a file mark to current task |
| `:TaskerAddMarkCurrBuf` | Add current buffer to current task |
| `:TaskerSelectMark <id>` | Open mark by index |
| `:TaskerDeleteMark <id>` | Delete mark by index |
| `:TaskerToggleMarkList` | Show/hide mark list |
| `:TaskerPinCurrentState` | Add all open buffers to current task |
| `:TaskerSelectAllMark` | Open all marks in current task |

### Interactive Lists

#### Task List (`TaskerToggleTaskList`)
- `Enter`: Select task
- `%`: Create new task (prompts for name)
- `D`: Delete task
- `q`/`Esc`: Close

#### Mark List (`TaskerToggleMarkList`)
- `Enter`: Open mark
- `D`: Delete mark
- `q`/`Esc`: Close

### Workflow Example

```lua
-- Create a new task
:TaskerCreateTask feature-auth

-- Add current buffer to the task
:TaskerAddMarkCurrBuf

-- Add specific files
:TaskerAddMark src/auth.lua
:TaskerAddMark tests/auth_spec.lua

-- View and navigate marks
:TaskerToggleMarkList

-- Switch to another task
:TaskerCreateTask bugfix-login
:TaskerSelectTask bugfix-login

-- Pin all currently open buffers
:TaskerPinCurrentState
```

## Configuration

```lua
require("tasker").setup({
  -- Save marks when toggling lists
  save_on_toggle = true,
  
  -- Save marks when changing tasks
  save_on_change = true,
  
  -- Filetypes to exclude from marking
  excluded_filetypes = { "harpoon", "alpha", "dashboard", "neo-tree" },
})
```

## API

The plugin exposes a Lua API for programmatic access:

```lua
local tasker = require("tasker")

-- Task management
tasker.create_task("my-task")
tasker.select_task("my-task")
tasker.delete_task("my-task")

-- Mark management
tasker.add_mark("/path/to/file.lua")
tasker.add_mark_curr_buf()
tasker.select_mark(1)
tasker.delete_mark(1)

-- Utility functions
tasker.pin_current_state()
tasker.select_all_mark()

-- UI
tasker.toggle_task_list()
tasker.toggle_mark_list()
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
