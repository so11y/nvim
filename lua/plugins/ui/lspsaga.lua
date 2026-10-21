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
        vim.api.nvim_create_autocmd('FileType', {
            group = require('lspsaga').saga_augroup,
            pattern = 'sagarename',
            callback = function(event)
                vim.b[event.buf].completion = false
                for _, key in ipairs({ '<BS>', '<Del>' }) do
                    vim.keymap.set('s', key, '<C-g>"_c', { buffer = event.buf })
                end
            end,
        })
        vim.api.nvim_create_autocmd('ModeChanged', {
            group = require('lspsaga').saga_augroup,
            pattern = '*:[sS]',
            callback = function()
                if vim.bo.filetype == 'sagarename' then
                    -- Select-mode deletion and replacement use this register.
                    vim.api.nvim_feedkeys(vim.keycode('<C-r>_'), 'ni', false)
                end
            end,
        })
        local function highlight_float()
            local title =
                vim.api.nvim_get_hl(0, { name = 'FloatTitle', link = false })
            title.bg = vim.api.nvim_get_hl(
                0,
                { name = 'NormalFloat', link = false }
            ).bg
            vim.api.nvim_set_hl(0, 'SagaActionTitle', title)
            for group, target in pairs({
                SagaNormal = 'NormalFloat',
                SagaTitle = 'FloatTitle',
                RenameNormal = 'NormalFloat',
                SagaFinderFname = 'NormalFloat',
            }) do
                vim.api.nvim_set_hl(0, group, { link = target })
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
        local do_request = symbols.do_request
        -- A queued symbol refresh can outlive its buffer.
        symbols.do_request = function(self, buf, client_id)
            if not vim.api.nvim_buf_is_loaded(buf) then
                return
            end
            return do_request(self, buf, client_id)
        end
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
