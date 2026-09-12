vim.pack.add {
  { src = 'https://github.com/techwizrd/render-latex.nvim' },
}

require('render_latex').setup {
  render = {
    -- preset = 'presentation',
    equation_label_format = '(%d)',
  },
}

vim.opt.conceallevel = 2
vim.opt.concealcursor = "nc"
