-- C3PO block navigation
-- Scope: existing files under :pwd, including hidden files, respecting rg's
-- ignore rules. Loaded buffers replace disk contents (including unsaved edits).
-- Blocks are ordered by their numeric ID, not by file or line number.
-- ]a / [a: next/previous, with counts, without wrapping. Outside a block they
-- start at the first/last block. :C3po [ID] jumps to an ID (with completion);
-- :C3po alone reports the current block and total number of valid blocks.
-- {ID}go jumps directly to that ID; bare go jumps to ID 0.
-- New files must be saved once to enter the index. No background scanning.
local M = {}

local function notify(message, level) vim.notify(message, level or vim.log.levels.INFO, { title = 'C3PO' }) end

local function markers(lines)
  local result = {}
  for _, line in ipairs(lines) do
    local offset = 1
    while true do
      local first, last, kind, id = line.text:find('(%a+): c3po%[(%d+)%]', offset)
      if not first then break end
      if kind == 'Start' or kind == 'End' then result[#result + 1] = { kind = kind, id = tonumber(id), lnum = line.lnum, col = first } end
      offset = last + 1
    end
  end
  return result
end

-- Nested regions are rejected as a whole. An unmatched/mismatched End closes
-- the current level so later, independent valid blocks can still be recovered.
local function parse(path, lines, blocks, warnings)
  local stack, start, invalid = {}, nil, false
  local function warn(marker, message) warnings[#warnings + 1] = string.format('%s:%d: %s', path, marker.lnum, message) end
  for _, marker in ipairs(markers(lines)) do
    if marker.kind == 'Start' then
      if #stack == 0 then
        start, invalid = marker, false
      else
        invalid = true
        warn(marker, 'nested block; ignoring the entire region')
      end
      stack[#stack + 1] = marker
    elseif #stack == 0 then
      warn(marker, string.format('End without Start for c3po[%d]', marker.id))
    else
      local opening = table.remove(stack)
      if opening.id ~= marker.id then
        invalid = true
        warn(marker, string.format('End c3po[%d] does not match Start c3po[%d] at line %d', marker.id, opening.id, opening.lnum))
      end
      if #stack == 0 and not invalid then blocks[#blocks + 1] = { id = start.id, path = path, lnum = start.lnum, col = start.col, end_lnum = marker.lnum } end
    end
  end
  for _, opening in ipairs(stack) do
    warn(opening, string.format('Start without End for c3po[%d]', opening.id))
  end
end

local function rg(cwd, args)
  local command = { 'rg', '--no-config', '--hidden', '--glob', '!**/.git/**' }
  vim.list_extend(command, args)
  local result = vim.system(command, { cwd = cwd, text = true }):wait(10000)
  if result.code ~= 0 and result.code ~= 1 then error(vim.trim(result.stderr or '') ~= '' and vim.trim(result.stderr) or 'ripgrep failed or timed out', 0) end
  return result.stdout or ''
end

-- Rebuild on demand: no stale line numbers, watchers, or warnings while typing.
-- Public for callers that want to inspect the current block without moving.
function M.scan()
  if vim.fn.executable 'rg' ~= 1 then error('C3PO requires ripgrep', 0) end
  local cwd = vim.fn.getcwd()
  local files = {}
  local function absolute(path) return vim.fs.normalize(vim.fs.joinpath(cwd, path)) end

  -- Enumerate separately so buffers with no markers on disk can introduce new
  -- blocks without admitting ignored files into the workspace index.
  for _, path in ipairs(vim.split(rg(cwd, { '--files', '--null', '--', '.' }), '\0', { trimempty = true })) do
    files[absolute(path)] = {}
  end
  local output = rg(cwd, { '--json', '--', '(Start|End): c3po\\[[0-9]+\\]', '.' })
  for _, line in ipairs(vim.split(output, '\n', { trimempty = true })) do
    local event = vim.json.decode(line)
    if event.type == 'match' then
      local data = event.data
      -- rg uses base64 for non-UTF-8 paths/lines.
      local path = data.path.text or vim.base64.decode(data.path.bytes)
      local text = data.lines.text or vim.base64.decode(data.lines.bytes)
      local entries = files[absolute(path)]
      if entries then entries[#entries + 1] = { lnum = data.line_number, text = text } end
    end
  end
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == '' then
      local path = vim.fs.normalize(vim.api.nvim_buf_get_name(buf))
      if files[path] then
        local lines = {}
        for lnum, text in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
          lines[#lines + 1] = { lnum = lnum, text = text }
        end
        files[path] = lines
      end
    end
  end

  local blocks, warnings = {}, {}
  for path, lines in pairs(files) do
    parse(path, lines, blocks, warnings)
  end
  local by_id = {}
  for _, block in ipairs(blocks) do
    by_id[block.id] = by_id[block.id] or {}
    table.insert(by_id[block.id], block)
  end
  local unique = {}
  for _, block in ipairs(blocks) do
    if #by_id[block.id] == 1 then
      unique[#unique + 1] = block
    else
      warnings[#warnings + 1] = string.format('%s:%d: duplicate c3po[%d]; excluding this ID', block.path, block.lnum, block.id)
    end
  end
  table.sort(unique, function(a, b) return a.id < b.id end)
  table.sort(warnings)
  return unique, warnings
end

function M.current(blocks)
  local path = vim.fs.normalize(vim.api.nvim_buf_get_name(0))
  local line = vim.api.nvim_win_get_cursor(0)[1]
  for index, block in ipairs(blocks) do
    if block.path == path and line >= block.lnum and line <= block.end_lnum then return index, block end
  end
end

local function scan(silent)
  local ok, blocks, warnings = pcall(M.scan)
  if not ok then
    if not silent then notify(blocks, vim.log.levels.ERROR) end
    return
  end
  if not silent and #warnings > 0 then notify('Ignoring invalid C3PO blocks:\n' .. table.concat(warnings, '\n'), vim.log.levels.WARN) end
  return blocks
end

local function report(blocks, index)
  if index then
    notify(string.format('c3po[%d] — block %d of %d', blocks[index].id, index, #blocks))
  else
    notify(string.format('Outside C3PO blocks — %d total', #blocks))
  end
end

local function jump(blocks, index)
  local block = blocks[index]
  -- :hide buffer retains modified buffers without writing them.
  -- Preserve a jumplist entry so <C-o> can take us back, and reveal folded blocks.
  vim.cmd "normal! m'"
  local buf = vim.fn.bufadd(block.path)
  local ok, err = pcall(function()
    vim.cmd { cmd = 'buffer', args = { tostring(buf) }, mods = { hide = true } }
    vim.api.nvim_win_set_cursor(0, { block.lnum, block.col - 1 })
    vim.cmd 'normal! zv'
  end)
  if not ok then
    notify(tostring(err), vim.log.levels.ERROR)
    return
  end
  report(blocks, index)
end

function M.move(direction, count)
  local blocks = scan()
  if not blocks then return end
  if #blocks == 0 then
    notify 'No valid C3PO blocks found'
    return
  end
  local index = M.current(blocks) or (direction > 0 and 0 or #blocks + 1)
  local target = index + direction * (count or 1)
  if target < 1 or target > #blocks then
    notify(direction > 0 and 'No later C3PO block' or 'No earlier C3PO block', vim.log.levels.WARN)
    return
  end
  jump(blocks, target)
end

vim.api.nvim_create_user_command('C3po', function(opts)
  if opts.args ~= '' and not opts.args:match '^%d+$' then
    notify('Usage: :C3po [non-negative ID]', vim.log.levels.ERROR)
    return
  end
  local blocks = scan()
  if not blocks then return end
  if opts.args == '' then
    report(blocks, M.current(blocks))
    return
  end
  local id = tonumber(opts.args)
  for index, block in ipairs(blocks) do
    if block.id == id then
      jump(blocks, index)
      return
    end
  end
  notify(string.format('No valid block with ID %s', opts.args), vim.log.levels.WARN)
end, {
  nargs = '?',
  desc = 'Report current C3PO block/total, or jump to an ID',
  complete = function(prefix)
    local ids = {}
    for _, block in ipairs(scan(true) or {}) do
      local id = tostring(block.id)
      if vim.startswith(id, prefix) then ids[#ids + 1] = id end
    end
    return ids
  end,
})

vim.keymap.set('n', 'go', function() vim.cmd.C3po(tostring(vim.v.count)) end, { desc = 'Go to C3PO block ID (default 0)' })
vim.keymap.set('n', ']a', function() M.move(1, vim.v.count1) end, { desc = 'Next C3PO block' })
vim.keymap.set('n', '[a', function() M.move(-1, vim.v.count1) end, { desc = 'Previous C3PO block' })

return M
