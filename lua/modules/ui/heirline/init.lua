return {
    'rebelot/heirline.nvim',
    event = 'VeryLazy',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
        local utils = require('heirline.utils')
        local function colors()
            local palette = require('catppuccin.palettes').get_palette('mocha')
            palette.dim = palette.surface1
            palette.filetype = palette.yellow
            palette.diag_warn = palette.yellow
            palette.diag_error = palette.red
            palette.diag_hint = palette.teal
            palette.diag_info = palette.sky
            vim.api.nvim_set_hl(0, 'StatusLine', {
                fg = palette.text,
                bg = palette.mantle,
            })
            vim.api.nvim_set_hl(0, 'StatusLineNC', {
                fg = palette.dim,
                bg = palette.mantle,
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
