-- :PackClean removes plugins that vim.pack manages but this session never
-- added via vim.pack.add(), i.e. leftovers whose add() call was deleted.
-- Every vim.pack.add() in this config runs at startup; a plugin added lazily
-- (autocmd, keymap, command) would look unused here and must not be cleaned.
vim.api.nvim_create_user_command('PackClean', function()
  local unused = vim
    .iter(vim.pack.get(nil, { info = false }))
    :filter(function(p) return not p.active end)
    :map(function(p) return p.spec.name end)
    :totable()

  if #unused == 0 then
    vim.notify('PackClean: nothing to remove', vim.log.levels.INFO)
    return
  end

  local prompt = 'Delete unused plugins?\n  ' .. table.concat(unused, '\n  ')
  if vim.fn.confirm(prompt, '&Yes\n&No', 2) ~= 1 then return end

  vim.pack.del(unused)
end, { desc = 'Delete vim.pack plugins not added by this config' })
