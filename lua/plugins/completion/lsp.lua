return {
    {
        'neovim/nvim-lspconfig',
        version = '^2',
        event = { 'BufReadPre', 'BufNewFile', 'FileType' },
        init = function()
            if not vim.g.vscode then
                require('config.lsp').setup_keymaps()
            end
        end,
        config = function()
            require('config.lsp').setup()
        end,
    },
    {
        'mrcjkb/rustaceanvim',
        version = '^9',
        ft = 'rust',
        dependencies = { 'neovim/nvim-lspconfig' },
        init = function()
            vim.g.rustaceanvim = function()
                return {
                    dap = { autoload_configurations = false },
                    server = {
                        capabilities = require('config.lsp').capabilities,
                        on_attach = function(_, bufnr)
                            vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
                        end,
                        default_settings = {
                            ['rust-analyzer'] = {
                                inlayHints = {
                                    bindingModeHints = { enable = true },
                                    chainingHints = { enable = true },
                                    closingBraceHints = {
                                        enable = true,
                                        minLines = 25,
                                    },
                                    closureReturnTypeHints = {
                                        enable = 'always',
                                    },
                                    lifetimeElisionHints = { enable = 'never' },
                                    parameterHints = { enable = true },
                                    reborrowHints = { enable = 'never' },
                                    typeHints = { enable = true },
                                },
                            },
                        },
                    },
                }
            end
        end,
    },
}
