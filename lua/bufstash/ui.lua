local core = require("bufstash.core")
local utils = require("bufstash.utils")
local data = require("bufstash.data")

---@class BufstashUI
local M = {}

local buf_buf = nil
local buf_win = nil

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

  vim.api.nvim_set_option_value("buftype", "acwrite", { buf = buf })
  vim.api.nvim_set_option_value("cursorline", true, { win = win })
  vim.api.nvim_set_option_value("number", true, { win = win })

  return buf, win
end

local function parse_buf_buffer()
  if not buf_buf or not vim.api.nvim_buf_is_valid(buf_buf) then
    return
  end

  local current_stash = core.get_current_stash()
  if not current_stash then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(buf_buf, 0, -1, false)
  local cwd = vim.fn.getcwd()
  local stashes = core.get_stashes()
  local stash = stashes[current_stash]

  if not stash then
    return
  end

  stash.bufs = {}

  for _, line in ipairs(lines) do
    local trimmed = vim.trim(line)
    if trimmed ~= "" then
      local file_path = trimmed

      if not file_path:match("^/") then
        file_path = cwd .. "/" .. file_path
      end

      if vim.fn.filereadable(file_path) == 1 then
        local abs_path = vim.fn.fnamemodify(file_path, ":p")
        table.insert(stash.bufs, {
          path = abs_path,
          display_name = utils.get_display_name(abs_path, cwd),
        })
      end
    end
  end

  data.save_stashes(cwd, stashes)
end

local function select_buf_from_cursor()
  if not buf_buf or not buf_win or not vim.api.nvim_win_is_valid(buf_win) then
    return
  end

  local line_num = vim.api.nvim_win_get_cursor(buf_win)[1]
  local lines = vim.api.nvim_buf_get_lines(buf_buf, 0, -1, false)
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
    close_window(buf_buf, buf_win)
    buf_buf, buf_win = nil, nil
    vim.cmd("edit " .. vim.fn.fnameescape(file_path))
    vim.cmd("normal! zz")
  else
    vim.notify("File not found: " .. file_path, vim.log.levels.ERROR)
  end
end

function M.toggle_buf_list()
  if buf_win and vim.api.nvim_win_is_valid(buf_win) then
    parse_buf_buffer()
    close_window(buf_buf, buf_win)
    buf_buf, buf_win = nil, nil
    return
  end

  local current_stash = core.get_current_stash()
  if not current_stash then
    vim.notify("No stash selected", vim.log.levels.ERROR)
    return
  end

  local bufs = core.get_current_bufs()
  local lines = {}

  if #bufs == 0 then
    table.insert(lines, "")
  else
    for _, buf in ipairs(bufs) do
      table.insert(lines, buf.display_name)
    end
  end

  buf_buf, buf_win = create_floating_window("Buffers - " .. current_stash, lines)

  vim.api.nvim_buf_set_lines(buf_buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("filetype", "bufstash-bufs", { buf = buf_buf })

  vim.api.nvim_create_autocmd({ "BufLeave" }, {
    buffer = buf_buf,
    callback = function()
      parse_buf_buffer()
      close_window(buf_buf, buf_win)
      buf_buf, buf_win = nil, nil
    end,
  })

  vim.keymap.set("n", "q", function()
    vim.cmd("q!")
  end, { buffer = buf_buf, silent = true })

  vim.keymap.set("n", "<Esc>", function()
    vim.cmd("q!")
  end, { buffer = buf_buf, silent = true })

  vim.keymap.set("n", "<CR>", function()
    select_buf_from_cursor()
  end, { buffer = buf_buf, silent = true })
end

function M.select_stash()
  local stashes = core.get_stashes()
  local current_stash = core.get_current_stash()

  local stash_names = {}
  for name, _ in pairs(stashes) do
    table.insert(stash_names, name)
  end

  if #stash_names == 0 then
    vim.notify("No stashes found", vim.log.levels.WARN)
    return
  end

  table.sort(stash_names)

  local items = {}
  for _, name in ipairs(stash_names) do
    local prefix = (name == current_stash) and "* " or "  "
    table.insert(items, prefix .. name)
  end

  vim.ui.select(items, {
    prompt = "Select stash:",
    format_item = function(item)
      return item
    end,
  }, function(choice)
    if choice then
      local stash_name = choice:gsub("^[* ] ", "")
      core.select_stash(stash_name)
    end
  end)
end

function M.delete_stash()
  local stashes = core.get_stashes()
  local current_stash = core.get_current_stash()

  local stash_names = {}
  for name, _ in pairs(stashes) do
    table.insert(stash_names, name)
  end

  if #stash_names == 0 then
    vim.notify("No stashes found", vim.log.levels.WARN)
    return
  end

  table.sort(stash_names)

  local items = {}
  for _, name in ipairs(stash_names) do
    local prefix = (name == current_stash) and "* " or "  "
    local suffix = (name == current_stash) and " (current)" or ""
    table.insert(items, prefix .. name .. suffix)
  end

  vim.ui.select(items, {
    prompt = "Delete stash (call multiple times for batch):",
    format_item = function(item)
      return item
    end,
  }, function(choice)
    if choice then
      local stash_name = choice:gsub("^[* ] ", ""):gsub(" %(current%)$", "")
      local confirm_msg = string.format("Delete stash '%s'? (y/N)", stash_name)

      vim.ui.input({
        prompt = confirm_msg,
      }, function(input)
        if input and (input:lower() == "y" or input:lower() == "yes") then
          core.delete_stash(stash_name)
        end
      end)
    end
  end)
end

function M.add_stash()
  vim.ui.input({
    prompt = "Enter stash name: ",
  }, function(input)
    if not input or input == "" then
      return
    end

    local stash_name = vim.trim(input)
    if stash_name == "" then
      vim.notify("Stash name cannot be empty", vim.log.levels.ERROR)
      return
    end

    local stashes = core.get_stashes()
    if stashes[stash_name] then
      vim.notify("Stash '" .. stash_name .. "' already exists", vim.log.levels.WARN)
      return
    end

    core.create_stash(stash_name)
  end)
end

return M
