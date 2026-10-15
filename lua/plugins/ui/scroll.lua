return {
    'petertriho/nvim-scrollbar',
    event = 'BufReadPost',
    config = function()
        local scrollbar = require('scrollbar')
        scrollbar.setup({
            excluded_filetypes = vim.list_extend(
                require('scrollbar.config').get().excluded_filetypes,
                { 'code_action_menu' }
            ),
            show = true,
            show_in_active_only = false,
            set_highlights = true,
            folds = 1000, -- handle folds, set to 0 to disable
            handle = {
                text = ' ',
                color = '#45475A',
                blend = 20,
                hide_if_all_visible = true,
            },
            marks = {
                Cursor = {
                    text = '-',
                    priority = 0,
                },
            },
            handlers = {
                cursor = false,
                diagnostic = true,
                gitsigns = false,
                handle = true,
                search = false,
            },
        })
        -- Coalesce scroll frames without losing the final position or other windows.
        vim.api.nvim_clear_autocmds({
            group = 'scrollbar_render',
            event = 'WinScrolled',
        })
        local pending
        vim.api.nvim_create_autocmd('WinScrolled', {
            group = 'scrollbar_render',
            callback = function(ev)
                if not pending then
                    pending = {}
                    vim.defer_fn(function()
                        local windows = pending
                        pending = nil
                        for win in pairs(windows) do
                            if vim.api.nvim_win_is_valid(win) then
                                vim.api.nvim_win_call(win, function()
                                    require('scrollbar.handlers').show()
                                    scrollbar.render()
                                end)
                            end
                        end
                    end, 16)
                end
                if vim.v.event.all then
                    for win in pairs(vim.v.event) do
                        if win ~= 'all' then
                            pending[tonumber(win)] = true
                        end
                    end
                else
                    pending[tonumber(ev.match)] = true
                end
            end,
        })
    end,
}
