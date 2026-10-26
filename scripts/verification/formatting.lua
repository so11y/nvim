-- Formatting must work without loading the LSP configuration.
vim.opt.rtp:prepend(vim.fn.getcwd())
vim.opt.rtp:append(vim.fn.stdpath('data') .. '/lazy/conform.nvim')
vim.env.PATH = vim.fn.stdpath('data')
    .. '/mason/bin'
    .. (vim.fn.has('win32') == 1 and ';' or ':')
    .. vim.env.PATH
vim.opt.undofile = false
local spec = require('modules.language.formatting')
require('conform').setup(spec.opts())
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

local other_filename = vim.fn.tempname() .. '.lua'
vim.fn.writefile({ 'local other={answer=44}' }, other_filename)
local other = vim.fn.bufadd(other_filename)
vim.fn.bufload(other)
vim.bo[other].filetype = 'lua'
vim.api.nvim_exec_autocmds('BufWritePre', { buffer = other, modeline = false })
assert(
    vim.api.nvim_buf_get_lines(other, 0, 1, false)[1]
        == 'local other = { answer = 44 }',
    'Save formatting targeted the current buffer instead of the event buffer'
)
assert(
    vim.api.nvim_get_current_line() == 'local manual = { answer = 43 }',
    'Formatting another buffer changed the current buffer'
)

vim.bo[other].filetype = 'text'
vim.api.nvim_buf_set_lines(other, 0, -1, false, { 'leave this = raw' })
vim.api.nvim_exec_autocmds('BufWritePre', { buffer = other, modeline = false })
require('modules.language.formatting.format').format(other)
assert(
    vim.api.nvim_buf_get_lines(other, 0, 1, false)[1] == 'leave this = raw',
    'An unconfigured filetype was formatted'
)
vim.api.nvim_buf_delete(other, { force = true })
vim.fn.delete(other_filename)
assert(
    not package.loaded['modules.language.lsp.setup'],
    'Formatting loaded the LSP configuration'
)
assert(vim.v.errmsg == '', vim.v.errmsg)
vim.api.nvim_buf_delete(0, { force = true })
vim.fn.delete(filename)
print(
    'PASS: save, manual, other-buffer and unconfigured-filetype formatting without LSP'
)
