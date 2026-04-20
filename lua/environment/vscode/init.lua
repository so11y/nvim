-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  VSCode 环境统一出口
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local M = {}

M.disabled = require('environment.vscode.disabled')

-- 交给 lazy.nvim 的 import 模块路径
M.spec = 'environment.vscode.plugins'

function M.setup()
    require('environment.vscode.keymaps')
end

return M
