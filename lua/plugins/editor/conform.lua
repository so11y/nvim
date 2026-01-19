return {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    keys = {
        {
            -- 按键：Alt + Shift + f (如果你按的是大写F) 或者 Alt + f
            "<A-F>", 
            function()
                require("conform").format({ lsp_fallback = false })
            end,
            mode = "n",
            desc = "Format buffer",
            silent = true
        },
    },
    opts = {
        formatters_by_ft = {
            lua = { "stylua" },
            vue = { "prettier" },
            typescript = { "prettier" },
            javascript = { "prettier" },
            css = { "prettier" },
            scss = { "prettier" },
            html = { "prettier" },
        },
        format_on_save = { timeout_ms = 1000, lsp_fallback = false },
    },
}
