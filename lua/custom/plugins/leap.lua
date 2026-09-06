vim.pack.add { 'https://codeberg.org/andyg/leap.nvim' }

-- See `:h leap-mappings`, `:h leap.visit-mappings` for more.

-- Jump
vim.keymap.set({ 'n', 'x', 'o' }, 'f',  '<Plug>(leap)')
