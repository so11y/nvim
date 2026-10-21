return {
    'karb94/neoscroll.nvim',
    opts = {
        mappings = {},
        easing = 'quadratic',
    },
    keys = {
        {
            'J',
            function()
                if vim.v.count > 0 then
                    vim.wo.scroll = vim.v.count
                end
                require('neoscroll').ctrl_d({ duration = 160 })
            end,
            desc = '向下滚动半页',
        },
        {
            'K',
            function()
                if vim.v.count > 0 then
                    vim.wo.scroll = vim.v.count
                end
                require('neoscroll').ctrl_u({ duration = 160 })
            end,
            desc = '向上滚动半页',
        },
    },
}
