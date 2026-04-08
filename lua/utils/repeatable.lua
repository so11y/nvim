local M = {}

function M.jump_pair(forward_fn, backward_fn)
    local move = require('nvim-treesitter.textobjects.repeatable_move')
    return move.make_repeatable_move(function(args)
        (args.forward and forward_fn or backward_fn)()
    end)
end

function M.map_jump(key_next, key_prev, forward_fn, backward_fn, desc_next, desc_prev)
    local jump = M.jump_pair(forward_fn, backward_fn)
    local nxo = { 'n', 'x', 'o' }
    vim.keymap.set(nxo, key_next, function() jump({ forward = true }) end, { desc = desc_next })
    vim.keymap.set(nxo, key_prev, function() jump({ forward = false }) end, { desc = desc_prev })
end

return M
