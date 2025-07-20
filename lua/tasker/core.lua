local utils = require("tasker.utils")
local data = require("tasker.data")

---@class TaskerCore
local M = {}

local state = {
  current_task = nil,
  config = nil,
}

---@param config TaskerConfig
function M.setup(config)
  state.config = config
  data.setup()
end

---@param name string
function M.create_task(name)
  if not name or name == "" then
    vim.notify("Task name cannot be empty", vim.log.levels.ERROR)
    return
  end

  local cwd = vim.fn.getcwd()
  local tasks = data.get_tasks(cwd)

  if tasks[name] then
    vim.notify("Task '" .. name .. "' already exists", vim.log.levels.WARN)
    return
  end

  tasks[name] = { marks = {} }
  data.save_tasks(cwd, tasks)

  state.current_task = name
  vim.notify("Created task: " .. name)

end
---@param name string
---@param tasks table
---@return table
function M.create_task_given_table(name, tasks)
  if not name or name == "" then
    vim.notify("Task name cannot be empty", vim.log.levels.ERROR)
    return tasks
  end

  local cwd = vim.fn.getcwd()

  if tasks[name] then
    vim.notify("Task '" .. name .. "' already exists", vim.log.levels.WARN)
    return tasks
  end

  tasks[name] = { marks = {} }

  vim.notify("Created task: " .. name)
  return tasks
end

---@param name string
function M.select_task(name)
  local cwd = vim.fn.getcwd()
  local tasks = data.get_tasks(cwd)

  if not tasks[name] then
    vim.notify("Task '" .. name .. "' does not exist", vim.log.levels.ERROR)
    return
  end

  state.current_task = name
  vim.notify("Selected task: " .. name)
end

---@param name string
function M.delete_task(name)
  local cwd = vim.fn.getcwd()
  local tasks = data.get_tasks(cwd)

  if not tasks[name] then
    vim.notify("Task '" .. name .. "' does not exist", vim.log.levels.ERROR)
    return
  end

  tasks[name] = nil
  data.save_tasks(cwd, tasks)

  if state.current_task == name then
    state.current_task = nil
  end

  vim.notify("Deleted task: " .. name)
end

---@param name string
---@param tasks table
---@return table
function M.delete_task_given_table(name, tasks)
  local cwd = vim.fn.getcwd()

  if not tasks[name] then
    vim.notify("Task '" .. name .. "' does not exist", vim.log.levels.ERROR)
    return tasks
  end

  tasks[name] = nil

  if state.current_task == name then
    state.current_task = nil
  end

  vim.notify("Deleted task: " .. name)
  return tasks
end

---@param file_path string
function M.add_mark(file_path)
  if not state.current_task then
    vim.notify("No task selected. Create or select a task first.", vim.log.levels.ERROR)
    return
  end

  if not file_path or file_path == "" then
    vim.notify("File path cannot be empty", vim.log.levels.ERROR)
    return
  end

  local cwd = vim.fn.getcwd()
  local tasks = data.get_tasks(cwd)
  local task = tasks[state.current_task]

  if not task then
    vim.notify("Current task no longer exists", vim.log.levels.ERROR)
    state.current_task = nil
    return
  end

  local abs_path = vim.fn.fnamemodify(file_path, ":p")

  for _, mark in ipairs(task.marks) do
    if mark.path == abs_path then
      vim.notify("File already marked in current task", vim.log.levels.WARN)
      return
    end
  end

  table.insert(task.marks, {
    path = abs_path,
    display_name = utils.get_display_name(abs_path, cwd),
  })

  data.save_tasks(cwd, tasks)
  vim.notify("Added mark: " .. utils.get_display_name(abs_path, cwd))
end

function M.add_mark_curr_buf()
  local buf_name = vim.api.nvim_buf_get_name(0)
  if buf_name == "" then
    vim.notify("Current buffer has no file", vim.log.levels.ERROR)
    return
  end

  M.add_mark(buf_name)
end

---@param id number
function M.select_mark(id)
  if not state.current_task then
    vim.notify("No task selected", vim.log.levels.ERROR)
    return
  end
  local cwd = vim.fn.getcwd()
  local tasks = data.get_tasks(cwd)
  local task = tasks[state.current_task]

  if not task or not task.marks[id] then
    vim.notify("Invalid mark index: " .. id, vim.log.levels.ERROR)
    return
  end

  local mark = task.marks[id]
  if vim.fn.filereadable(mark.path) == 1 then
    vim.cmd("edit " .. vim.fn.fnameescape(mark.path))
    vim.cmd("normal! zz")
  else
    vim.notify("File not found: " .. mark.path, vim.log.levels.ERROR)
  end
end

---@param id number
function M.delete_mark(id)
  if not state.current_task then
    vim.notify("No task selected", vim.log.levels.ERROR)
    return
  end

  local cwd = vim.fn.getcwd()
  local tasks = data.get_tasks(cwd)
  local task = tasks[state.current_task]

  if not task or not task.marks[id] then
    vim.notify("Invalid mark index: " .. id, vim.log.levels.ERROR)
    return
  end

  local mark = table.remove(task.marks, id)
  data.save_tasks(cwd, tasks)
  vim.notify("Deleted mark: " .. mark.display_name)
end

function M.pin_current_state()
  if not state.current_task then
    vim.notify("No task selected", vim.log.levels.ERROR)
    return
  end

  local cwd = vim.fn.getcwd()
  local tasks = data.get_tasks(cwd)
  local task = tasks[state.current_task]

  if not task then
    vim.notify("Current task no longer exists", vim.log.levels.ERROR)
    state.current_task = nil
    return
  end

  task.marks = {}

  local buffers = vim.api.nvim_list_bufs()
  local added_count = 0

  for _, buf in ipairs(buffers) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_option(buf, "buflisted") then
      local buf_name = vim.api.nvim_buf_get_name(buf)
      if buf_name ~= "" and vim.fn.filereadable(buf_name) == 1 then
        local abs_path = vim.fn.fnamemodify(buf_name, ":p")
        table.insert(task.marks, {
          path = abs_path,
          display_name = utils.get_display_name(abs_path, cwd),
        })
        added_count = added_count + 1
      end
    end
  end
  data.save_tasks(cwd, tasks)
  vim.notify("Pinned " .. added_count .. " buffers to task: " .. state.current_task)
end

function M.select_all_mark()
  if not state.current_task then
    vim.notify("No task selected", vim.log.levels.ERROR)
    return
  end

  local cwd = vim.fn.getcwd()
  local tasks = data.get_tasks(cwd)
  local task = tasks[state.current_task]

  if not task or #task.marks == 0 then
    vim.notify("No marks in current task", vim.log.levels.WARN)
    return
  end

  local opened_count = 0
  local last_opened = nil
  for _, mark in ipairs(task.marks) do
    if vim.fn.filereadable(mark.path) == 1 then
      vim.cmd("edit " .. vim.fn.fnameescape(mark.path))
      last_opened = mark.path
      opened_count = opened_count + 1
    end
  end

  -- Focus on the last opened file
  if last_opened then
    vim.cmd("normal! zz")
  end

  vim.notify("Opened " .. opened_count .. " marks from task: " .. state.current_task)
end

function M.get_current_task()
  return state.current_task
end

function M.get_tasks()
  local cwd = vim.fn.getcwd()
  return data.get_tasks(cwd)
end

function M.get_current_marks()
  if not state.current_task then
    return {}
  end

  local cwd = vim.fn.getcwd()
  local tasks = data.get_tasks(cwd)
  local task = tasks[state.current_task]

  return task and task.marks or {}
end

return M

