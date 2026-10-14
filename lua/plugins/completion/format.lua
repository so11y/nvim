return {
    'stevearc/conform.nvim',
    version = '^9',
    event = { 'BufReadPre', 'BufNewFile' },
    cmd = 'ConformInfo',
    opts = function()
        return {
            formatters_by_ft = require('config.format').formatters,
            notify_on_error = false,
            notify_no_formatters = false,
            default_format_opts = {
                timeout_ms = 2000,
            },
            formatters = {
                prettierd = {
                    env = {
                        PRETTIERD_DEFAULT_CONFIG = vim.fn.stdpath('config')
                            .. '/format/prettier.json',
                    },
                },
            },
        }
    end,
}
