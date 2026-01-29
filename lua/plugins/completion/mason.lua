return {{
    "williamboman/mason.nvim",
    opts = {}
}, {
    "williamboman/mason-lspconfig.nvim",
    dependencies = {"williamboman/mason.nvim"},
    opts = {
        ensure_installed = {"eslint", "html", "cssls", "vue_ls", "vtsls"},
        automatic_installation = true
    }
}}
