return {
    "stevearc/conform.nvim",
    event = {"BufWritePre"},
    keys = {{
        -- 按键：Alt + Shift + f (如果你按的是大写F) 或者 Alt + f
        "<A-F>",
        function()
            require("conform").format({
                lsp_fallback = false
            })
        end,
        mode = {"n", "i"},
        desc = "Format buffer",
        silent = true
    }},
    opts = {
        formatters_by_ft = {
            lua = {"stylua"},
            vue = {"prettierd"},
            typescript = {"prettierd"},
            javascript = {"prettierd"},
            css = {"prettierd"},
            scss = {"prettierd"},
            html = {"prettierd"},
            json = {"prettierd"}
        },
        format_on_save = {
            timeout_ms = 2000,
            lsp_fallback = false
        }
    }
}
