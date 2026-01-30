return {
    'rebelot/heirline.nvim',
    event = {'BufReadPre', 'BufNewFile'},
    dependencies = {"nvim-tree/nvim-web-devicons"},
    config = function()
        vim.opt.cmdheight = 0
        require('heirline').setup {
            statusline = require 'custom.heirline.statusline'
        }
    end
}
