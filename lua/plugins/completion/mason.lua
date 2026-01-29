return {
    "williamboman/mason.nvim",
    optional = true,
    opts_extend = {"ensure_installed"},
    opts = {
        ensure_installed = {"vue-language-server", "vtsls", "eslint-lsp", "prettierd"}
    }
}
