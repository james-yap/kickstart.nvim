-- Diffview + open current line on the GitHub PR (`<leader>gP` in a view pane).
-- Command completion is intentionally emptied so huge monorepos don't hang on Tab.

vim.pack.add { 'https://github.com/sindrets/diffview.nvim' }

local function command_output(command, cwd)
  local result = vim.system(command, { cwd = cwd, text = true }):wait()
  if result.code ~= 0 then
    local stderr = vim.trim(result.stderr or '')
    local stdout = vim.trim(result.stdout or '')
    local message = stderr ~= '' and stderr or stdout ~= '' and stdout or 'Command failed'
    return nil, message
  end

  return vim.trim(result.stdout or '')
end

local function github_repo(root)
  local remotes, err = command_output({ 'git', 'remote', '-v' }, root)
  if not remotes then return nil, err end

  for line in remotes:gmatch '[^\r\n]+' do
    local url = line:match '^%S+%s+(%S+)%s+%(fetch%)$'
    local owner, repo
    if url then
      owner, repo = url:match 'github%.com[:/]([^/]+)/([^/]+)$'
    end
    if owner and repo then return owner .. '/' .. repo:gsub('%.git$', '') end
  end

  return nil, 'No GitHub fetch remote found'
end

local function open_pr_line()
  local view = require('diffview.lib').get_current_view()
  if not view or not view.cur_entry then
    vim.notify('No active Diffview file', vim.log.levels.ERROR)
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local current_file
  for _, file in ipairs(view.cur_entry.layout:files()) do
    if file:is_valid() and file.bufnr == bufnr then
      current_file = file
      break
    end
  end

  if not current_file then
    vim.notify('Cursor is not in a Diffview file pane', vim.log.levels.ERROR)
    return
  end

  local side = ({ a = 'L', b = 'R' })[current_file.symbol]
  if not side then
    vim.notify('Only two-way Diffview panes can open PR lines', vim.log.levels.ERROR)
    return
  end

  local root = view.adapter.ctx.toplevel
  local repo, repo_err = github_repo(root)
  if not repo then
    vim.notify(repo_err, vim.log.levels.ERROR)
    return
  end

  local branch, branch_err = command_output({ 'git', 'branch', '--show-current' }, root)
  if not branch or branch == '' then
    vim.notify(branch_err or 'Cannot find a pull request from a detached HEAD', vim.log.levels.ERROR)
    return
  end

  local pr_url, pr_err = command_output({ 'gh', 'pr', 'view', branch, '--repo', repo, '--json', 'url', '--jq', '.url' }, root)
  if not pr_url then
    vim.notify(pr_err, vim.log.levels.ERROR)
    return
  end

  local url = ('%s/files#diff-%s%s%d'):format(pr_url, vim.fn.sha256(view.cur_entry.path), side, vim.api.nvim_win_get_cursor(0)[1])
  vim.ui.open(url)
end

-- Example: :DiffviewOpen main...feature -- . ':!**/tests/**' ':!**/translations/**'
require('diffview').setup {
  file_panel = {
    win_config = {
      position = 'bottom',
      height = 15,
    },
  },
  keymaps = {
    view = {
      { 'n', '<leader>gP', open_pr_line, { desc = 'Open line in GitHub PR' } },
    },
  },
}

local diffview = require 'diffview'
diffview.completers.DiffviewOpen = function() return {} end
diffview.completers.DiffviewFileHistory = function() return {} end
