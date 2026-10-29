-- Run with: nvim --headless -u NONE -i NONE -l scripts/verification/closed-file.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
for _, plugin in ipairs({
    'snacks.nvim',
    'buffer-reopen.nvim',
    'bufferline.nvim',
}) do
    vim.opt.rtp:append(vim.fn.stdpath('data') .. '/lazy/' .. plugin)
end
vim.o.hidden = true
vim.g.mapleader = ' '
require('config.keymaps')
local plugin = require('modules.tools.buffer-reopen')
plugin.config()
local mapping = plugin.keys[1]
vim.keymap.set('n', mapping[1], mapping[2], { desc = mapping.desc })
local function reopen()
    vim.api.nvim_feedkeys(' wr', 'xt', false)
end
local close
for _, key in ipairs(require('modules.tools.snacks')[1].keys) do
    if key[1] == '<A-w>' then
        close = key[2]
    end
end
local options = require('modules.ui.bufferline').opts().options
local history = require('buffer-reopen.store').closed_buffers
assert(vim.fn.maparg('<leader>bt', 'n') == '')
assert(vim.fn.maparg('<C-S-t>', 'n') == '')

vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'abc' })
vim.api.nvim_feedkeys(vim.keycode('sZ<Esc>'), 'xt', false)
assert(
    vim.api.nvim_get_current_line() == 'Zbc',
    's did not replace one character'
)
vim.bo.modified = false

local directory = vim.fn.tempname()
vim.fn.mkdir(directory)
local alpha = directory .. '/first %# file.txt'
local beta = directory .. '/second.txt'
vim.fn.writefile({ 'alpha' }, alpha)
vim.fn.writefile({ 'beta' }, beta)
vim.cmd.edit(vim.fn.fnameescape(alpha))
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'discarded edit' })
local confirm = vim.fn.confirm
vim.fn.confirm = function()
    return 3
end
options.close_command(0)
assert(
    vim.fs.normalize(vim.api.nvim_buf_get_name(0)) == vim.fs.normalize(alpha)
)
assert(#history == 0, 'Cancelled close created a history entry')

vim.fn.confirm = function()
    return 2
end
close()
assert(#history == 1, 'Alt+w did not record the closed file')
vim.cmd.edit(vim.fn.fnameescape(beta))
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'saved edit' })
vim.fn.confirm = function()
    return 1
end
options.right_mouse_command(0)
vim.fn.confirm = confirm
assert(vim.fn.readfile(beta)[1] == 'saved edit', 'Save-before-close failed')
assert(#history == 2, 'Tag close did not record the closed file')

-- Named utility buffers and unnamed editor buffers must not enter file history.
for _, kind in ipairs({ 'nofile', 'help', 'quickfix', 'prompt' }) do
    local buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(buf, directory .. '/' .. kind)
    vim.bo[buf].buftype = kind
    vim.api.nvim_buf_delete(buf, { force = true })
end
vim.api.nvim_buf_delete(vim.api.nvim_create_buf(true, false), { force = true })
assert(#history == 2, 'Non-file buffer entered history')

reopen()
assert(vim.fs.normalize(vim.api.nvim_buf_get_name(0)) == vim.fs.normalize(beta))
assert(vim.api.nvim_get_current_line() == 'saved edit')
reopen()
assert(
    vim.fs.normalize(vim.api.nvim_buf_get_name(0)) == vim.fs.normalize(alpha)
)
assert(vim.api.nvim_get_current_line() == 'alpha', 'Discarded changes returned')
assert(#history == 0, 'Repeated reopen did not consume history')
assert(#vim.api.nvim_tabpage_list_wins(0) == 1, 'Reopen changed window layout')

vim.cmd.vsplit()
close()
assert(#history == 0, 'Closing a split recorded an open buffer')
assert(vim.bo.buflisted, 'Split close removed the file from the buffer list')

local action
package.loaded.vscode = {
    action = function(name)
        action = name
    end,
}
require('environment.vscode.keymaps')
vim.fn.maparg('<leader>wr', 'n', false, true).callback()
assert(action == 'workbench.action.reopenClosedEditor')
vim.fn.delete(alpha)
vim.fn.delete(beta)
vim.fn.delete(directory, 'd')
assert(vim.v.errmsg == '', vim.v.errmsg)
print(
    'PASS: file history, repeated reopen, special names, save/discard/cancel, VS Code'
)
vim.cmd('qa!')
