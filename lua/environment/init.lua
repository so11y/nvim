if not vim.g.vscode then
    return { disabled = {}, specs = {} }
end

require('environment.vscode.keymaps')

return {
    disabled = require('environment.vscode.disabled'),
    specs = { { import = 'environment.vscode.plugins' } },
}
