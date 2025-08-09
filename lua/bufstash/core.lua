local utils = require("bufstash.utils")
local data = require("bufstash.data")

---@class BufstashCore
local M = {}

local state = {
  current_stash = nil,
  config = nil,
  initialized = false,
}

local function ensure_initialized()
  if not state.initialized then
    data.setup()
    state.initialized = true
  end
end

---@param config BufstashConfig
function M.setup(config)
  state.config = config
  data.setup()
  state.initialized = true
end

---@param name string
function M.create_stash(name)
  ensure_initialized()

  if not name or name == "" then
    vim.notify("Stash name cannot be empty", vim.log.levels.ERROR)
    return
  end

  local cwd = vim.fn.getcwd()
  local stashes = data.get_stashes(cwd)

  if stashes[name] then
    vim.notify("Stash '" .. name .. "' already exists", vim.log.levels.WARN)
    return
  end

  stashes[name] = { bufs = {} }
  data.save_stashes(cwd, stashes)

  state.current_stash = name
  vim.notify("Created stash: " .. name)

end
---@param name string
---@param stashes table
---@return table
function M.create_stash_given_table(name, stashes)
  if not name or name == "" then
    vim.notify("Stash name cannot be empty", vim.log.levels.ERROR)
    return stashes
  end

  if stashes[name] then
    vim.notify("Stash '" .. name .. "' already exists", vim.log.levels.WARN)
    return stashes
  end

  stashes[name] = { bufs = {} }

  vim.notify("Created stash: " .. name)
  return stashes
end

function M.hide_non_stash_buffers()
  ensure_initialized()
  
  if not state.current_stash then
    vim.notify("No stash selected", vim.log.levels.ERROR)
    return
  end
  
  local cwd = vim.fn.getcwd()
  local stashes = data.get_stashes(cwd)
  local stash = stashes[state.current_stash]
  
  if not stash then
    vim.notify("Current stash no longer exists", vim.log.levels.ERROR)
    state.current_stash = nil
    return
  end
  
  -- Get all stash buffer paths for quick lookup
  local stash_paths = {}
  if stash.bufs then
    for _, buf in ipairs(stash.bufs) do
      stash_paths[buf.path] = true
    end
  end
  
  local hidden_count = 0
  local buffers = vim.api.nvim_list_bufs()
  
  for _, buf in ipairs(buffers) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_get_option_value("buflisted", {buf = buf}) then
      local buf_name = vim.api.nvim_buf_get_name(buf)
      if buf_name ~= "" then
        local abs_path = vim.fn.fnamemodify(buf_name, ":p")
        -- If this buffer is not in the current stash, hide it
        if not stash_paths[abs_path] then
          vim.api.nvim_set_option_value("buflisted", false, {buf = buf})
          hidden_count = hidden_count + 1
        end
      end
    end
  end
  
  if hidden_count > 0 then
    vim.notify("Hidden " .. hidden_count .. " buffers not in stash: " .. state.current_stash)
  else
    vim.notify("No buffers to hide (all open buffers are in current stash)")
  end
end

function M.show_all_buffers()
  ensure_initialized()
  
  local shown_count = 0
  local buffers = vim.api.nvim_list_bufs()
  
  for _, buf in ipairs(buffers) do
    if vim.api.nvim_buf_is_loaded(buf) and not vim.api.nvim_get_option_value("buflisted", {buf = buf}) then
      local buf_name = vim.api.nvim_buf_get_name(buf)
      if buf_name ~= "" and vim.fn.filereadable(buf_name) == 1 then
        vim.api.nvim_set_option_value("buflisted", true, {buf = buf})
        shown_count = shown_count + 1
      end
    end
  end
  
  if shown_count > 0 then
    vim.notify("Showed " .. shown_count .. " hidden buffers")
  else
    vim.notify("No hidden buffers to show")
  end
end

---@param name string
function M.select_stash(name)
  ensure_initialized()

  local cwd = vim.fn.getcwd()
  local stashes = data.get_stashes(cwd)

  if not stashes[name] then
    vim.notify("Stash '" .. name .. "' does not exist", vim.log.levels.ERROR)
    return
  end

  state.current_stash = name
  local stash = stashes[name]
  
  -- Hide all non-stash buffers first
  M.hide_non_stash_buffers()
  
  -- Open all buffers in the selected stash
  if stash and stash.bufs and #stash.bufs > 0 then
    local opened_count = 0
    local last_opened = nil
    
    for _, buf in ipairs(stash.bufs) do
      if vim.fn.filereadable(buf.path) == 1 then
        vim.cmd("edit " .. vim.fn.fnameescape(buf.path))
        last_opened = buf.path
        opened_count = opened_count + 1
      end
    end
    
    -- Focus on the last opened file
    if last_opened then
      vim.cmd("normal! zz")
    end
    
    vim.notify("Selected stash: " .. name .. " (opened " .. opened_count .. " buffers)")
  else
    vim.notify("Selected stash: " .. name .. " (no buffers)")
  end
end

---@param name string
function M.delete_stash(name)
  ensure_initialized()

  local cwd = vim.fn.getcwd()
  local stashes = data.get_stashes(cwd)

  if not stashes[name] then
    vim.notify("Stash '" .. name .. "' does not exist", vim.log.levels.ERROR)
    return
  end

  stashes[name] = nil
  data.save_stashes(cwd, stashes)

  if state.current_stash == name then
    state.current_stash = nil
  end

  vim.notify("Deleted stash: " .. name)
end

