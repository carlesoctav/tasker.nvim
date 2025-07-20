local tasker = require("tasker")

vim.api.nvim_create_user_command("TaskerCreateTask", function(opts)
  tasker.create_task(opts.args)
end, {
  nargs = 1,
  desc = "Create a new task",
})

vim.api.nvim_create_user_command("TaskerSelectTask", function(opts)
  tasker.select_task(opts.args)
end, {
  nargs = 1,
  desc = "Select a task",
})

vim.api.nvim_create_user_command("TaskerDeleteTask", function(opts)
  tasker.delete_task(opts.args)
end, {
  nargs = 1,
  desc = "Delete a task",
})

vim.api.nvim_create_user_command("TaskerToggleTaskList", function()
  tasker.toggle_task_list()
end, {
  desc = "Toggle task list",
})

vim.api.nvim_create_user_command("TaskerAddMark", function(opts)
  tasker.add_mark(opts.args)
end, {
  nargs = 1,
  complete = "file",
  desc = "Add a mark for the given file path",
})

vim.api.nvim_create_user_command("TaskerAddMarkCurrBuf", function()
  tasker.add_mark_curr_buf()
end, {
  desc = "Add a mark for the current buffer",
})

vim.api.nvim_create_user_command("TaskerSelectMark", function(opts)
  tasker.select_mark(tonumber(opts.args))
end, {
  nargs = 1,
  desc = "Open the mark at the given index",
})

vim.api.nvim_create_user_command("TaskerDeleteMark", function(opts)
  tasker.delete_mark(tonumber(opts.args))
end, {
  nargs = 1,
  desc = "Delete the mark at the given index",
})

vim.api.nvim_create_user_command("TaskerToggleMarkList", function()
  tasker.toggle_mark_list()
end, {
  desc = "Toggle mark list",
})

vim.api.nvim_create_user_command("TaskerPinCurrentState", function()
  tasker.pin_current_state()
end, {
  desc = "Pin all open buffers to the current task",
})

vim.api.nvim_create_user_command("TaskerSelectAllMark", function()
  tasker.select_all_mark()
end, {
  desc = "Open all marks in the current task",
})
