local utils = require("bufstash.utils")

---@class BufstashData
local M = {}

local data_dir = vim.fn.stdpath("data") .. "/bufstash"

function M.setup()
  if vim.fn.isdirectory(data_dir) == 0 then
    vim.fn.mkdir(data_dir, "p")
  end
end

---@param cwd string
---@return string
local function get_data_file(cwd)
  local hash = utils.hash_string(cwd)
  return data_dir .. "/" .. hash .. ".json"
end

---@param cwd string
---@return table
function M.get_stashes(cwd)
  local file_path = get_data_file(cwd)

  if vim.fn.filereadable(file_path) == 0 then
    return {}
  end

  local content = utils.read_file(file_path)
  if not content then
    return {}
  end

  local ok, data = pcall(vim.json.decode, content)
  if not ok then
    vim.notify("Failed to parse stashes data for " .. cwd, vim.log.levels.ERROR)
    return {}
  end

  return data or {}
end

---@param cwd string
---@param stashes table
function M.save_stashes(cwd, stashes)
  -- Ensure directory exists before writing
  if vim.fn.isdirectory(data_dir) == 0 then
    vim.fn.mkdir(data_dir, "p")
  end

  local file_path = get_data_file(cwd)
  local content = vim.json.encode(stashes)

  if not utils.write_file(file_path, content) then
    vim.notify("Failed to save stashes data", vim.log.levels.ERROR)
  end
end

return M
