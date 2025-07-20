---@class TaskerUtils
local M = {}

---@param str string
---@return string
function M.hash_string(str)
  local hash = 0
  for i = 1, #str do
    hash = (hash * 31 + string.byte(str, i)) % 0x100000000
  end
  return string.format("%x", hash)
end

---@param file_path string
---@return string?
function M.read_file(file_path)
  local file = io.open(file_path, "r")
  if not file then
    return nil
  end
  
  local content = file:read("*a")
  file:close()
  return content
end

---@param file_path string
---@param content string
---@return boolean
function M.write_file(file_path, content)
  local file = io.open(file_path, "w")
  if not file then
    return false
  end
  
  file:write(content)
  file:close()
  return true
end

---@param abs_path string
---@param cwd string
---@return string
function M.get_display_name(abs_path, cwd)
  local rel_path = vim.fn.fnamemodify(abs_path, ":~:.")
  if vim.startswith(rel_path, cwd) then
    return vim.fn.fnamemodify(abs_path, ":.")
  end
  return rel_path
end

---@param prompt string
---@param default string?
---@return string?
function M.input(prompt, default)
  local ok, result = pcall(vim.fn.input, prompt, default or "")
  if not ok or result == "" then
    return nil
  end
  return result
end

return M