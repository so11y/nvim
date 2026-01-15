-- 自动安装 lazy.nvim 如果不存在
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({"git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable",
                   lazypath})
end
vim.opt.rtp:prepend(lazypath)

-- 加载 lazy，并告诉它去 lua/plugins 目录找插件
require("lazy").setup({
    spec = { -- 1. 扫描 lua/plugins 目录下的所有文件
    {
        import = "plugins"
    }, -- 2. 特别重要：确保它也扫描你新建的 languages 文件夹
    {
        import = "plugins.languages"
    }},
    change_detection = {
        notify = false -- 关闭每次修改配置时的通知
    }
})
