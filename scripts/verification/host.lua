local config = require('lazy.core.config')
local blocked = {}
for _, name in ipairs({
    'nvim-lspconfig',
    'mason.nvim',
    'rustaceanvim',
    'blink.cmp',
    'blink.indent',
    'nvim-dap',
    'snacks.nvim',
    'glance.nvim',
    'neoscroll.nvim',
    'neogit',
    'codediff.nvim',
    'vim-visual-multi',
}) do
    assert(not config.plugins[name], 'Host loaded ' .. name)
    blocked[#blocked + 1] = name
end
local actions = {}
for _, mapping in ipairs({
    { 'n', '<A-F>', 'editor.action.formatDocument' },
    { 'n', '<leader>co', 'outline.focus' },
    { 'n', 'za', 'editor.toggleFold' },
    { 'x', '<CR>', 'editor.action.smartSelect.expand' },
    { 'x', '<BS>', 'editor.action.smartSelect.shrink' },
    { 'n', 'grr', 'editor.action.goToReferences' },
    { 'n', 'gri', 'editor.action.peekImplementation' },
    { 'n', 'grt', 'editor.action.peekTypeDefinition' },
    { 'n', 'grn', 'editor.action.rename' },
    { 'x', 'gra', 'editor.action.quickFix' },
    { 'n', '<leader>ch', 'editor.action.showHover' },
    { 'n', '<leader>ff', 'workbench.action.quickOpen' },
    { 'n', '<leader>sg', 'workbench.action.findInFiles' },
    { 'x', '<leader>sr', 'editor.action.startFindReplaceAction' },
    { 'n', '<leader>wv', 'workbench.action.splitEditorRight' },
    { 'n', '<leader>ws', 'workbench.action.splitEditorDown' },
}) do
    assert(vim.fn.maparg(mapping[2], mapping[1], false, true).callback)()
    actions[#actions + 1] = mapping[3]
end
local vscode = require('vscode')
local original_eval, original_call = vscode.eval, vscode.call
local targets, history_calls = {}, {}
vscode.eval = function(code, opts, timeout)
    targets[#targets + 1] = vim.deepcopy(opts.args)
    return original_eval(code, opts, timeout)
end
vscode.call = function(name, ...)
    history_calls[name] = (history_calls[name] or 0) + 1
    return original_call(name, ...)
end
local original_buffer = vim.api.nvim_get_current_buf()
local navigation_buffer = vim.api.nvim_create_buf(false, false)
vim.api.nvim_buf_set_name(
    navigation_buffer,
    vim.fn.tempname() .. ' navigation.txt'
)
vim.api.nvim_set_current_buf(navigation_buffer)
local lines = {}
for index = 1, 20 do
    lines[index] = 'line ' .. index
end
lines[15] = '😀中文 target'
vim.api.nvim_buf_set_lines(navigation_buffer, 0, -1, false, lines)
local function feed(keys)
    vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes(keys, true, false, true),
        'xt',
        false
    )
end
for _, motion in ipairs({
    { keys = '5j', source = 1, target = 5 },
    { keys = '4j', source = 6, target = 9 },
    { keys = '4k', source = 10, target = 5 },
}) do
    vim.api.nvim_win_set_cursor(0, { motion.source, 0 })
    feed(motion.keys)
    local target = targets[#targets]
    assert(
        target.line == motion.target and target.character == 0,
        motion.keys .. ' sent the wrong target'
    )
end
local target_count = #targets
vim.api.nvim_win_set_cursor(0, { 1, 0 })
feed('1j')
assert(vim.api.nvim_win_get_cursor(0)[1] == 2, '1j did not move one line')
feed('1k')
assert(vim.api.nvim_win_get_cursor(0)[1] == 1, '1k did not move one line')
assert(#targets == target_count, 'Single-line motion created a jump')
require('environment.vscode.navigation').jump(navigation_buffer, { 15, 11 })
local unicode_target = targets[#targets]
assert(
    unicode_target.line == 14 and unicode_target.character == 5,
    'Jump target is not UTF-16'
)
for _, command in ipairs({
    { keys = '2<A-u>', action = 'workbench.action.navigateBack' },
    { keys = '2<A-i>', action = 'workbench.action.navigateForward' },
}) do
    feed(command.keys)
    assert(
        history_calls[command.action] == 2,
        command.keys .. ' lost its count'
    )
    actions[#actions + 1] = command.action
end
vscode.eval, vscode.call = original_eval, original_call
vim.api.nvim_set_current_buf(original_buffer)
vim.api.nvim_buf_delete(navigation_buffer, { force = true })

assert(vim.fn.maparg('<leader>cr', 'n') == '')
assert(vim.fn.maparg('<leader>ca', 'n') == '')
assert(vim.fn.maparg('mcc', 'n') == '')
assert(vim.fn.maparg('J', 'n') == '<C-D>')
assert(vim.fn.maparg('K', 'n') == '<C-U>')
vim.fn.maparg('<Esc>', 'n', false, true).callback()
vim.wait(300)
assert(#vim.lsp.get_clients() == 0)
return {
    appname = vim.env.NVIM_APPNAME,
    config = vim.fn.stdpath('config'),
    native_clients = #vim.lsp.get_clients(),
    blocked = blocked,
    expected_actions = actions,
    extension_runtime = vim.g.vscode_neovim_runtime,
    errmsg = vim.v.errmsg,
    messages = vim.api.nvim_exec2('messages', { output = true }).output,
}
