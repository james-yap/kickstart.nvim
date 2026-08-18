-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information

local plugins_dir = vim.fs.joinpath(vim.fn.stdpath 'config', 'lua', 'custom', 'plugins')

-- Per-machine conform overrides (gitignored). Seed from the example on first
-- run, then load via the directory iteration below. init.lua SECTION 7 only
-- installs conform + shared defaults; this file owns format_on_save/formatters.
local format_path = vim.fs.joinpath(plugins_dir, 'format.lua')
local format_example = format_path .. '.example'
if not vim.uv.fs_stat(format_path) and vim.uv.fs_stat(format_example) then
  assert(vim.uv.fs_copyfile(format_example, format_path), 'failed to seed lua/custom/plugins/format.lua from example')
end

-- Iterate over all Lua files in the plugins directory and load them
for file_name, type in vim.fs.dir(plugins_dir, { follow = true }) do
  if (type == 'file' or type == 'link') and file_name:match '%.lua$' and file_name ~= 'init.lua' then
    local module = file_name:gsub('%.lua$', '')
    require('custom.plugins.' .. module)
  end
end
