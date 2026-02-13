return {
    'rebelot/heirline.nvim',
    event = 'VeryLazy',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
        require('heirline').setup({
            statusline = require('custom.heirline.statusline'),
        })
    end,
}
