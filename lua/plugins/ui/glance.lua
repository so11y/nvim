return {
    'DNLHC/glance.nvim',
    cmd = 'Glance',
    keys = {
        { 'gd', '<cmd>Glance definitions<CR>', desc = '转到定义' },
        { 'grr', '<cmd>Glance references<CR>', desc = '转到引用' },
        { 'gri', '<cmd>Glance implementations<CR>', desc = '转到实现' },
        {
            'grt',
            '<cmd>Glance type_definitions<CR>',
            desc = '转到类型定义',
        },
    },
    opts = function()
        local actions = require('glance').actions
        return {
            preserve_win_context = true,
            detached = false,
            border = { enable = true, top_char = '━', bottom_char = '▁' },
            list = { position = 'right', width = 0.4 },
            folds = { folded = false },
            mappings = {
                list = { ['<C-h>'] = actions.enter_win('preview') },
                preview = {
                    ['<C-l>'] = actions.enter_win('list'),
                    ['<Esc>'] = actions.close,
                    q = actions.close,
                },
            },
        }
    end,
    config = function(_, opts)
        require('glance').setup(opts)

        -- Reuse the border row for titles instead of adding a separate winbar.
        local Winbar = require('glance.winbar')
        function Winbar:render(values)
            if vim.deep_equal(values, self.last_values) then
                return
            end
            local title = {}
            for _, section in ipairs({ 'filename', 'filepath', 'title' }) do
                if values[section] then
                    title[#title + 1] = {
                        ' ' .. tostring(values[section]) .. ' ',
                        self.sections[section],
                    }
                end
            end
            vim.wo[self.winnr].winbar = ''
            vim.api.nvim_win_set_config(self.winnr, {
                title = title,
                title_pos = 'left',
            })
            self.last_values = values
        end

        local function highlight_borders()
            -- Match each border row to the adjacent panel.
            local fg =
                require('catppuccin.palettes').get_palette('mocha').lavender
            for group, panel in pairs({
                GlanceBorderTop = 'GlanceWinBarTitle',
                GlancePreviewBorderBottom = 'GlancePreviewNormal',
                GlanceListBorderBottom = 'GlanceListNormal',
            }) do
                local bg =
                    vim.api.nvim_get_hl(0, { name = panel, link = false }).bg
                vim.api.nvim_set_hl(0, group, { fg = fg, bg = bg })
            end
        end

        highlight_borders()
        vim.api.nvim_create_autocmd('ColorScheme', {
            group = vim.api.nvim_create_augroup(
                'GlanceBorders',
                { clear = true }
            ),
            callback = highlight_borders,
        })
    end,
}
