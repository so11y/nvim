return {
    'rebelot/heirline.nvim',
    event = 'VeryLazy',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
        local utils = require('heirline.utils')
        local function colors()
            local c = require('vscode.colors').get_colors()
            local palette = {
                base = c.vscBack,
                mantle = c.vscTabOutside,
                text = c.vscFront,
                dim = c.vscLineNumber,
                blue = c.vscBlue,
                lavender = c.vscBlue,
                mauve = c.vscPink,
                pink = c.vscPink,
                peach = c.vscOrange,
                green = c.vscLightGreen,
                red = c.vscRed,
                maroon = c.vscLightRed,
                filetype = c.vscYellow,
                diag_warn = c.vscYellow,
                diag_error = c.vscRed,
                diag_hint = c.vscBlueGreen,
                diag_info = c.vscLightBlue,
            }
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
