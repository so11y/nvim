local M = {
    servers = {
        'cssls',
        'emmet_language_server',
        'eslint',
        'html',
        'jsonls',
        'lua_ls',
        'tag_fix',
        'vtsls',
        'vue_ls',
    },
}

function M.setup_keymaps()
    local function show_diagnostic(_, bufnr)
        vim.diagnostic.open_float({
            bufnr = bufnr,
            scope = 'cursor',
            focus = false,
        })
    end
    require('utils.repeatable').map_jump(']x', '[x', function()
        vim.diagnostic.jump({ count = 1, on_jump = show_diagnostic })
    end, function()
        vim.diagnostic.jump({ count = -1, on_jump = show_diagnostic })
    end, '下一个诊断', '上一个诊断')
end

function M.setup()
    M.capabilities = require('blink.cmp').get_lsp_capabilities()
    vim.lsp.config('*', { capabilities = M.capabilities })
    vim.lsp.config('vtsls', require('lsp.vtsls'))
    vim.lsp.config('vue_ls', require('lsp.vue_ls'))
    vim.lsp.config(
        'emmet_language_server',
        require('lsp.emmet_language_server')
    )
    vim.lsp.config('tag_fix', {
        cmd = require('lsp.tag_fix').cmd,
        filetypes = { 'html', 'vue', 'javascriptreact', 'typescriptreact' },
        offset_encoding = 'utf-8',
    })
    vim.lsp.config('eslint', {
        settings = { format = false },
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
                    require('editing.linked_tags').attach(client, ev.buf)
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
end

return M
