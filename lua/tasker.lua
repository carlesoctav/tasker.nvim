local tasker = require("tasker.core")
local ui = require("tasker.ui")

---@class TaskerConfig
---@field save_on_toggle boolean Save marks when toggling lists
---@field save_on_change boolean Save marks when changing tasks
---@field excluded_filetypes string[] Filetypes to exclude from marking
local default_config = {
}

---@class Tasker
local M = {}

---@type TaskerConfig
M.config = default_config

---@param args TaskerConfig?
M.setup = function(args)
  M.config = vim.tbl_deep_extend("force", M.config, args or {})
  tasker.setup(M.config)
end

M.create_task = tasker.create_task
M.select_task = tasker.select_task
M.delete_task = tasker.delete_task
M.toggle_task_list = ui.toggle_task_list
M.add_mark = tasker.add_mark
M.add_mark_curr_buf = tasker.add_mark_curr_buf
M.select_mark = tasker.select_mark
M.delete_mark = tasker.delete_mark
M.toggle_mark_list = ui.toggle_mark_list
M.pin_current_state = tasker.pin_current_state
M.select_all_mark = tasker.select_all_mark

M.get_current_task = tasker.get_current_task
M.get_tasks = tasker.get_tasks
M.get_current_marks = tasker.get_current_marks

return M
