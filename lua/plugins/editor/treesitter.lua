return {
    {
        'nvim-treesitter/nvim-treesitter',
        branch = 'main',
        lazy = false,
        build = function()
            require('config.treesitter').install()
        end,
        config = function()
            require('config.treesitter').setup()
        end,
    },
    {
        'nvim-treesitter/nvim-treesitter-textobjects',
        branch = 'main',
        event = 'FileType',
        opts = { select = { lookahead = true }, move = { set_jumps = true } },
        config = function(_, opts)
            require('nvim-treesitter-textobjects').setup(opts)
            local nxo = { 'n', 'x', 'o' }
            local motion = require('config.ast_move')
            local descriptions = {
                a = { '下一个参数', '上一个参数' },
                c = { '下一处调用', '上一处调用' },
                d = { '下一个条件分支', '上一个条件分支' },
                f = { '下一个函数', '上一个函数' },
                l = { '下一个循环', '上一个循环' },
                s = { '下一条语句', '上一条语句' },
            }
            for key, capture in pairs(motion.captures) do
                vim.keymap.set(nxo, ']' .. key, function()
                    motion.move({ forward = true }, capture)
                end, { desc = descriptions[key][1] })
                vim.keymap.set(nxo, '[' .. key, function()
                    motion.move({ forward = false }, capture)
                end, { desc = descriptions[key][2] })
            end
            local repeat_move =
                require('nvim-treesitter-textobjects.repeatable_move')
            vim.keymap.set(
                nxo,
                ';',
                repeat_move.repeat_last_move_next,
                { desc = '重复上次移动' }
            )
            vim.keymap.set(
                nxo,
                ',',
                repeat_move.repeat_last_move_previous,
                { desc = '反向重复上次移动' }
            )
            for key, object in pairs({
                af = { 'function.outer', '选中整个函数' },
                ['if'] = { 'function.inner', '选中函数内部' },
                al = { 'loop.outer', '选中整个循环' },
                il = { 'loop.inner', '选中循环内部' },
                ad = { 'conditional.outer', '选中整个条件分支' },
                id = { 'conditional.inner', '选中条件分支内部' },
                ac = { 'call.outer', '选中整个调用' },
                ic = { 'call.inner', '选中调用内部' },
                aa = { 'parameter.outer', '选中整个参数' },
                ia = { 'parameter.inner', '选中参数内容' },
                ['as'] = { 'statement.outer', '选中整条语句' },
                ['is'] = { 'statement.inner', '选中语句内容' },
            }) do
                local capture, description = object[1], object[2]
                vim.keymap.set({ 'x', 'o' }, key, function()
                    vim.cmd("normal! m'")
                    require('nvim-treesitter-textobjects.select').select_textobject(
                        '@' .. capture,
                        'textobjects'
                    )
                end, { desc = description })
            end
        end,
    },
}
