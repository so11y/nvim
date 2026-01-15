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
        ensure_installed = {"vue-language-server", "vtsls", "eslint", "html", "cssls", "emmet_ls"},
        automatic_installation = true
    }
}, -- 2. LSPConfig 主配置
{
    "neovim/nvim-lspconfig",
    dependencies = {"williamboman/mason-lspconfig.nvim", "hrsh7th/cmp-nvim-lsp"},
    config = function()
        local lspconfig = require("lspconfig")
        local capabilities = require("cmp_nvim_lsp").default_capabilities()

        -- 1. 准备路径 (使用最稳妥的拼接方式)
        local mason_path = vim.fn.stdpath("data") .. "/mason"
        local vue_language_server_path = mason_path .. "/packages/vue-language-server/node_modules/@vue/language-server"

        -- [关键] 告诉 Volar TypeScript 库在哪里 (解决补全的核心)
        -- 根据 mason 安装的 vtsls 路径推导 typescript 路径
        local typescript_path = mason_path .. "/packages/vtsls/node_modules/typescript/lib"

        -- 2. [TypeScript 配置 - vtsls]
        -- 负责 JS/TS 部分 (包括 Vue 里的 script)
        lspconfig.vtsls.setup({
            capabilities = capabilities,
            settings = {
                vtsls = {
                    tsserver = {
                        globalPlugins = {{
                            name = "@vue/typescript-plugin",
                            location = vue_language_server_path,
                            languages = {"vue"},
                            configNamespace = "typescript",
                            enableForWorkspaceTypeScriptVersions = true
                        }}
                    },
                    experimental = {
                        completion = {
                            enableServerSideFuzzyMatch = true
                        }
                    }
                }
            },
            filetypes = {"typescript", "javascript", "javascriptreact", "typescriptreact", "vue"}
        })

        -- 3. [Vue Volar 配置]
        -- 负责 HTML 模板和 CSS 部分
        lspconfig.volar.setup({
            capabilities = capabilities,
            init_options = {
                vue = {
                    hybridMode = true
                },
                typescript = {
                    tsdk = typescript_path
                }
            }
        })

        lspconfig.html.setup({
            capabilities = capabilities
        })
        lspconfig.cssls.setup({
            capabilities = capabilities
        })
        lspconfig.emmet_ls.setup({
            capabilities = capabilities
        })
        lspconfig.eslint.setup({
            capabilities = capabilities,
            on_attach = function(client, bufnr)
                vim.api.nvim_create_autocmd("BufWritePre", {
                    buffer = bufnr,
                    command = "EslintFixAll"
                })
            end
        })

        -- 5. 诊断配置
        vim.diagnostic.config({
            virtual_text = {
                prefix = "●"
            },
            signs = true,
            underline = true,
            update_in_insert = false,
            severity_sort = true
        })

        -- 6. 快捷键 (简化版，先确保功能正常)
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
                vim.keymap.set({"n", "v"}, "<leader>ca", function()
                    require("tiny-code-action").code_action()
                end, opts)
            end
        })
    end
}}
