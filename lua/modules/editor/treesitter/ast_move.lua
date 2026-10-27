local M = {
    captures = {
        f = 'function.outer',
        a = 'parameter.inner',
        d = 'conditional.outer',
        l = 'loop.outer',
        c = 'call.outer',
        s = 'statement.outer',
    },
}

M.move = require('nvim-treesitter-textobjects.repeatable_move').make_repeatable_move(
    function(opts, capture)
        local buf, count = vim.api.nvim_get_current_buf(), vim.v.count1
        local index = require('modules.editor.treesitter.snapshot').get(buf)
        if not index then
            return
        end
        local ranges = index.captures[capture] or {}
        for _ = 1, count do
            local cursor = vim.api.nvim_win_get_cursor(0)
            local byte = vim.api.nvim_buf_get_offset(buf, cursor[1] - 1)
                + cursor[2]
            local left, right = 1, #ranges
            while left <= right do
                local mid = math.floor((left + right) / 2)
                if
                    ranges[mid][3] < byte
                    or opts.forward and ranges[mid][3] == byte
                then
                    left = mid + 1
                else
                    right = mid - 1
                end
            end
            local target = ranges[opts.forward and left or right]
            if not target then
                return
            end
            vim.cmd("normal! m'")
            vim.api.nvim_win_set_cursor(0, { target[1] + 1, target[2] })
        end
    end
)

return M
