vim.pack.add { 'https://github.com/james-yap/omp.nvim' }

require('omp').setup {
  keymaps = {
    open = '<C-m>',
    hide = '<C-q>',
  },
}
