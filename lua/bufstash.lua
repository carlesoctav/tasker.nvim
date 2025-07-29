local bufstash = require("bufstash.core")
local ui = require("bufstash.ui")

---@class BufstashConfig
local default_config = {
}

---@class Bufstash
local M = {}

---@type BufstashConfig
M.config = default_config

---@param args BufstashConfig?
M.setup = function(args)
  M.config = vim.tbl_deep_extend("force", M.config, args or {})
  bufstash.setup(M.config)
end

M.create_stash = bufstash.create_stash
M.select_stash = bufstash.select_stash
M.delete_stash = bufstash.delete_stash

M.select_stash_picker = ui.select_stash
M.delete_stash_picker = ui.delete_stash
M.add_stash_picker = ui.add_stash

M.add_buf = bufstash.add_buf
M.add_buf_curr_buf = bufstash.add_buf_curr_buf
M.select_buf = bufstash.select_buf
M.delete_buf = bufstash.delete_buf
M.toggle_buf_list = ui.toggle_buf_list
M.pin_current_state = bufstash.pin_current_state
M.select_all_buf = bufstash.select_all_buf

M.get_current_stash = bufstash.get_current_stash
M.get_stashes = bufstash.get_stashes
M.get_current_bufs = bufstash.get_current_bufs

return M
