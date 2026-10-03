local M = {
    servers = {
        'cssls',
        'efm',
        'eslint',
        'html',
        'jsonls',
        'lua_ls',
        'tag_fix',
        'vtsls',
        'vue_ls',
    },
}

function M.setup()
    M.capabilities = require('blink.cmp').get_lsp_capabilities()
    vim.lsp.config('*', { capabilities = M.capabilities })
    vim.lsp.config('vtsls', require('lsp.vtsls'))
    vim.lsp.config('vue_ls', require('lsp.vue_ls'))
    vim.lsp.config('tag_fix', {
        cmd = require('lsp.tag_fix').cmd,
        filetypes = { 'html', 'vue' },
        offset_encoding = 'utf-8',
    })
    vim.lsp.config('eslint', {
        settings = { format = false },
    })
    local format = require('config.format')
    vim.lsp.config('efm', {
        filetypes = vim.tbl_keys(format.languages),
        init_options = {
            documentFormatting = true,
            documentRangeFormatting = false,
        },
        settings = { languages = format.languages },
        root_dir = function(bufnr, on_dir)
            local name = vim.api.nvim_buf_get_name(bufnr)
            if name ~= '' then
                on_dir(
                    vim.fs.root(bufnr, { 'package.json', '.git' })
                        or vim.fs.dirname(name)
                )
            end
        end,
    })
    vim.lsp.enable(M.servers)

    vim.diagnostic.config({
        virtual_text = false,
        signs = {
            text = {
                [vim.diagnostic.severity.ERROR] = '󰧞',
                [vim.diagnostic.severity.WARN] = '󰧞',
                [vim.diagnostic.severity.INFO] = '󰧞',
                [vim.diagnostic.severity.HINT] = '󱐋',
            },
        },
        underline = true,
        severity_sort = true,
        update_in_insert = false,
    })

    local group = vim.api.nvim_create_augroup('config.lsp', { clear = true })
    local highlights =
        vim.api.nvim_create_augroup('config.lsp.highlights', { clear = true })
    vim.api.nvim_create_autocmd('WinEnter', {
        group = group,
        callback = function()
            local win = vim.api.nvim_get_current_win()
            if vim.w[win]['textDocument/hover'] then
                vim.wo[win].concealcursor = 'n'
            end
        end,
    })
    vim.api.nvim_create_autocmd('LspAttach', {
        group = group,
        callback = function(ev)
            local client = vim.lsp.get_client_by_id(ev.data.client_id)
            if
                (client.name == 'vue_ls' or client.name == 'html')
                and client:supports_method('textDocument/linkedEditingRange')
            then
                vim.schedule(function()
                    require('config.linked_tags').attach(client, ev.buf)
                end)
            end
            if
                not client:supports_method('textDocument/documentHighlight')
                or #vim.api.nvim_get_autocmds({
                        group = highlights,
                        buffer = ev.buf,
                    })
                    > 0
            then
                return
            end
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
                group = highlights,
                buffer = ev.buf,
                callback = function()
                    local node = vim.treesitter.get_node()
                    if
                        node
                        and vim.tbl_contains({
                            'tag_name',
                            'attribute_name',
                            'start_tag',
                            'end_tag',
                            'element',
                        }, node:type())
                    then
                        vim.lsp.buf.clear_references()
                    else
                        vim.lsp.buf.document_highlight()
                    end
                end,
            })
            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
                group = highlights,
                buffer = ev.buf,
                callback = vim.lsp.buf.clear_references,
            })
        end,
    })
    vim.api.nvim_create_autocmd('LspDetach', {
        group = group,
        callback = function(ev)
            for _, client in
                ipairs(vim.lsp.get_clients({
                    bufnr = ev.buf,
                    method = 'textDocument/documentHighlight',
                }))
            do
                if client.id ~= ev.data.client_id then
                    return
                end
            end
            vim.api.nvim_clear_autocmds({ group = highlights, buffer = ev.buf })
            vim.lsp.buf.clear_references()
        end,
    })
    vim.api.nvim_create_autocmd('BufWritePre', {
        group = group,
        callback = function(ev)
            if vim.bo[ev.buf].buftype == '' then
                format.format(ev.buf)
            end
        end,
    })
end

return M
