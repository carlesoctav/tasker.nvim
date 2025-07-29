local bufstash = require("bufstash")

-- Ensure bufstash is initialized
pcall(bufstash.setup, {})

vim.api.nvim_create_user_command("BufstashCreateStash", function(opts)
  bufstash.create_stash(opts.args)
end, {
  nargs = 1,
  desc = "Create a new stash",
})

vim.api.nvim_create_user_command("BufstashSelectStash", function(opts)
  if opts.args and opts.args ~= "" then
    bufstash.select_stash(opts.args)
  else
    bufstash.select_stash_picker()
  end
end, {
  nargs = "?",
  desc = "Select a stash (use picker if no args)",
})

vim.api.nvim_create_user_command("BufstashDeleteStash", function(opts)
  if opts.args and opts.args ~= "" then
    bufstash.delete_stash(opts.args)
  else
    bufstash.delete_stash_picker()
  end
end, {
  nargs = "?",
  desc = "Delete a stash (use picker if no args)",
})

vim.api.nvim_create_user_command("BufstashAddStash", function(opts)
  if opts.args and opts.args ~= "" then
    bufstash.create_stash(opts.args)
  else
    bufstash.add_stash_picker()
  end
end, {
  nargs = "?",
  desc = "Add/create a stash (use picker if no args)",
})

vim.api.nvim_create_user_command("BufstashAddBuf", function(opts)
  bufstash.add_buf(opts.args)
end, {
  nargs = 1,
  complete = "file",
  desc = "Add a buffer for the given file path",
})

vim.api.nvim_create_user_command("BufstashAddBufCurrBuf", function()
  bufstash.add_buf_curr_buf()
end, {
  desc = "Add a buffer for the current buffer",
})

vim.api.nvim_create_user_command("BufstashSelectBuf", function(opts)
  bufstash.select_buf(tonumber(opts.args))
end, {
  nargs = 1,
  desc = "Open the buffer at the given index",
})

vim.api.nvim_create_user_command("BufstashDeleteBuf", function(opts)
  bufstash.delete_buf(tonumber(opts.args))
end, {
  nargs = 1,
  desc = "Delete the buffer at the given index",
})

vim.api.nvim_create_user_command("BufstashToggleBufList", function()
  bufstash.toggle_buf_list()
end, {
  desc = "Toggle buffer list",
})

vim.api.nvim_create_user_command("BufstashPinCurrentState", function()
  bufstash.pin_current_state()
end, {
  desc = "Pin all open buffers to the current stash",
})

vim.api.nvim_create_user_command("BufstashSelectAllBuf", function()
  bufstash.select_all_buf()
end, {
  desc = "Open all buffers in the current stash",
})
