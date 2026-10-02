local M = {
    captures = {
        f = 'function.outer',
        a = 'parameter.inner',
        d = 'conditional.outer',
        l = 'loop.outer',
        c = 'call.outer',
        q = 'string.outer',
        s = 'statement.outer',
        b = 'block.outer',
    },
}
local cache, wanted = {}, {}
for _, capture in pairs(M.captures) do
    wanted[capture] = true
end
vim.api.nvim_create_autocmd('BufWipeout', {
    group = vim.api.nvim_create_augroup('config.ast_move', { clear = true }),
    callback = function(ev)
        cache[ev.buf] = nil
    end,
})

local function positions(bufnr)
    local tick, ft =
        vim.api.nvim_buf_get_changedtick(bufnr), vim.bo[bufnr].filetype
    local entry = cache[bufnr]
    if entry and entry.tick == tick and entry.ft == ft then
        return entry.positions
    end
    local parser = vim.treesitter.get_parser(bufnr, nil, { error = false })
    if not parser then
        return {}
    end
    parser:parse(true)
    local found = {}
    parser:for_each_tree(function(tree, language)
        local query = vim.treesitter.query.get(language:lang(), 'textobjects')
        if not query then
            return
        end
        for id, node, metadata in query:iter_captures(tree:root(), bufnr) do
            local capture = query.captures[id]
            if wanted[capture] then
                local row, col, byte = node:start()
                if metadata[id] and metadata[id].range then
                    row, col = unpack(metadata[id].range)
                    byte = vim.api.nvim_buf_get_offset(bufnr, row) + col
                end
                found[capture] = found[capture] or {}
                found[capture][#found[capture] + 1] = { row + 1, col, byte }
            end
        end
    end)
    for name, ranges in pairs(found) do
        table.sort(ranges, function(a, b)
            return a[3] < b[3]
        end)
        local unique = {}
        for _, range in ipairs(ranges) do
            if #unique == 0 or unique[#unique][3] ~= range[3] then
                unique[#unique + 1] = range
            end
        end
        found[name] = unique
    end
    cache[bufnr] = { tick = tick, ft = ft, positions = found }
    return found
end

M.move = require('nvim-treesitter-textobjects.repeatable_move').make_repeatable_move(
    function(opts, capture)
        local buf = vim.api.nvim_get_current_buf()
        local ranges = positions(buf)[capture] or {}
        for _ = 1, vim.v.count1 do
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
            local range = ranges[opts.forward and left or right]
            if not range then
                return
            end
            vim.cmd("normal! m'")
            vim.api.nvim_win_set_cursor(0, { range[1], range[2] })
        end
    end
)

return M
