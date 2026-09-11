-- Personal keymaps (loaded from custom/ at the end of init.lua).

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

vim.keymap.set('n', 'g-', function()
  local abspath = vim.api.nvim_buf_get_name(0)
  local filename = vim.fn.fnamemodify(abspath, ':t')
  local relpath = vim.fn.fnamemodify(abspath, ':.')

  local cmd = string.format('jj squash --into @- %s', vim.fn.shellescape(relpath))
  local output = vim.fn.system(cmd)

  if vim.v.shell_error ~= 0 then
    local err_msg = vim.trim(output)
    vim.notify(string.format('jj squash failed:\n%s', err_msg), vim.log.levels.ERROR)
  end

  vim.notify(string.format( 'squashed "%s" to previous jj commit' , filename), vim.log.levels.INFO)
end, { desc = 'Squash current file to previous jj commit' })

vim.keymap.set('n', '<leader>rl', function()
  local abspath = vim.api.nvim_buf_get_name(0)
  if vim.fn.fnamemodify(abspath, ':e') ~= 'tex' then
    vim.notify('current file is not .tex', vim.log.levels.WARN)
    return
  end

  local filename = vim.fn.fnamemodify(abspath, ':t')
  local dir = vim.fn.fnamemodify(abspath, ':h')
  local result = vim.system(
    { 'pdflatex', '-interaction=nonstopmode', filename },
    { cwd = dir, text = true }
  ):wait()

  if result.code ~= 0 then
    local output = vim.trim((result.stdout or '') .. (result.stderr or ''))
    local lines = vim.split(output, '\n', { plain = true })
    local start = math.max(1, #lines - 19)
    local err_msg = table.concat(vim.list_slice(lines, start, #lines), '\n')
    vim.notify(string.format('pdflatex failed:\n%s', err_msg), vim.log.levels.ERROR)
    return
  end

  vim.notify(string.format('compiled "%s"', filename), vim.log.levels.INFO)
end, { desc = 'Run pdflatex on current file' })
