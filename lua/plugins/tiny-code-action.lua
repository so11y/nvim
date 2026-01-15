return {{
    "rachartier/tiny-code-action.nvim",
    dependencies = {{"nvim-lua/plenary.nvim"}, {"nvim-web-devicons"}},
    event = "LspAttach",
    opts = {
        lsp_timeout = 3000,
        backend = "vim"
    },
    config = function()
        require("tiny-code-action").setup({
            backend = "vim" -- 可以是 "vim", "delta", "difftastic"
        })

        vim.api.nvim_create_autocmd("FileType", {
            pattern = "tiny-code-action", -- 这是该插件窗口的文件类型
            callback = function()
                local opts = {
                    buffer = true,
                    nowait = true
                }
                vim.keymap.set("n", "<A-j>", "j", opts)
                vim.keymap.set("n", "<A-k>", "k", opts)
                vim.keymap.set("n", "<Esc>", "q", opts)
            end
        })
    end
}}
