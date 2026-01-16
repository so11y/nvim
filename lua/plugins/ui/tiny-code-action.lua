return {
    "rachartier/tiny-code-action.nvim",
    dependencies = {"nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons"},
    event = "LspAttach",
    opts = {
        backend = "vim", -- 预览后端
        picker = "buffer", -- 【关键】使用精简的缓冲区选择器界面
        lsp_timeout = 3000
    }
}
