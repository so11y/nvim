-- 自动安装 lazy.nvim 如果不存在
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({"git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable",
                   lazypath})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    spec = {{
        import = "plugins"
    }, {
        import = "plugins.languages"
    }, {
        import = "plugins.completion"
    }, {
        import = "plugins.editor"
    }, {
        import = "plugins.tool"
    }, {
        import = "plugins.ui"
    }},
    change_detection = {
        notify = false
    }
})
