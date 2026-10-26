if vim.g.vscode then
    return
end

vim.opt.foldcolumn = '1'
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.opt.foldtext = '' -- 原样显示折叠首行，保留语法高亮。
vim.opt.fillchars:append({
    fold = ' ',
    foldopen = '▾',
    foldsep = '│',
    foldclose = '▸',
})
