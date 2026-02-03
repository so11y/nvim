return {{
    "williamboman/mason.nvim",
    cmd = "Mason",
    opts = {}
}, {
    "williamboman/mason-lspconfig.nvim",
    dependencies = {"williamboman/mason.nvim"},
    event = "VeryLazy",
    opts = {
        ensure_installed = {
            -- "eslint", 
        "html", "cssls", "vue_ls", "vtsls", "jsonls"},
        automatic_installation = true
    }
}}
