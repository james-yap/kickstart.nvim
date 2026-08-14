-- fzf-lua: drive the real `fzf` binary for file finding (CLI-fzf speed,
-- non-blocking headless-nvim preview). Overrides the Telescope
-- `<leader>sf` / `<leader>sF` bindings defined in init.lua section 5;
-- this file loads afterward via `lua/custom/plugins/init.lua`, so the
-- override takes effect without touching init.lua. All other pickers
-- (grep, buffers, oldfiles, LSP, help, etc.) stay on Telescope.
vim.pack.add {
  { src = 'https://github.com/ibhagwan/fzf-lua' },
}

local fzf = require 'fzf-lua'

-- Rounded float border to match Telescope's default look. Defaults
-- already use a headless-nvim subprocess previewer (non-blocking), so
-- no extra previewer config is needed.
fzf.setup {
  winopts = {
    border = 'rounded',
  },
}

-- [S]earch [F]iles  (replaces builtin.find_files)
-- `hidden = false` is explicit: fzf-lua's `files` defaults to `hidden = true`
-- (includes dotfiles), but Telescope's find_files does not show hidden files.
vim.keymap.set('n', '<leader>sf', function() fzf.files({ hidden = false }) end, { desc = '[S]earch [F]iles' })

-- [S]earch all [F]iles, including hidden and ignored
-- (replaces builtin.find_files { hidden = true, no_ignore = true })
vim.keymap.set('n', '<leader>sF', function()
  fzf.files {
    hidden = true,
    no_ignore = true,
    winopts = { title = ' Find Files (hidden + ignored) ' },
  }
end, { desc = '[S]earch all [F]iles, including hidden and ignored' })
