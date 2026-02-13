return {
    {
        'MagicDuck/grug-far.nvim',
        event = 'VeryLazy',
        config = function()
            require('grug-far').setup({
                keymaps = {
                    close = {
                        n = '<A-w>',
                    },
                },
            })
        end,

        keys = {
            {
                '<leader>r',
                function()
                    local grug = require('grug-far')
                    local ext = vim.bo.buftype

                    if ext == 'nofile' and vim.bo.filetype == 'grug-far' then
                        grug.close()
                    else
                        grug.open({

                            prefills = {
                                paths = vim.fn.expand('%'),
                                flags = '--fixed-strings',
                            },
                        })
                    end
                end,
                mode = { 'n', 'v' }, -- 支持普通模式和可视模式
                desc = 'Grug Far (当前文件)',
            },
        },
    },
}
