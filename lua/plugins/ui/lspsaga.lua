return {
    'nvimdev/lspsaga.nvim',
    cmd = 'Lspsaga',
    event = 'LspAttach',
    keys = {
        { 'gd', '<cmd>Lspsaga finder def<CR>', desc = '转到定义' },
        { 'grr', '<cmd>Lspsaga finder ref<CR>', desc = '转到引用' },
        { 'gri', '<cmd>Lspsaga finder imp<CR>', desc = '转到实现' },
        { '<leader>co', '<cmd>Lspsaga outline<CR>', desc = '代码大纲' },
        { 'grn', '<cmd>Lspsaga rename<CR>', desc = '重命名' },
        {
            'gra',
            require('config.code_action').open,
            mode = { 'n', 'x' },
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
        finder = {
            keys = { toggle_or_open = '<CR>', quit = { 'q', '<Esc>' } },
        },
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
                'SagaText',
                'FloatTitle',
            }) do
                vim.api.nvim_set_hl(0, group, { link = 'NormalFloat' })
            end
            vim.api.nvim_set_hl(
                0,
                'SagaInCurrent',
                { link = 'SnacksIndentScope' }
            )
        end
        highlight_float()
        vim.api.nvim_create_autocmd('ColorScheme', {
            group = require('lspsaga').saga_augroup,
            callback = highlight_float,
        })
        local finder_box = require('lspsaga.finder.box')
        local indent_current = finder_box.indent_current
        finder_box.indent_current = function(inlevel)
            indent_current(inlevel)
            -- Keep inactive branches visible while preserving the active branch.
            for row = 0, vim.api.nvim_buf_line_count(0) - 1 do
                for col = 0, 4, 2 do
                    local group = 'SagaIndent' .. row .. col
                    if
                        vim.api.nvim_get_hl(0, { name = group, link = true }).link
                        ~= 'SagaInCurrent'
                    then
                        vim.api.nvim_set_hl(0, group, { link = 'SnacksIndent' })
                    end
                end
            end
        end
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
