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
}
