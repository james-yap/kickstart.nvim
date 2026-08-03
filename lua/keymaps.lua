local M = {}

function M.setup()
  -- Copy the current file path, including the cursor position or visual selection.
  local function copy_path_with_position()
    local path = vim.fn.expand('%:p')
    local result
    local mode = vim.fn.mode()

    if mode == 'v' or mode == 'V' or mode == '\22' then
      local start_pos = vim.fn.getpos('v')
      local end_pos = vim.fn.getpos('.')
      local start_row, start_col = start_pos[2], start_pos[3]
      local end_row, end_col = end_pos[2], end_pos[3]

      -- Normalize so the start position precedes the end position.
      if start_row > end_row or (start_row == end_row and start_col > end_col) then
        start_row, start_col, end_row, end_col = end_row, end_col, start_row, start_col
      end

      if mode == 'V' then
        result = string.format('%s:L%d-L%d', path, start_row, end_row)
      elseif start_row == end_row then
        result = string.format('%s:L%d:C%d-C%d', path, start_row, start_col, end_col)
      else
        result = string.format('%s:L%d:C%d-L%d:C%d', path, start_row, start_col, end_row, end_col)
      end
    else
      -- No selection: copy the cursor position.
      local cursor = vim.fn.getpos('.')
      result = string.format('%s:L%d:C%d', path, cursor[2], cursor[3])
    end

    vim.fn.setreg('+', result)
    print('Copied: ' .. result)
  end

  vim.keymap.set({ 'n', 'x' }, '<leader>cp', copy_path_with_position, {
    desc = 'Copy file path with range or position',
  })

  -- Copy only the current file path.
  vim.keymap.set('n', '<leader>cP', function()
    local path = vim.fn.expand('%:p')
    vim.fn.setreg('+', path)
    print('Copied: ' .. path)
  end, { desc = 'Copy current file path' })
end

return M
