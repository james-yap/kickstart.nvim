vim.pack.add {
  { src = 'https://github.com/james-yap/p5render.nvim' },
}

require('p5render').setup {
  seconds = 4, -- default duration for :P5Render
}

vim.keymap.set('n', '<leader>ps', function()
  local opts = {}
  if vim.v.count > 0 then
    opts.seconds = vim.v.count
  end
  require('p5render').render(opts)
end, { desc = 'Render p5 sketch [count=seconds]' })

vim.keymap.set("n", "<leader>pt", function()
  local f = vim.fn.expand("%:p")
  vim.fn.system({ "touch", f })
  vim.notify("touched " .. f)
end, { desc = 'Touch current file' })
