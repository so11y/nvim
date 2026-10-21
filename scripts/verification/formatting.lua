-- Formatting must work without loading the LSP configuration.
vim.opt.rtp:prepend(vim.fn.getcwd())
vim.opt.rtp:append(vim.fn.stdpath('data') .. '/lazy/conform.nvim')
vim.env.PATH = vim.fn.stdpath('data')
    .. '/mason/bin'
    .. (vim.fn.has('win32') == 1 and ';' or ':')
    .. vim.env.PATH
vim.opt.undofile = false
local spec = require('plugins.completion.format')
spec.config(nil, spec.opts())
local filename = vim.fn.tempname() .. '.lua'
vim.fn.writefile({ 'local value={answer=42}' }, filename)
vim.cmd.edit(filename)
vim.bo.filetype = 'lua'
vim.cmd.write()
assert(
    vim.fn.readfile(filename)[1] == 'local value = { answer = 42 }',
    'Saving without LSP did not format the file'
)
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'local manual={answer=43}' })
spec.keys[1][2]()
assert(
    vim.api.nvim_get_current_line() == 'local manual = { answer = 43 }',
    'Manual formatting without LSP did not format the buffer'
)
assert(
    not package.loaded['config.lsp'],
    'Formatting loaded the LSP configuration'
)
assert(vim.v.errmsg == '', vim.v.errmsg)
vim.api.nvim_buf_delete(0, { force = true })
vim.fn.delete(filename)
print('PASS: save and manual formatting without LSP')
