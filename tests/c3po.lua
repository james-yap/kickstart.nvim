-- Run from the config root: nvim --headless -u NONE -l tests/c3po.lua
local root = vim.fn.getcwd()
vim.opt.runtimepath:prepend(root)
local c3po = require 'custom.plugins.c3po'
local tmp = vim.fn.tempname()
local messages = {}
vim.notify = function(message, level) messages[#messages + 1] = { message = message, level = level } end

local function eq(expected, actual) assert(vim.deep_equal(expected, actual), string.format('Expected %s, got %s', vim.inspect(expected), vim.inspect(actual))) end
local function marker(kind, id) return kind .. ': ' .. string.format('c3po[%d]', id) end
local function block(id) return { marker('Start', id), 'body', marker('End', id) } end
local function file(name, lines)
  local path = tmp .. '/' .. name
  vim.fn.writefile(lines, path)
  return path
end
local function ids(blocks)
  return vim.tbl_map(function(b) return b.id end, blocks)
end
local function last_message() return messages[#messages].message end

local ok, err = xpcall(function()
  vim.fn.mkdir(tmp .. '/.git', 'p') -- Make rg honor .gitignore in the fixture.
  tmp = assert(vim.uv.fs_realpath(tmp))
  vim.cmd.cd(tmp)
  file('.gitignore', { 'ignored.txt' })
  file('ignored.txt', block(99))
  file('.git/internal', block(98))
  file('.hidden', { '-- ' .. marker('Start', 20), '---', 'body', '-- ' .. marker('End', 20) })
  local first = file('a file.txt', vim.list_extend({ 'outside' }, block(0)))
  local second = file('b.txt', block(7))
  file('old.txt', { 'Agent: ' .. 'c3po[123]' })
  local blocks, warnings = c3po.scan()
  eq({ 0, 7, 20 }, ids(blocks))
  eq({}, warnings)

  vim.cmd.edit(vim.fn.fnameescape(first))
  eq(nil, c3po.current(blocks))
  for _, line in ipairs { 2, 3, 4 } do
    vim.api.nvim_win_set_cursor(0, { line, 0 })
    eq(1, c3po.current(blocks)) -- Start and End are inclusive.
  end
  vim.cmd.C3po()
  eq('c3po[0] — block 1 of 3', last_message())
  vim.cmd 'C3po 7'
  eq(second, vim.api.nvim_buf_get_name(0))
  eq({ 1, 0 }, vim.api.nvim_win_get_cursor(0))
  vim.cmd 'C3po 1'
  eq('No valid block with ID 1', last_message()) -- ID, not ordinal.
  eq(second, vim.api.nvim_buf_get_name(0))
  eq({ '0', '7', '20' }, vim.fn.getcompletion('C3po ', 'cmdline'))
  eq({ '20' }, vim.fn.getcompletion('C3po 2', 'cmdline'))
  vim.cmd 'C3po nope'
  eq('Usage: :C3po [non-negative ID]', last_message())

  vim.cmd 'normal 20go'
  eq(20, select(2, c3po.current(c3po.scan())).id)
  vim.cmd 'normal 7go'
  eq(second, vim.api.nvim_buf_get_name(0))
  vim.cmd 'normal 1go'
  eq('No valid block with ID 1', last_message())
  eq(second, vim.api.nvim_buf_get_name(0))
  vim.cmd 'normal go'
  eq(first, vim.api.nvim_buf_get_name(0))
  eq({ 2, 0 }, vim.api.nvim_win_get_cursor(0))

  vim.cmd 'C3po 0'
  vim.cmd 'normal 2]a'
  eq(20, select(2, c3po.current(c3po.scan())).id)
  eq({ 1, 3 }, vim.api.nvim_win_get_cursor(0)) -- Land on the marker, after comment syntax.
  vim.cmd 'normal ]a'
  eq('No later C3PO block', last_message())
  vim.cmd 'normal 2[a'
  eq(first, vim.api.nvim_buf_get_name(0))
  vim.cmd 'normal [a'
  eq('No earlier C3PO block', last_message())
  vim.cmd 'normal! \15' -- <C-o> returns to the previous block.
  eq(20, select(2, c3po.current(c3po.scan())).id)

  vim.cmd 'C3po 0'
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  vim.cmd.C3po()
  eq('Outside C3PO blocks — 3 total', last_message())
  vim.cmd 'normal [a'
  eq(20, select(2, c3po.current(c3po.scan())).id)
  vim.cmd 'C3po 0'
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  vim.cmd 'normal ]a'
  eq({ 2, 0 }, vim.api.nvim_win_get_cursor(0))

  -- Unsaved additions, deletions, and shifted positions override disk contents.
  local live = file('live.txt', { 'no markers on disk' })
  vim.cmd.edit(vim.fn.fnameescape(live))
  vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.list_extend({ 'prefix' }, block(3)))
  eq({ 0, 3, 7, 20 }, ids(c3po.scan()))
  vim.o.hidden = false
  vim.cmd 'C3po 7' -- Must not discard or save the modified buffer.
  eq(second, vim.api.nvim_buf_get_name(0))
  vim.cmd 'C3po 3'
  eq(live, vim.api.nvim_buf_get_name(0))
  eq({ 2, 0 }, vim.api.nvim_win_get_cursor(0))
  eq({ 'no markers on disk' }, vim.fn.readfile(live))
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'removed' })
  eq({ 0, 7, 20 }, ids(c3po.scan()))

  -- Ignored buffers and buffers outside :pwd must not enter the index.
  local ignored = vim.fn.bufadd(tmp .. '/ignored.txt')
  vim.fn.bufload(ignored)
  local outside = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(outside, tmp .. '-outside.txt')
  vim.api.nvim_buf_set_lines(outside, 0, -1, false, block(97))
  eq({ 0, 7, 20 }, ids(c3po.scan()))

  file('malformed.txt', {
    marker('End', 1), -- Orphan End.
    marker('Start', 2),
    marker('End', 4), -- Mismatched ID.
    marker('Start', 5),
    marker('Start', 6),
    marker('End', 6),
    marker('End', 5), -- Nested.
    marker('Start', 8),
    marker('Start', 9),
    marker('End', 8),
    marker('End', 9), -- Overlapping.
    marker('Start', 10),
    marker('End', 10), -- Recovery after invalid regions.
    marker('Start', 11), -- Orphan Start.
  })
  file('duplicate.txt', block(7))
  blocks, warnings = c3po.scan()
  eq({ 0, 10, 20 }, ids(blocks))
  eq(9, #warnings)
  assert(table.concat(warnings, '\n'):find('malformed.txt:1:', 1, true))
  messages = {}
  vim.fn.getcompletion('C3po ', 'cmdline')
  eq({}, messages) -- Completion doesn't emit warnings.
  vim.cmd.C3po()
  eq(vim.log.levels.WARN, messages[1].level)
  assert(messages[1].message:find('duplicate c3po[7]', 1, true))

  -- No quickfix API was installed.
  eq(0, vim.fn.exists ':C3poList')
  eq({}, vim.fn.getqflist())

  vim.fn.mkdir(tmp .. '/empty')
  vim.cmd.cd(tmp .. '/empty')
  eq({}, c3po.scan())
  vim.cmd 'normal ]a'
  eq('No valid C3PO blocks found', last_message())

  local path = vim.env.PATH
  vim.env.PATH = tmp .. '/empty'
  vim.cmd.C3po()
  vim.env.PATH = path
  eq('C3PO requires ripgrep', last_message())
  eq(vim.log.levels.ERROR, messages[#messages].level)
end, debug.traceback)

vim.cmd.cd(root)
for _, buf in ipairs(vim.api.nvim_list_bufs()) do
  vim.api.nvim_buf_delete(buf, { force = true })
end
vim.fn.delete(tmp, 'rf')
if not ok then
  io.stderr:write(err .. '\n')
  vim.cmd 'cquit 1'
end
print 'C3PO tests passed'
vim.cmd 'qa!'
