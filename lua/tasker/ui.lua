local core = require("tasker.core")
local utils = require("tasker.utils")
local data = require("tasker.data")

---@class TaskerUI
local M = {}

local task_buf = nil
local task_win = nil
local mark_buf = nil
local mark_win = nil

local function close_window(buf, win)
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
  if buf and vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
  end
end

local function create_floating_window(title, lines)
  local width = math.max(40, math.min(80, vim.o.columns - 4))
  local height = math.max(10, math.min(20, math.max(#lines, 8)))

  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local buf = vim.api.nvim_create_buf(false, true)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = title,
    title_pos = "center",
  })

  vim.api.nvim_buf_set_option(buf, "buftype", "acwrite")
  vim.api.nvim_win_set_option(win, "cursorline", true)
  vim.api.nvim_win_set_option(win, "number", true)

  return buf, win
end

local function parse_task_buffer()
  if not task_buf or not vim.api.nvim_buf_is_valid(task_buf) then
    return
  end
  local lines = vim.api.nvim_buf_get_lines(task_buf, 0, -1, false)
  local tasks = core.get_tasks()
  local current_task = core.get_current_task()
  local new_tasks = {}
  
  for _, line in ipairs(lines) do
    local trimmed = vim.trim(line)
    if trimmed ~= "" then
      local task_name = trimmed:gsub("^[* ] ", "")
      if tasks[task_name] then
        new_tasks[task_name] = tasks[task_name]
      elseif trimmed ~= "No tasks found" and not trimmed:match("^Press") and not trimmed:match("^Enter:") then
        new_tasks[task_name] = { marks = {} }
      end
    end
  end

  local cwd = vim.fn.getcwd()
  data.save_tasks(cwd, new_tasks)
end

local function select_task_from_cursor()
  if not task_buf or not task_win or not vim.api.nvim_win_is_valid(task_win) then
    return
  end

  local line_num = vim.api.nvim_win_get_cursor(task_win)[1]
  local lines = vim.api.nvim_buf_get_lines(task_buf, 0, -1, false)
  local line = lines[line_num]

  if not line or vim.trim(line) == "" then
    return
  end

  local task_name = vim.trim(line):gsub("^[* ] ", "")
  if task_name ~= "No tasks found" and not task_name:match("^Press") and not task_name:match("^Enter:") then
    core.select_task(task_name)
    close_window(task_buf, task_win)
    task_buf, task_win = nil, nil
  end
end

function M.toggle_task_list()
  if task_win and vim.api.nvim_win_is_valid(task_win) then
    parse_task_buffer()
    close_window(task_buf, task_win)
    task_buf, task_win = nil, nil
    return
  end

  local tasks = core.get_tasks()
  local current_task = core.get_current_task()

  local lines = {}
  local task_names = {}

  for name, _ in pairs(tasks) do
    table.insert(task_names, name)
  end

  if #task_names == 0 then
    table.insert(lines, "")
  else
    for _, name in ipairs(task_names) do
      local prefix = (name == current_task) and "* " or ""
      table.insert(lines, prefix .. name)
    end
  end

  task_buf, task_win = create_floating_window("Tasks", lines)

  vim.api.nvim_buf_set_lines(task_buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(task_buf, "filetype", "tasker-tasks")

  vim.api.nvim_create_autocmd({ "BufLeave" }, {
    buffer = task_buf,
    callback = function()
      parse_task_buffer()
      close_window(task_buf, task_win)
      task_buf, task_win = nil, nil
    end,
  })

  vim.keymap.set("n", "q", function()
    vim.cmd("q!")
  end, { buffer = task_buf, silent = true })

  vim.keymap.set("n", "<Esc>", function()
    vim.cmd("q!")
  end, { buffer = task_buf, silent = true })

  vim.keymap.set("n", "<CR>", function()
    select_task_from_cursor()
  end, { buffer = task_buf, silent = true })

end

local function parse_mark_buffer()
  if not mark_buf or not vim.api.nvim_buf_is_valid(mark_buf) then
    return
  end

  local current_task = core.get_current_task()
  if not current_task then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(mark_buf, 0, -1, false)
  local cwd = vim.fn.getcwd()
  local tasks = core.get_tasks()
  local task = tasks[current_task]

  if not task then
    return
  end

  task.marks = {}

  for _, line in ipairs(lines) do
    local trimmed = vim.trim(line)
    if trimmed ~= "" then
      local file_path = trimmed

      if not file_path:match("^/") then
        file_path = cwd .. "/" .. file_path
      end

      if vim.fn.filereadable(file_path) == 1 then
        local abs_path = vim.fn.fnamemodify(file_path, ":p")
        table.insert(task.marks, {
          path = abs_path,
          display_name = utils.get_display_name(abs_path, cwd),
        })
      end
    end
  end

  data.save_tasks(cwd, tasks)
end

local function select_mark_from_cursor()
  if not mark_buf or not mark_win or not vim.api.nvim_win_is_valid(mark_win) then
    return
  end

  local line_num = vim.api.nvim_win_get_cursor(mark_win)[1]
  local lines = vim.api.nvim_buf_get_lines(mark_buf, 0, -1, false)
  local line = lines[line_num]

  if not line or vim.trim(line) == "" then
    return
  end

  local file_path = vim.trim(line)
  local cwd = vim.fn.getcwd()

  if not file_path:match("^/") then
    file_path = cwd .. "/" .. file_path
  end

  if vim.fn.filereadable(file_path) == 1 then
    close_window(mark_buf, mark_win)
    mark_buf, mark_win = nil, nil
    vim.cmd("edit " .. vim.fn.fnameescape(file_path))
    vim.cmd("normal! zz")
  else
    vim.notify("File not found: " .. file_path, vim.log.levels.ERROR)
  end
end

function M.toggle_mark_list()
  if mark_win and vim.api.nvim_win_is_valid(mark_win) then
    parse_mark_buffer()
    close_window(mark_buf, mark_win)
    mark_buf, mark_win = nil, nil
    return
  end

  local current_task = core.get_current_task()
  if not current_task then
    vim.notify("No task selected", vim.log.levels.ERROR)
    return
  end

  local marks = core.get_current_marks()
  local lines = {}

  if #marks == 0 then
    table.insert(lines, "")
  else
    for _, mark in ipairs(marks) do
      table.insert(lines, mark.display_name)
    end
  end

  mark_buf, mark_win = create_floating_window("Marks - " .. current_task, lines)

  vim.api.nvim_buf_set_lines(mark_buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(mark_buf, "filetype", "tasker-marks")

  vim.api.nvim_create_autocmd({ "BufLeave" }, {
    buffer = mark_buf,
    callback = function()
      parse_mark_buffer()
      close_window(mark_buf, mark_win)
      mark_buf, mark_win = nil, nil
    end,
  })

  vim.keymap.set("n", "q", function()
    vim.cmd("q!")
  end, { buffer = mark_buf, silent = true })

  vim.keymap.set("n", "<Esc>", function()
    vim.cmd("q!")
  end, { buffer = mark_buf, silent = true })

  vim.keymap.set("n", "<CR>", function()
    select_mark_from_cursor()
  end, { buffer = mark_buf, silent = true })
end

return M
