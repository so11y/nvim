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
    dependencies = {"williamboman/mason-lspconfig.nvim" -- "hrsh7th/cmp-nvim-lsp"
    },
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
    config = function(_, opts)
        vim.opt.updatetime = 200
        vim.api.nvim_create_autocmd("LspAttach", {
            callback = function(args)

                vim.diagnostic.config({
                    virtual_text = true,
                    underline = true,
                    severity_sort = true
                })

                local client = vim.lsp.get_client_by_id(args.data.client_id)
                if client and client.server_capabilities.documentHighlightProvider then
                    local group = vim.api.nvim_create_augroup("lsp_document_highlight", {
                        clear = true
                    })

                    vim.api.nvim_create_autocmd({"CursorHold", "CursorHoldI"}, {
                        group = group,
                        buffer = args.buf,
                        callback = function()
                            local node = vim.treesitter.get_node()
                            if not node then
                                return
                            end

                            local node_type = node:type()

                            local ignore_types = {"tag_name", "attribute_name", "start_tag", "end_tag", "element"}

                            if vim.tbl_contains(ignore_types, node_type) then
                                vim.lsp.buf.clear_references()
                            else
                                vim.lsp.buf.document_highlight()
                            end
                        end
                    })

                    -- 移动光标立刻清除高亮
                    vim.api.nvim_create_autocmd({"CursorMoved", "CursorMovedI"}, {
                        group = group,
                        buffer = args.buf,
                        callback = vim.lsp.buf.clear_references
                    })
                end
            end
        })
    end
}}