---@param name string
---@param stashes table
---@return table
function M.delete_stash_given_table(name, stashes)
  if not stashes[name] then
    vim.notify("Stash '" .. name .. "' does not exist", vim.log.levels.ERROR)
    return stashes
  end

  stashes[name] = nil

  if state.current_stash == name then
    state.current_stash = nil
  end

  vim.notify("Deleted stash: " .. name)
  return stashes
end

---@param file_path string
function M.add_buf(file_path)
  ensure_initialized()

  if not state.current_stash then
    vim.notify("No stash selected. Create or select a stash first.", vim.log.levels.ERROR)
    return
  end

  if not file_path or file_path == "" then
    vim.notify("File path cannot be empty", vim.log.levels.ERROR)
    return
  end

  local cwd = vim.fn.getcwd()
  local stashes = data.get_stashes(cwd)
  local stash = stashes[state.current_stash]

  if not stash then
    vim.notify("Current stash no longer exists", vim.log.levels.ERROR)
    state.current_stash = nil
    return
  end

  local abs_path = vim.fn.fnamemodify(file_path, ":p")

  for _, buf in ipairs(stash.bufs) do
    if buf.path == abs_path then
      vim.notify("File already buffered in current stash", vim.log.levels.WARN)
      return
    end
  end

  table.insert(stash.bufs, {
    path = abs_path,
    display_name = utils.get_display_name(abs_path, cwd),
  })

  data.save_stashes(cwd, stashes)
  vim.notify("Added buffer: " .. utils.get_display_name(abs_path, cwd))
end

function M.add_buf_curr_buf()
  local buf_name = vim.api.nvim_buf_get_name(0)
  if buf_name == "" then
    vim.notify("Current buffer has no file", vim.log.levels.ERROR)
    return
  end

  M.add_buf(buf_name)
end

---@param id number
function M.select_buf(id)
  if not state.current_stash then
    vim.notify("No stash selected", vim.log.levels.ERROR)
    return
  end
  local cwd = vim.fn.getcwd()
  local stashes = data.get_stashes(cwd)
  local stash = stashes[state.current_stash]

  if not stash or not stash.bufs[id] then
    vim.notify("Invalid buffer index: " .. id, vim.log.levels.ERROR)
    return
  end

  local buf = stash.bufs[id]
  if vim.fn.filereadable(buf.path) == 1 then
    vim.cmd("edit " .. vim.fn.fnameescape(buf.path))
    vim.cmd("normal! zz")
  else
    vim.notify("File not found: " .. buf.path, vim.log.levels.ERROR)
  end
end

---@param id number
function M.delete_buf(id)
  if not state.current_stash then
    vim.notify("No stash selected", vim.log.levels.ERROR)
    return
  end

  local cwd = vim.fn.getcwd()
  local stashes = data.get_stashes(cwd)
  local stash = stashes[state.current_stash]

  if not stash or not stash.bufs[id] then
    vim.notify("Invalid buffer index: " .. id, vim.log.levels.ERROR)
    return
  end

  local buf = table.remove(stash.bufs, id)
  data.save_stashes(cwd, stashes)
  vim.notify("Deleted buffer: " .. buf.display_name)
end

function M.pin_current_state()
  if not state.current_stash then
    vim.notify("No stash selected", vim.log.levels.ERROR)
    return
  end

  local cwd = vim.fn.getcwd()
  local stashes = data.get_stashes(cwd)
  local stash = stashes[state.current_stash]

  if not stash then
    vim.notify("Current stash no longer exists", vim.log.levels.ERROR)
    state.current_stash = nil
    return
  end

  stash.bufs = {}

  local buffers = vim.api.nvim_list_bufs()
  local added_count = 0

  for _, buf in ipairs(buffers) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_get_option_value("buflisted", {buf = buf}) then
      local buf_name = vim.api.nvim_buf_get_name(buf)
      if buf_name ~= "" and vim.fn.filereadable(buf_name) == 1 then
        local abs_path = vim.fn.fnamemodify(buf_name, ":p")
        table.insert(stash.bufs, {
          path = abs_path,
          display_name = utils.get_display_name(abs_path, cwd),
        })
        added_count = added_count + 1
      end
    end
  end
  data.save_stashes(cwd, stashes)
  vim.notify("Pinned " .. added_count .. " buffers to stash: " .. state.current_stash)
end

function M.select_all_buf()
  if not state.current_stash then
    vim.notify("No stash selected", vim.log.levels.ERROR)
    return
  end

  local cwd = vim.fn.getcwd()
  local stashes = data.get_stashes(cwd)
  local stash = stashes[state.current_stash]

  if not stash or #stash.bufs == 0 then
    vim.notify("No buffers in current stash", vim.log.levels.WARN)
    return
  end

  local opened_count = 0
  local last_opened = nil
  for _, buf in ipairs(stash.bufs) do
    if vim.fn.filereadable(buf.path) == 1 then
      vim.cmd("edit " .. vim.fn.fnameescape(buf.path))
      last_opened = buf.path
      opened_count = opened_count + 1
    end
  end

  -- Focus on the last opened file
  if last_opened then
    vim.cmd("normal! zz")
  end

  vim.notify("Opened " .. opened_count .. " buffers from stash: " .. state.current_stash)
end

function M.get_current_stash()
  return state.current_stash
end

function M.get_stashes()
  ensure_initialized()

  local cwd = vim.fn.getcwd()
  return data.get_stashes(cwd)
end

function M.get_current_bufs()
  if not state.current_stash then
    return {}
  end

  local cwd = vim.fn.getcwd()
  local stashes = data.get_stashes(cwd)
  local stash = stashes[state.current_stash]

  return stash and stash.bufs or {}
end

return M

