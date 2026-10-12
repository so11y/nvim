return {
    'rebelot/heirline.nvim',
    event = 'VeryLazy',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
        local utils = require('heirline.utils')
        local function colors()
            local github = vim.startswith(vim.g.colors_name, 'github_')
            local palette = require('catppuccin.palettes').get_palette(
                github and 'mocha' or nil
            )
            palette.dim = palette.surface1
            if github then
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
            else
                palette.filetype = utils.get_highlight('Type').fg
                palette.diag_warn = utils.get_highlight('DiagnosticWarn').fg
                palette.diag_error = utils.get_highlight('DiagnosticError').fg
                palette.diag_hint = utils.get_highlight('DiagnosticHint').fg
                palette.diag_info = utils.get_highlight('DiagnosticInfo').fg
            end
            return palette
        end

        require('heirline').setup({
            statusline = require('custom.heirline.statusline'),
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
