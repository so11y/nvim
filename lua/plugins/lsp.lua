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
            -- 1. 在这里显式禁用 vue_ls，确保它哪怕安装了也不许动
            vue_ls = {
                enabled = false
            },
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
                local opts = {
                    buffer = ev.buf
                }

                -- 这里的 gd 先用默认的，排除自定义函数报错的可能性
                vim.keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<cr>", opts)
                vim.keymap.set("n", "gr", "<cmd>Telescope lsp_references<cr>", opts)
                vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, opts)

                local ft = vim.bo.filetype -- 获取当前文件的类型

                if ft == "vue" then
                    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
                else
                    vim.keymap.set({"n", "v"}, "<leader>ca", function()
                        require("tiny-code-action").code_action()
                    end, opts)
                end
            end
        })
    end
}}
