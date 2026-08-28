-- Personal keymaps (loaded from custom/ at the end of init.lua).

-- File path with cursor position or visual selection range.
local function path_with_position()
  local path = vim.fn.expand '%:p'
  local mode = vim.fn.mode()

  if mode == 'v' or mode == 'V' or mode == '\22' then
    local start_pos = vim.fn.getpos 'v'
    local end_pos = vim.fn.getpos '.'
    local start_row, start_col = start_pos[2], start_pos[3]
    local end_row, end_col = end_pos[2], end_pos[3]

    -- Normalize so the start position precedes the end position.
    if start_row > end_row or (start_row == end_row and start_col > end_col) then
      start_row, start_col, end_row, end_col = end_row, end_col, start_row, start_col
    end

    if mode == 'V' then
      return string.format('%s:L%d-L%d', path, start_row, end_row)
    elseif start_row == end_row then
      return string.format('%s:L%d:C%d-C%d', path, start_row, start_col, end_col)
    end
    return string.format('%s:L%d:C%d-L%d:C%d', path, start_row, start_col, end_row, end_col)
  end

  local cursor = vim.fn.getpos '.'
  return string.format('%s:L%d:C%d', path, cursor[2], cursor[3])
end

local function copy_path_with_position()
  local result = path_with_position()
  vim.fn.setreg('+', result)
  vim.notify('Copied path+position to clipboard', vim.log.levels.INFO)
end

vim.keymap.set({ 'n', 'x' }, '<leader>cp', copy_path_with_position, {
  desc = 'Copy file path with range or position',
})

-- Copy only the current file path.
vim.keymap.set('n', '<leader>cP', function()
  local path = vim.fn.expand '%:p'
  vim.fn.setreg('+', path)
  vim.notify('Copied file path to clipboard', vim.log.levels.INFO)
end, { desc = 'Copy current file path' })

-- Floating OMP agent terminal (reuses one session; hide with <C-q>).
local omp_term = { buf = nil, win = nil }

local function omp_float_config()
  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.85)
  return {
    relative = 'editor',
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2) - 1,
    col = math.floor((vim.o.columns - width) / 2),
    style = 'minimal',
    border = 'rounded',
    title = ' OMP ',
    title_pos = 'center',
  }
end

-- Floats default to NormalFloat→Pmenu (light gray here). Terminal default
-- cells use the window bg, so pin this float to Normal (editor dark/light).
local function style_omp_float(win)
  if not (win and vim.api.nvim_win_is_valid(win)) then
    return
  end
  vim.api.nvim_set_option_value(
    'winhighlight',
    'Normal:Normal,NormalFloat:Normal,FloatBorder:WinSeparator,FloatTitle:Normal',
    { win = win }
  )
end

local function hide_omp()
  if omp_term.win and vim.api.nvim_win_is_valid(omp_term.win) then
    vim.api.nvim_win_close(omp_term.win, true)
  end
  omp_term.win = nil
end

local function open_omp()
  if omp_term.win and vim.api.nvim_win_is_valid(omp_term.win) then
    vim.api.nvim_set_current_win(omp_term.win)
    style_omp_float(omp_term.win)
    vim.cmd 'startinsert'
    return
  end

  if omp_term.buf and vim.api.nvim_buf_is_valid(omp_term.buf) then
    omp_term.win = vim.api.nvim_open_win(omp_term.buf, true, omp_float_config())
    style_omp_float(omp_term.win)
    vim.cmd 'startinsert'
    return
  end

  omp_term.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[omp_term.buf].bufhidden = 'hide'
  omp_term.win = vim.api.nvim_open_win(omp_term.buf, true, omp_float_config())
  style_omp_float(omp_term.win)

  -- Nested :terminal OSC 11 is flaky; seed COLORFGBG from Neovim's background.
  local colorfgbg = vim.o.background == 'light' and '0;15' or '15;0'
  vim.fn.jobstart({ 'omp' }, {
    term = true,
    cwd = vim.fn.getcwd(),
    env = {
      COLORFGBG = colorfgbg,
    },
    on_exit = function()
      vim.schedule(function()
        hide_omp()
        if omp_term.buf and vim.api.nvim_buf_is_valid(omp_term.buf) then
          vim.api.nvim_buf_delete(omp_term.buf, { force = true })
        end
        omp_term.buf = nil
      end)
    end,
  })

  -- Leader chords are unreliable in terminal mode; use a direct hide key.
  vim.keymap.set('t', '<C-q>', hide_omp, {
    buffer = omp_term.buf,
    silent = true,
    desc = 'Hide OMP float',
  })

  vim.cmd 'startinsert'
end

vim.keymap.set('n', '<leader>oa', open_omp, {
  desc = 'OMP floating terminal',
})
