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
            for key, capture in pairs(motion.captures) do
                vim.keymap.set(nxo, ']' .. key, function()
                    motion.move({ forward = true }, capture)
                end, { desc = 'Next ' .. capture })
                vim.keymap.set(nxo, '[' .. key, function()
                    motion.move({ forward = false }, capture)
                end, { desc = 'Previous ' .. capture })
            end
            local repeat_move =
                require('nvim-treesitter-textobjects.repeatable_move')
            vim.keymap.set(
                nxo,
                ';',
                repeat_move.repeat_last_move_next,
                { desc = 'Repeat last movement' }
            )
            vim.keymap.set(
                nxo,
                ',',
                repeat_move.repeat_last_move_previous,
                { desc = 'Reverse last movement' }
            )
            for key, capture in pairs({
                af = 'function.outer',
                ['if'] = 'function.inner',
                al = 'loop.outer',
                il = 'loop.inner',
                ad = 'conditional.outer',
                id = 'conditional.inner',
                ac = 'call.outer',
                ic = 'call.inner',
                aa = 'parameter.outer',
                ia = 'parameter.inner',
                ['as'] = 'statement.outer',
                ['is'] = 'statement.inner',
            }) do
                vim.keymap.set({ 'x', 'o' }, key, function()
                    vim.cmd("normal! m'")
                    require('nvim-treesitter-textobjects.select').select_textobject(
                        '@' .. capture,
                        'textobjects'
                    )
                end, { desc = 'Select ' .. capture })
            end
            vim.keymap.set('n', '<leader>ra', function()
                require('config.parameter_swap').swap(1)
            end, { desc = 'Swap next parameter' })
            vim.keymap.set('n', '<leader>rA', function()
                require('config.parameter_swap').swap(-1)
            end, { desc = 'Swap previous parameter' })
        end,
    },
}
