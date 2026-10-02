local M = {}

local prettierd = {
    formatCommand = 'prettierd "${INPUT}"',
    formatStdin = true,
    env = {
        'PRETTIERD_DEFAULT_CONFIG='
            .. vim.fn.stdpath('config')
            .. '/format/prettier.json',
    },
    rootMarkers = { 'package.json', '.git/' },
}
local stylua = {
    formatCommand = 'stylua --search-parent-directories --stdin-filepath "${INPUT}" -',
    formatStdin = true,
    rootMarkers = { 'stylua.toml', '.stylua.toml', '.git/' },
}

M.languages = { lua = { stylua } }
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
    M.languages[ft] = { prettierd }
end

function M.client(bufnr, method)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local ft = vim.bo[bufnr].filetype
    local name = M.languages[ft] and 'efm' or ft == 'rust' and 'rust-analyzer'
    if name then
        return vim.lsp.get_clients({
            bufnr = bufnr,
            name = name,
            method = method or 'textDocument/formatting',
        })[1]
    end
end

function M.label(bufnr)
    local ft = vim.bo[bufnr or 0].filetype
    if ft == 'rust' then
        return 'rustfmt'
    end
    local tools = M.languages[ft]
    return tools and (ft == 'lua' and 'stylua' or 'prettierd') or ''
end

function M.format(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    if M.label(bufnr) == '' then
        return
    end
    local client = M.client(bufnr)
    if not client then
        vim.notify(
            'LSP formatter is not ready for this buffer: ' .. M.label(bufnr),
            vim.log.levels.WARN
        )
        return
    end
    local params = vim.api.nvim_buf_call(bufnr, function()
        return vim.lsp.util.make_formatting_params()
    end)
    local reply, err =
        client:request_sync('textDocument/formatting', params, 2000, bufnr)
    local failure = err or (reply.err and reply.err.message)
    if failure then
        vim.notify(
            'LSP formatting ('
                .. client.name
                .. '): '
                .. failure:gsub('\27%[[0-9;]*m', ''),
            vim.log.levels.WARN
        )
    elseif reply.result then
        vim.lsp.util.apply_text_edits(
            reply.result,
            bufnr,
            client.offset_encoding
        )
    end
end

return M
