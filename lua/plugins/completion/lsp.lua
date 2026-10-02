return {
    {
        'neovim/nvim-lspconfig',
        version = '^2',
        event = { 'BufReadPre', 'BufNewFile', 'FileType' },
        dependencies = { 'mason-org/mason-lspconfig.nvim' },
        keys = {
            {
                '<A-F>',
                function()
                    require('config.format').format()
                end,
                mode = { 'n', 'i' },
                desc = 'Format buffer with LSP',
            },
        },
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
                        cmd = {
                            vim.fn.systemlist({
                                'rustup',
                                'which',
                                '--toolchain',
                                require('config.runtime').versions.rust,
                                'rust-analyzer',
                            })[1],
                        },
                        cmd_env = {
                            PATH = vim.fs.dirname(vim.fn.exepath('rustup'))
                                .. (vim.fn.has('win32') == 1 and ';' or ':')
                                .. vim.env.PATH,
                        },
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
