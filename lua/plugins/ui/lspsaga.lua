return {
    'nvimdev/lspsaga.nvim',
    cmd = 'Lspsaga',
    event = 'LspAttach',
    keys = {
        { '<leader>co', '<cmd>Lspsaga outline<CR>', desc = '代码大纲' },
        { 'grn', '<cmd>Lspsaga rename<CR>', desc = '重命名' },
        {
            'gra',
            '<cmd>Lspsaga code_action<CR>',
            desc = '代码操作',
        },
    },
    opts = {
        ui = {
            button = { '', '' },
            lines = { '└', '├', '│', '─', '┌' },
        },
        lightbulb = { enable = false },
        symbol_in_winbar = { enable = false },
        rename = { keys = { quit = { '<Esc>', '<C-c>' } } },
        outline = {
            layout = 'float',
            keys = { jump = '<CR>', quit = { 'q', '<Esc>' } },
        },
        code_action = {
            keys = {
                quit = { 'q', '<Esc>' },
                exec = { '<CR>', '<Tab>' },
            },
        },
    },
    config = function(_, opts)
        require('lspsaga').setup(opts)
        local function highlight_float()
            for _, group in ipairs({
                'SagaActionTitle',
                'SagaTitle',
                'RenameNormal',
                'SagaFinderFname',
                'FloatTitle',
            }) do
                vim.api.nvim_set_hl(0, group, { link = 'NormalFloat' })
            end
        end
        highlight_float()
        vim.api.nvim_create_autocmd('ColorScheme', {
            group = require('lspsaga').saga_augroup,
            callback = highlight_float,
        })
        -- This version has no option to disable code action previews.
        require('lspsaga.codeaction.preview').action_preview = function() end
        local symbols = require('lspsaga.symbol.head')
        local group = 'LspsagaSymbols'
        -- Vue document symbols come from vue_ls; vtsls returns no outline.
        vim.api.nvim_clear_autocmds({ group = group, event = 'LspAttach' })
        vim.api.nvim_create_autocmd('LspAttach', {
            group = group,
            callback = function(event)
                local client = vim.lsp.get_client_by_id(event.data.client_id)
                if
                    symbols[event.buf]
                    or not client:supports_method('textDocument/documentSymbol')
                    or (
                        vim.bo[event.buf].filetype == 'vue'
                        and client.name ~= 'vue_ls'
                    )
                then
                    return
                end
                symbols:do_request(event.buf, client.id)
                symbols:buf_watcher(event.buf, group)
            end,
        })
    end,
}
