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
local chunk_lines = 256
for _, capture in pairs(M.captures) do
    wanted[capture] = true
end
vim.api.nvim_create_autocmd('BufWipeout', {
    group = vim.api.nvim_create_augroup('config.ast_move', { clear = true }),
    callback = function(ev)
        cache[ev.buf] = nil
    end,
})

local function positions(bufnr, chunk)
    local tick, ft =
        vim.api.nvim_buf_get_changedtick(bufnr), vim.bo[bufnr].filetype
    local entry = cache[bufnr]
    if
        entry
        and entry.tick == tick
        and entry.ft == ft
        and entry.chunks[chunk]
    then
        return entry.chunks[chunk]
    end
    local parser = vim.treesitter.get_parser(bufnr, nil, { error = false })
    if not parser then
        return {}
    end
    parser:parse(true)
    local first_row = chunk * chunk_lines
    local last_row =
        math.min(first_row + chunk_lines, vim.api.nvim_buf_line_count(bufnr))
    local found = {}
    parser:for_each_tree(function(tree, language)
        local root = tree:root()
        local tree_start, _, tree_end = root:range()
        if tree_end < first_row or tree_start >= last_row then
            return
        end
        local query = vim.treesitter.query.get(language:lang(), 'textobjects')
        if not query then
            return
        end
        for id, node, metadata in
            query:iter_captures(root, bufnr, first_row, last_row)
        do
            local capture = query.captures[id]
            if wanted[capture] then
                local row, col, byte = node:start()
                if metadata[id] and metadata[id].range then
                    row, col = unpack(metadata[id].range)
                    byte = vim.api.nvim_buf_get_offset(bufnr, row) + col
                end
                -- Queries can repeat a long parent in later windows.
                if row >= first_row and row < last_row then
                    found[capture] = found[capture] or {}
                    found[capture][#found[capture] + 1] = {
                        row + 1,
                        col,
                        byte,
                    }
                end
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
    if not entry or entry.tick ~= tick or entry.ft ~= ft then
        entry = { tick = tick, ft = ft, chunks = {} }
        cache[bufnr] = entry
    end
    entry.chunks[chunk] = found
    return found
end

M.move = require('nvim-treesitter-textobjects.repeatable_move').make_repeatable_move(
    function(opts, capture)
        local buf = vim.api.nvim_get_current_buf()
        local last_chunk =
            math.floor((vim.api.nvim_buf_line_count(buf) - 1) / chunk_lines)
        for _ = 1, vim.v.count1 do
            local cursor = vim.api.nvim_win_get_cursor(0)
            local byte = vim.api.nvim_buf_get_offset(buf, cursor[1] - 1)
                + cursor[2]
            local start_chunk = math.floor((cursor[1] - 1) / chunk_lines)
            local target
            for chunk = start_chunk, opts.forward and last_chunk or 0, opts.forward and 1 or -1 do
                local ranges = positions(buf, chunk)[capture] or {}
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
                target = ranges[opts.forward and left or right]
                if target then
                    break
                end
            end
            if not target then
                return
            end
            vim.cmd("normal! m'")
            vim.api.nvim_win_set_cursor(0, { target[1], target[2] })
        end
    end
)

return M
