-- 自动安装 lazy.nvim 如果不存在
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        'git',
        'clone',
        '--filter=blob:none',
        'https://github.com/folke/lazy.nvim.git',
        '--branch=stable',
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

local disabled = {}
for _, v in ipairs(vim.g.vscode_disabled_plugins or {}) do
    disabled[v] = true
end

require('lazy').setup({
    spec = {
        {
            import = 'plugins.completion',
        },
        {
            import = 'plugins.editor',
        },
        {
            import = 'plugins.tool',
        },
        {
            import = 'plugins.ui',
        },
    },
    defaults = {
        cond = function(plugin)
            return not disabled[plugin[1]]
        end,
    },
    change_detection = {
        notify = false,
    },
})
