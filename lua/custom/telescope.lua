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

vim.keymap.set('n', 'gs', builtin.git_status, { desc = '[G]it [S]tatus' })

-- vim.keymap.set('n', 'gs', function()
--   local start_dir = vim.fn.expand '%:p:h'
--   if start_dir == '' then start_dir = vim.uv.cwd() end
--
--   local root_result = vim.system({ 'git', 'rev-parse', '--show-toplevel' }, { cwd = start_dir, text = true }):wait()
--   if root_result.code ~= 0 then
--     vim.notify(vim.trim(root_result.stderr), vim.log.levels.ERROR)
--     return
--   end
--   local root = vim.trim(root_result.stdout)
--
--   local base_result = vim.system({ 'git', 'merge-base', 'origin/main', 'HEAD' }, { cwd = root, text = true }):wait()
--   if base_result.code ~= 0 then
--     vim.notify(vim.trim(base_result.stderr), vim.log.levels.ERROR)
--     return
--   end
--   local base = vim.trim(base_result.stdout)
--   require('gitsigns').change_base(base, true, function(err)
--     if err then vim.notify(err, vim.log.levels.ERROR) end
--   end)
--
--   builtin.find_files {
--     cwd = root,
--     prompt_title = 'Changes vs origin/main',
--     find_command = {
--       'git',
--       'diff',
--       '--name-only',
--       '--diff-filter=ACMR',
--       base,
--       '--',
--       '.',
--     },
--   }
-- end, { desc = '[G]it changes vs origin/main' })

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
