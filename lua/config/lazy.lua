-- 自动安装 lazy.nvim 如果不存在
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
    local clone = vim.system({
        'git',
        'clone',
        '--filter=blob:none',
        'https://github.com/folke/lazy.nvim.git',
        '--branch=stable',
        lazypath,
    }, { text = true }):wait()
    assert(clone.code == 0, 'lazy.nvim bootstrap failed: ' .. clone.stderr)
    local lock = vim.json.decode(
        table.concat(
            vim.fn.readfile(vim.fn.stdpath('config') .. '/lazy-lock.json'),
            '\n'
        )
    )
    local checkout = vim.system(
        { 'git', '-C', lazypath, 'checkout', lock['lazy.nvim'].commit },
        { text = true }
    ):wait()
    assert(checkout.code == 0, checkout.stderr)
end
vim.opt.rtp:prepend(lazypath)

local env = require('environment')

local disabled = {}
for _, v in ipairs(env.disabled) do
    disabled[v] = true
end

require('lazy').setup({
    install = { missing = false },
    spec = vim.list_extend({
        { import = 'plugins.completion' },
        { import = 'plugins.editor' },
        { import = 'plugins.tool' },
        { import = 'plugins.ui' },
    }, env.specs),
    defaults = {
        cond = function(plugin)
            return not disabled[plugin[1]]
        end,
    },
    change_detection = {
        notify = false,
    },
    performance = {
        -- Windows cache filenames encode full paths and can exceed MAX_PATH.
        cache = { enabled = vim.fn.has('win32') ~= 1 },
    },
})

-- Missing plugins stay installable, but their events must not block the Lazy UI.
local function sync_handlers()
    local handler = require('lazy.core.handler')
    for _, plugin in pairs(require('lazy.core.config').plugins) do
        if plugin._.installed then
            handler.enable(plugin)
        else
            handler.disable(plugin)
        end
    end
end
sync_handlers()
vim.api.nvim_create_autocmd('User', {
    group = vim.api.nvim_create_augroup('config.lazy', { clear = true }),
    pattern = 'LazyInstall',
    callback = sync_handlers,
})
