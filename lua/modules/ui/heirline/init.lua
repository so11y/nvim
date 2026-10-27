return {
    'rebelot/heirline.nvim',
    event = 'VeryLazy',
    config = function()
        local utils = require('heirline.utils')
        local function colors()
            local palette = {
                status_fg = '#FFFFFF',
                status_bg = '#007ACC',
                diag_error = '#FFB4AB',
                diag_warn = '#F4D58D',
                diag_info = '#B7DCFF',
                diag_hint = '#A9DCCB',
            }
            vim.api.nvim_set_hl(0, 'StatusLine', {
                fg = palette.status_fg,
                bg = palette.status_bg,
            })
            vim.api.nvim_set_hl(0, 'StatusLineNC', {
                fg = palette.status_fg,
                bg = palette.status_bg,
            })
            return palette
        end

        require('heirline').setup({
            statusline = require('modules.ui.heirline.statusline'),
            opts = { colors = colors },
        })
        vim.api.nvim_create_autocmd('ColorScheme', {
            group = vim.api.nvim_create_augroup(
                'HeirlineColors',
                { clear = true }
            ),
            callback = function()
                utils.on_colorscheme(colors)
            end,
        })
    end,
}
