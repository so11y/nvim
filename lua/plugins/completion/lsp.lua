return { -- 1. Mason & LSP 相关
{
    "williamboman/mason.nvim",
    opts = {
        ui = {
            border = "rounded"
        }
    }
}, {
    "williamboman/mason-lspconfig.nvim",
    dependencies = {"williamboman/mason.nvim"},
    opts = {
        ensure_installed = {"eslint", "html", "cssls" -- "emmet_ls"
        },
        automatic_installation = true
    }
}, -- 2. LSPConfig 主配置
{
    "neovim/nvim-lspconfig",
    dependencies = {"williamboman/mason-lspconfig.nvim", "hrsh7th/cmp-nvim-lsp"},
    opts = {
        servers = {
            html = {},
            cssls = {},
            eslint = {}
        },
        -- 诊断配置移到这里
        diagnostics = {
            virtual_text = {
                prefix = "●"
            },
            underline = true,
            update_in_insert = false,
            severity_sort = true
        }
    },
    config = function()

        vim.api.nvim_create_autocmd("LspAttach", {
            group = vim.api.nvim_create_augroup("UserLspConfig", {}),
            callback = function(ev)
            end
        })
    end
}}
