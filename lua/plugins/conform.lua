return {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
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
        format_on_save = { timeout_ms = 1000, lsp_fallback = true },
    },
}
