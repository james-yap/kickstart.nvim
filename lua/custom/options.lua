-- Personal options / UI overrides applied after upstream kickstart setup.

-- Yank to host clipboard over SSH.
-- Paste still from unnamed register for terminal security.
if vim.env.SSH_CONNECTION then
  local osc52 = require('vim.ui.clipboard.osc52')
  local function paste()
    return {
      vim.split(vim.fn.getreg '"', '\n'),
      vim.fn.getregtype '"',
    }
  end
  vim.g.clipboard = {
    name = 'OSC 52',
    copy = {
      ['+'] = osc52.copy '+',
      ['*'] = osc52.copy '*',
    },
    paste = {
      ['+'] = paste,
      ['*'] = paste,
    },
  }
  if vim.g.loaded_clipboard_provider then
    vim.g.loaded_clipboard_provider = nil
    vim.cmd.runtime 'autoload/provider/clipboard.vim'
  end
end

vim.o.relativenumber = true

-- Prefer built-in quiet over the upstream tokyonight install/setup.
vim.o.background = 'dark'
vim.cmd.colorscheme 'catppuccin'

-- Richer cursor location in mini.statusline.
local ok, statusline = pcall(require, 'mini.statusline')
if ok then
  ---@diagnostic disable-next-line: duplicate-set-field
  statusline.section_location = function() return 'L%L %p%%' end
end
