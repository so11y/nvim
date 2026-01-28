return {
    "rachartier/tiny-code-action.nvim",
    dependencies = {"nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons"},
    event = "LspAttach",
    opts = {
        backend = "vim", -- 预览后端
        picker = {
            "buffer",
            opts = {
                auto_preview = true,
                height = 5, -- 限制只显示 5 个条目
                keymaps = {
                    preview = "K",
                    select = "<Tab>",
                    close = {"q", "<Esc>"},
                    preview_close = {"q", "<Esc>"}
                },
                group_icon = " └"
            }

        },
        lsp_timeout = 3000
    }
}
