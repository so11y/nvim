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

        -- Keep the whole file in the preview; selecting a symbol only moves its cursor.
        local outline = getmetatable(require('lspsaga.symbol.outline'))
        function outline:float_preview()
            local api = vim.api
            api.nvim_buf_set_lines(
                self.rbufnr,
                0,
                -1,
                false,
                api.nvim_buf_get_lines(self.main_buf, 0, -1, false)
            )
            vim.bo[self.rbufnr].modifiable = false
            vim.wo[self.rwinid].number = true
            vim.wo[self.rwinid].relativenumber = false
            vim.wo[self.rwinid].cursorline = true
            vim.wo[self.rwinid].foldenable = false

            vim.keymap.set('n', '<C-l>', function()
                api.nvim_set_current_win(self.rwinid)
            end, { buffer = self.bufnr, desc = '进入代码预览' })
            vim.keymap.set('n', '<C-h>', function()
                api.nvim_set_current_win(self.winid)
            end, {
                buffer = self.rbufnr,
                desc = '返回代码大纲',
            })
            for _, key in ipairs(opts.outline.keys.quit) do
                vim.keymap.set('n', key, function()
                    self:outline()
                end, {
                    buffer = self.rbufnr,
                    desc = '关闭代码大纲',
                })
            end

            api.nvim_create_autocmd('CursorMoved', {
                group = 'outline',
                buffer = self.bufnr,
                callback = function()
                    local node = require('lspsaga.slist').find_node(
                        self.list,
                        api.nvim_win_get_cursor(self.winid)[1]
                    )
                    if not node then
                        return
                    end
                    local row = node.value.selectionRange.start.line + 1
                    api.nvim_win_set_cursor(self.rwinid, { row, 0 })
                    api.nvim_win_call(self.rwinid, function()
                        vim.cmd('normal! zz')
                    end)
                end,
            })
        end
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
