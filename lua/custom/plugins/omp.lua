vim.pack.add { 'https://github.com/james-yap/omp.nvim' }

require('omp').setup {
  keymaps = {
    open = 'gm',
    hide = '<C-q>',
  },
}
