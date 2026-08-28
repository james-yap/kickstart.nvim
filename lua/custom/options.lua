-- Personal options / UI overrides applied after upstream kickstart setup.
-- OSC 52 clipboard stays in init.lua SECTION 1 (must run before provider pick).

vim.o.relativenumber = true

-- Prefer built-in quiet over the upstream tokyonight install/setup.
vim.o.background = 'dark'
vim.cmd.colorscheme 'quiet'

-- Richer cursor location in mini.statusline.
local ok, statusline = pcall(require, 'mini.statusline')
if ok then
  ---@diagnostic disable-next-line: duplicate-set-field
  statusline.section_location = function() return '%2l/%L:%-2v | %p%%' end
end
