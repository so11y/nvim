return {
    'Bekaboo/dropbar.nvim',
    lazy = false,
    opts = {
        menu = {
            keymaps = {
                ['h'] = '<C-w>q',
                ['l'] = function()
                    local menu = require('dropbar.utils.menu').get_current()
                    local row = vim.api.nvim_win_get_cursor(menu.win)[1]
                    local components = menu.entries[row].components
                    menu:click_on(
                        components[1].on_click and components[1]
                            or components[2]
                    )
                end,
            },
        },
    },
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
