return {
    -- 1. Mason: 负责下载 TS, Vue, ESLint 等服务器
    {
        "williamboman/mason.nvim",
        opts = {},
    },

    -- 2. Mason LSP Config: 自动启动 LSP 服务器
    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = { "williamboman/mason.nvim" },
        opts = {
            ensure_installed = {
                "volar",
                "tsserver",
                "eslint",
                "html",
                "cssls",
            },
            automatic_installation = true,
        },
    },

    -- 3. LSP Config: 配置服务器
    {
        "neovim/nvim-lspconfig",
        dependencies = { "williamboman/mason-lspconfig.nvim" },
        config = function()
            local lspconfig = require("lspconfig")

            -- ==========================================
            -- 实时诊断显示配置
            -- ==========================================
            vim.diagnostic.config({
                virtual_text = true,        -- 代码中显示错误
                signs = true,               -- 行号显示错误图标
                underline = true,           -- 下划线标记
                update_in_insert = false,   -- 插入模式不实时更新
                severity_sort = true,       -- 按严重程度排序
            })

            -- 在行号处显示错误图标
            local signs = {
                Error = " ",
                Warn = " ",
                Hint = " ",
                Info = " ",
            }
            for type, icon in pairs(signs) do
                vim.fn.sign_define("DiagnosticSign" .. type, {
                    text = icon,
                    texthl = "DiagnosticSign" .. type,
                    numhl = "DiagnosticSign" .. type,
                })
            end

            -- ==========================================
            -- 在这里统一配置快捷键 (当 LSP 连接到文件时执行)
            -- ==========================================
            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("UserLspConfig", {}),
                callback = function(ev)
                    local opts = { buffer = ev.buf }
                    -- Space + k: 显示悬浮提示 (Hover)
                    vim.keymap.set("n", "<leader>k", vim.lsp.buf.hover, { desc = "LSP Hover", buffer = ev.buf })

                    -- Space + c + a: 代码操作 (使用 Telescope 显示)
                    vim.keymap.set({ "n", "v" }, "<leader>ca", "<cmd>Telescope lsp_code_actions<cr>", { desc = "Code Action", buffer = ev.buf })

                    -- Space + c + r: 重命名 (Rename)
                    vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, { desc = "Rename", buffer = ev.buf })

                    -- gd: 跳转到定义
                    vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to Definition", buffer = ev.buf })

                    -- gr: 查找引用 (使用 Telescope 弹窗显示)
                    vim.keymap.set("n", "gr", "<cmd>Telescope lsp_references<cr>", { desc = "References", buffer = ev.buf })
                end,
            })

            -- TypeScript / JavaScript
            lspconfig.ts_ls.setup({
                init_options = {
                    plugins = {
                        {
                            name = "@vue/typescript-plugin",
                            location = vim.fn.stdpath("data") .. "/mason/packages/vue-language-server/node_modules/@vue/language-server",
                            languages = { "vue" },
                        },
                    },
                },
            })

            -- Vue (Volar)
            lspconfig.volar.setup({
                filetypes = { "vue" },
            })

            -- HTML & CSS
            lspconfig.html.setup({})
            lspconfig.cssls.setup({})

            -- ESLint (保存时自动修复)
            lspconfig.eslint.setup({
                on_attach = function(client, buf)
                    vim.api.nvim_create_autocmd("BufWritePre", {
                        buffer = buf,
                        command = "EslintFixAll",
                    })
                end,
            })
        end,
    },

    -- 3. 自动格式化 (Conform.nvim)
    {
        "stevearc/conform.nvim",
        event = { "BufWritePre" },
        cmd = { "ConformInfo" },
        keys = {
            {
                -- Alt + Shift + F 格式化
                "<A-F>",
                function()
                    require("conform").format({ async = true, lsp_fallback = true })
                end,
                mode = { "n", "v" },
                desc = "Format Document",
            },
        },
        opts = {
            formatters_by_ft = {
                javascript = { "prettier" },
                typescript = { "prettier" },
                vue = { "prettier" },
                css = { "prettier" },
                html = { "prettier" },
                json = { "prettier" },
                lua = { "stylua" },
            },
            -- 保存时自动格式化
            format_on_save = { timeout_ms = 500, lsp_fallback = true },
        },
    },
}