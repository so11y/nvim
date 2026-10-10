local config = require('lazy.core.config')
local blocked = {}
for _, name in ipairs({
    'nvim-lspconfig',
    'mason.nvim',
    'mason-lspconfig.nvim',
    'rustaceanvim',
    'blink.cmp',
    'nvim-dap',
    'snacks.nvim',
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
assert(vim.fn.maparg('<leader>cr', 'n') == '')
assert(vim.fn.maparg('<leader>ca', 'n') == '')
assert(vim.fn.maparg('mcc', 'n') == '')
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
