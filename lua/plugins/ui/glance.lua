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
            list = { position = 'right', width = 0.4 },
            folds = { folded = false },
            border = { enable = true, top_char = '─', bottom_char = '─' },
            theme = { enable = false },
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
        local function highlights()
            for _, group in ipairs({
                'GlanceListNormal',
                'GlancePreviewNormal',
                'GlancePreviewSignColumn',
                'GlancePreviewFoldColumn',
                'GlanceListFilename',
                'GlanceWinBarFilename',
                'GlanceWinBarFilepath',
                'GlanceWinBarTitle',
            }) do
                vim.api.nvim_set_hl(0, group, { link = 'NormalFloat' })
            end
            for group, link in pairs({
                GlanceListCursorLine = 'PmenuSel',
                GlancePreviewCursorLine = 'CursorLine',
                GlanceListFilepath = 'Comment',
                GlanceListCount = 'Comment',
                GlanceFoldIcon = 'Comment',
                GlanceIndent = 'BlinkIndent',
                GlancePreviewLineNr = 'LineNr',
                GlanceListEndOfBuffer = 'EndOfBuffer',
                GlancePreviewEndOfBuffer = 'EndOfBuffer',
                GlanceBorderTop = 'FloatBorder',
                GlanceListBorderBottom = 'FloatBorder',
                GlancePreviewBorderBottom = 'FloatBorder',
            }) do
                vim.api.nvim_set_hl(0, group, { link = link })
            end
        end
        highlights()
        vim.api.nvim_create_autocmd('ColorScheme', {
            group = vim.api.nvim_create_augroup(
                'GlanceAppearance',
                { clear = true }
            ),
            callback = highlights,
        })
    end,
}
