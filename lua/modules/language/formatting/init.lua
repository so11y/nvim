return {
    'stevearc/conform.nvim',
    version = '^9',
    event = { 'BufReadPre', 'BufNewFile' },
    cmd = 'ConformInfo',
    keys = {
        {
            '<A-F>',
            function()
                require('modules.language.formatting.format').format()
            end,
            mode = { 'n', 'i' },
            desc = '格式化代码',
        },
    },
    opts = function()
        local format = require('modules.language.formatting.format')
        local oxfmt = require('modules.language.formatting.oxfmt')
        local filetypes = vim.tbl_filter(function(ft)
            return format.formatters[ft].name == 'oxfmt'
        end, vim.tbl_keys(format.formatters))
        vim.lsp.config('oxfmt', { cmd = oxfmt.cmd, filetypes = filetypes })
        vim.api.nvim_create_autocmd('FileType', {
            group = vim.api.nvim_create_augroup('nvim.oxfmt', { clear = true }),
            pattern = filetypes,
            callback = function(event)
                oxfmt.start(event.buf)
            end,
        })
        return {
            formatters_by_ft = format.formatters,
            format_on_save = format.format_options,
            notify_on_error = false,
            notify_no_formatters = false,
            default_format_opts = {
                timeout_ms = 2000,
                quiet = true,
            },
        }
    end,
}
