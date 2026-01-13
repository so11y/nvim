return {
    "folke/tokyonight.nvim",
    lazy = false, -- 启动时加载
    priority = 1000, -- 优先加载，确保配色最先应用
    config = function()
        vim.cmd([[colorscheme tokyonight]])
    end,
}