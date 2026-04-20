-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  运行环境入口：按当前宿主分发对应配置
--  统一导出给 init.lua / config.lazy 使用
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local M = {
    disabled = {}, -- 需要禁用的插件名列表
    specs = {}     -- 需要追加的 lazy spec（import 形式）
}

local function register(env)
    env.setup()
    vim.list_extend(M.disabled, env.disabled or {})
    if env.spec then
        table.insert(M.specs, { import = env.spec })
    end
end

if vim.g.vscode then
    register(require('environment.vscode'))
end

-- 预留：if vim.g.neovide then register(require('environment.neovide')) end

return M
