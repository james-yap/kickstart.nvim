local checkout = vim.fn.expand('~/git/pdfview.nvim')
if vim.uv.fs_stat(checkout .. '/lua/pdfview/init.lua') then
  vim.opt.runtimepath:prepend(checkout)
else
  vim.pack.add { 'https://github.com/james-yap/pdfview.nvim' }
end

require('pdfview').setup()
