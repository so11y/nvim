if not vim.g.vscode then
    return { disabled = {}, specs = {} }
end

require('environment.vscode.keymaps')

-- Mason itself is disabled in the host; keep its installed CLI tools available.
vim.env.PATH = vim.fn.stdpath('data')
    .. '/mason/bin'
    .. (vim.fn.has('win32') == 1 and ';' or ':')
    .. vim.env.PATH

return {
    disabled = require('environment.vscode.disabled'),
    specs = { { import = 'environment.vscode.plugins' } },
}
