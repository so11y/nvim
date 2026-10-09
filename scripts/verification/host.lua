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
}) do
    assert(not config.plugins[name], 'Host loaded ' .. name)
    blocked[#blocked + 1] = name
end
for _, mapping in ipairs({
    { 'n', '<A-F>' },
    { 'n', '<A-o>' },
    { 'n', 'za' },
    { 'x', '<CR>' },
    { 'x', '<BS>' },
}) do
    assert(vim.fn.maparg(mapping[2], mapping[1], false, true).callback)()
end
vim.wait(300)
assert(#vim.lsp.get_clients() == 0)
return {
    appname = vim.env.NVIM_APPNAME,
    config = vim.fn.stdpath('config'),
    native_clients = #vim.lsp.get_clients(),
    blocked = blocked,
    extension_runtime = vim.g.vscode_neovim_runtime,
    errmsg = vim.v.errmsg,
    messages = vim.api.nvim_exec2('messages', { output = true }).output,
}
