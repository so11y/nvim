local M = {
    formatters = {
        lua = { 'stylua' },
        rust = { lsp_format = 'prefer', name = 'rust-analyzer' },
    },
}

for _, ft in ipairs({
    'vue',
    'javascript',
    'javascriptreact',
    'typescript',
    'typescriptreact',
    'css',
    'scss',
    'html',
    'json',
    'jsonc',
    'markdown',
}) do
    M.formatters[ft] = { 'prettierd' }
end

function M.info(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local ft = vim.bo[bufnr].filetype
    local formatters = M.formatters[ft]
    if not formatters then
        return
    end
    local conform = require('conform')
    if ft == 'rust' then
        local _, lsp = conform.list_formatters_to_run(bufnr)
        return { name = 'rustfmt', available = lsp }
    end
    return conform.get_formatter_info(formatters[1], bufnr)
end

function M.format_options(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local ft = vim.bo[bufnr].filetype
    local formatters = M.formatters[ft]
    if not formatters then
        return
    end
    local name = ft == 'rust' and 'rustfmt' or formatters[1]
    return {
        bufnr = bufnr,
    }, function(err)
        if err then
            vim.notify(
                'Formatting (' .. name .. '): ' .. err:gsub('\27%[[0-9;]*m', ''),
                vim.log.levels.WARN
            )
        end
    end
end

function M.format(bufnr)
    local opts, callback = M.format_options(bufnr)
    if opts then
        require('conform').format(opts, callback)
    end
end

return M
