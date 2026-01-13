-- 自动安装 lazy.nvim 如果不存在
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- 加载 lazy，并告诉它去 lua/plugins 目录找插件
require("lazy").setup("plugins", {
    change_detection = {
        notify = false, -- 关闭每次修改配置时的通知
    },
})