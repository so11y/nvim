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
        vim.lsp.config('oxfmt', {
            cmd = oxfmt.cmd,
            before_init = function(params, config)
                params.initializationOptions = {
                    {
                        workspaceUri = vim.uri_from_fname(config.root_dir),
                        options = vim.empty_dict(),
                    },
                }
            end,
            filetypes = vim.tbl_filter(function(ft)
                return format.formatters[ft].name == 'oxfmt'
            end, vim.tbl_keys(format.formatters)),
            root_dir = function(bufnr, on_dir)
                local filename = vim.api.nvim_buf_get_name(bufnr)
                on_dir(
                    vim.fs.root(
                        filename,
                        { { 'package.json', '.git', 'node_modules' } }
                    )
                        or vim.fs.root(filename, function(name)
                            return name == '.editorconfig'
                                or vim.tbl_contains(oxfmt.config_files, name)
                                or vim.tbl_contains(oxfmt.prettier_files, name)
                        end)
                        or vim.fs.dirname(filename)
                )
            end,
        })
        vim.lsp.enable('oxfmt')
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
