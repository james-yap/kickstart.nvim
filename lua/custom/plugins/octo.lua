vim.pack.add {
  { src = 'https://github.com/pwntester/octo.nvim' },
  { src = 'https://github.com/nvim-tree/nvim-web-devicons' },
}

require('octo').setup {
  picker = 'telescope', -- or "fzf-lua" or "snacks" or "default"
  enable_builtin = true,

  -- world: origin is gitstream; github is github.com/shop/world
  default_remote = { 'github', 'upstream', 'origin' },

  reviews = {
    auto_show_threads = true,
    show_virtual_text = true,
  },
}

vim.keymap.set('n', '<leader>oi', '<CMD>Octo issue list<CR>', { desc = 'List GitHub Issues' })
vim.keymap.set('n', '<leader>op', '<CMD>Octo pr list<CR>', { desc = 'List GitHub Pull Requests' })
vim.keymap.set('n', '<leader>od', '<CMD>Octo discussion list<CR>', { desc = 'List GitHub Discussions' })
vim.keymap.set('n', '<leader>on', '<CMD>Octo notification list<CR>', { desc = 'List GitHub Notifications' })

vim.keymap.set('n', '<leader>os', function() require('octo.utils').create_base_search_command { include_current_repo = true } end, { desc = 'Search GitHub' })
