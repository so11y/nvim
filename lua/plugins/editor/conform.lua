return {
    "stevearc/conform.nvim",
    event = {"BufWritePre"},
    keys = {{
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
            json = {"prettierd"},
            rust = {"rustfmt"}
        },
        format_on_save = {
            timeout_ms = 2000,
            lsp_fallback = false
        }
    }
}
