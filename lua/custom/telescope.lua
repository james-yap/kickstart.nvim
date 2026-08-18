-- Personal Telescope overrides (loaded after upstream SECTION 5 setup).
-- Re-calling setup merges into the existing config.

local ok, telescope = pcall(require, 'telescope')
if not ok then return end

telescope.setup {
  defaults = {
    -- Lua patterns (not globs). Skip vendored trees in find/grep pickers.
    file_ignore_patterns = {
      'repos/',
    },
  },
}

local builtin = require 'telescope.builtin'

vim.keymap.set('n', '<leader>gs', builtin.git_status, { desc = '[G]it [S]tatus' })

-- Prefer plain buffer fuzzy-find over upstream's dropdown theme.
vim.keymap.set('n', '<leader>/', builtin.current_buffer_fuzzy_find, { desc = '[/] Fuzzily search in current buffer' })

vim.keymap.set(
  'n',
  '<leader>sG',
  function()
    builtin.live_grep {
      additional_args = { '-F' },
      prompt_title = 'Live Grep (fixed string)',
    }
  end,
  { desc = '[S]earch by [G]rep (fixed string)' }
)

vim.keymap.set(
  'n',
  '<leader>sF',
  function()
    builtin.find_files {
      hidden = true,
      no_ignore = true,
      prompt_title = 'Find Files (hidden + ignored)',
    }
  end,
  { desc = '[S]earch all [F]iles, including hidden and ignored' }
)
