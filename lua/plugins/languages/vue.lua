return { -- 1. 语法高亮：扩展 Treesitter
{
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = {
        ensure_installed = {"vue", "typescript", "javascript", "css", "scss", "html"}
    },
    opts_extend = {"ensure_installed"}
}, -- 2. 自动安装：扩展 Mason
{
    "williamboman/mason.nvim",
    optional = true,
    opts_extend = {"ensure_installed"},
    opts = {
        ensure_installed = {"vue-language-server", "vtsls", "eslint-lsp", "prettierd"}

    }
}, {
    "stevearc/conform.nvim",
    optional = true,
    opts_extend = {"ensure_installed"},
    opts = {
        formatters_by_ft = {
            vue = {
                "prettierd",
                "prettier",
                stop_after_first = true
            },
            javascript = {
                "prettierd",
                "prettier",
                stop_after_first = true
            },
            typescript = {
                "prettierd",
                "prettier",
                stop_after_first = true
            }
        }
    }
}, {
    "neovim/nvim-lspconfig",
    optional = true,
    opts_extend = {"ensure_installed"},
    opts = function(_, opts)
        local vue_language_server_path = vim.fn.stdpath('data') .. "/mason/packages/vue-language-server"

        local vue_plugin = {
            name = '@vue/typescript-plugin',
            location = vue_language_server_path .. "/node_modules/@vue/language-server",
            languages = {'vue'},
            configNamespace = 'typescript'
        }

        vim.lsp.config('vtsls', {
            settings = {
                vtsls = {
                    tsserver = {
                        globalPlugins = {vue_plugin}
                    }
                }
            },
            filetypes = {'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue'}
        })
        -- vim.lsp.enable('vtsls')
        vim.lsp.enable('vue_ls')
    end
}}
