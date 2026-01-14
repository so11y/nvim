return {
    -- 1. Mason & LSP 相关
    {
        "williamboman/mason.nvim",
        opts = {
            ui = { border = "rounded" }
        },
    },
    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = { "williamboman/mason.nvim" },
        opts = {
            ensure_installed = {
                "vue-language-server",
                "vtsls",
                "eslint",
                "html",
                "cssls",
                "emmet_ls",
            },
            automatic_installation = true,
        },
    },

    -- 2. LSPConfig 主配置
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "williamboman/mason-lspconfig.nvim",
            "hrsh7th/cmp-nvim-lsp",
        },
        config = function()
            local lspconfig = require("lspconfig")
            local capabilities = require("cmp_nvim_lsp").default_capabilities()

            -- 诊断配置
            vim.diagnostic.config({
                virtual_text = { prefix = "●" },
                signs = true,
                underline = true,
                update_in_insert = false,
                severity_sort = true,
            })

            -- 快捷键定义 (LspAttach)
            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("UserLspConfig", {}),
                callback = function(ev)
                    local opts = { buffer = ev.buf }
                    vim.keymap.set("n", "<Space>k", vim.lsp.buf.hover, opts)
                    vim.keymap.set("n", "gd", function()
                        local params = vim.lsp.util.make_position_params()
                        vim.lsp.buf_request(0, 'textDocument/definition', params, function(err, result)
                            if err then return end
                            if not result or vim.tbl_isempty(result) then return end
                            if vim.tbl_count(result) == 1 then
                                vim.lsp.util.jump_to_location(result[1], 'utf-8', true)
                            else
                                vim.cmd('Telescope lsp_definitions')
                            end
                        end)
                    end, opts)
                    vim.keymap.set("n", "gr", "<cmd>Telescope lsp_references<cr>", opts)
                    vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, opts)
                    vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
                end,
            })

            -- [Vue Volar 配置]
            lspconfig.vue_ls.setup({
                capabilities = capabilities,
                init_options = {
                    vue = {
                        hybridMode = false,
                    },
                },
            })

            -- [TypeScript 配置 - vtsls (使用 vtsls 替代 ts_ls)]
            local vue_language_server_path = vim.fn.stdpath("data") .. "/mason/packages/vue-language-server/node_modules/@vue/language-server"

            local vue_plugin = {
                name = "@vue/typescript-plugin",
                location = vue_language_server_path,
                languages = { "vue" },
            }

            lspconfig.vtsls.setup({
                capabilities = capabilities,
                settings = {
                    vtsls = {
                        tsserver = {
                            globalPlugins = { vue_plugin },
                        },
                    },
                },
                filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
            })

            -- [HTML/CSS/ESLint]
            lspconfig.html.setup({
                capabilities = capabilities,
                cmd = { "vscode-html-language-server", "--stdio" },
            })
            lspconfig.cssls.setup({ capabilities = capabilities })
            lspconfig.eslint.setup({
                capabilities = capabilities,
                on_attach = function(client, bufnr)
                    vim.api.nvim_create_autocmd("BufWritePre", {
                        buffer = bufnr,
                        command = "EslintFixAll",
                    })
                end,
            })
        end,
    },

    -- 3. 格式化配置 (Conform)
    {
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
    },
}