-- Personal keymaps (loaded from custom/ at the end of init.lua).

-- File path with cursor position or visual selection range.
local function path_with_position()
  local path = vim.fn.expand '%:p'
  local mode = vim.fn.mode()

  if mode == 'v' or mode == 'V' or mode == '\22' then
    local start_pos = vim.fn.getpos 'v'
    local end_pos = vim.fn.getpos '.'
    local start_row, start_col = start_pos[2], start_pos[3]
    local end_row, end_col = end_pos[2], end_pos[3]

    -- Normalize so the start position precedes the end position.
    if start_row > end_row or (start_row == end_row and start_col > end_col) then
      start_row, start_col, end_row, end_col = end_row, end_col, start_row, start_col
    end

    if mode == 'V' then
      return string.format('%s:L%d-L%d', path, start_row, end_row)
    elseif start_row == end_row then
      return string.format('%s:L%d:C%d-C%d', path, start_row, start_col, end_col)
    end
    return string.format('%s:L%d:C%d-L%d:C%d', path, start_row, start_col, end_row, end_col)
  end

  local cursor = vim.fn.getpos '.'
  return string.format('%s:L%d:C%d', path, cursor[2], cursor[3])
end

local function copy_path_with_position()
  local result = path_with_position()
  vim.fn.setreg('+', result)
  vim.notify('Copied path+position to clipboard', vim.log.levels.INFO)
end

vim.keymap.set({ 'n', 'x' }, 'gp', copy_path_with_position, {
  desc = 'Copy file path with range or position',
})

-- Copy only the current file path.
vim.keymap.set('n', 'gP', function()
  local path = vim.fn.expand '%:p'
  vim.fn.setreg('+', path)
  vim.notify('Copied file path to clipboard', vim.log.levels.INFO)
end, { desc = 'Copy current file path' })

-- Keep the current quickfix entry aligned with the active file without
-- jumping to the entry's saved line or column.
local quickfix_sync_group = vim.api.nvim_create_augroup('custom_quickfix_sync', { clear = true })

vim.api.nvim_create_autocmd('BufEnter', {
  group = quickfix_sync_group,
  callback = function(args)
    if vim.bo[args.buf].buftype ~= '' then return end

    local info = vim.fn.getqflist { id = 0, items = 0, idx = 0 }
    local current_item = info.items[info.idx]
    if current_item and current_item.bufnr == args.buf then return end

    for index, item in ipairs(info.items) do
      if item.bufnr == args.buf then
        vim.fn.setqflist({}, 'a', { id = info.id, idx = index })
        return
      end
    end
  end,
  desc = 'Sync quickfix entry with the active file',
})

-- Remove the focused entry from the current quickfix list. In a quickfix
-- window, use the cursor row; elsewhere, use the list's active entry.
vim.keymap.set('n', '<leader>qd', function()
  local info = vim.fn.getqflist { id = 0, items = 0, idx = 0 }
  local wininfo = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1]
  local index = wininfo.quickfix == 1 and vim.api.nvim_win_get_cursor(0)[1] or info.idx

  if index < 1 or index > #info.items then
    vim.notify('Quickfix list is empty', vim.log.levels.INFO)
    return
  end

  table.remove(info.items, index)
  vim.fn.setqflist({}, 'r', {
    id = info.id,
    items = info.items,
    idx = math.min(index, #info.items),
  })

  if #info.items > 0 then vim.cmd.cc() end
end, { desc = 'Quickfix [D]elete focused entry' })
