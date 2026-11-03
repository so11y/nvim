return {
    'Bekaboo/dropbar.nvim',
    lazy = false,
    keys = {
        {
            '<leader>;',
            function()
                require('dropbar.api').pick()
            end,
            desc = '选择面包屑层级',
        },
    },
}
