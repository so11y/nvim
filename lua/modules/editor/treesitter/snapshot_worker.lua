local request = vim.json.decode(io.read('*a'))
vim.opt.rtp = request.runtimepath
-- Register the same directives used by the interactive text objects.
require('modules.editor.treesitter.textobjects')

local parser = vim.treesitter.get_string_parser(request.source, request.lang)
parser:parse(true)
local captures = {}
local terminators = {}
local function add(name, range)
    captures[name] = captures[name] or {}
    table.insert(captures[name], range)
end

parser:for_each_tree(function(tree, language)
    local query = vim.treesitter.query.get(language:lang(), 'textobjects')
    if not query then
        return
    end
    for _, match, metadata in query:iter_matches(tree:root(), request.source) do
        for id, nodes in pairs(match) do
            local name = query.captures[id]
            if name:sub(1, 1) ~= '_' then
                local range
                if metadata[id] and metadata[id].range then
                    range = vim.treesitter._range.add_bytes(
                        request.source,
                        metadata[id].range
                    )
                else
                    range = { nodes[1]:range(true) }
                    local _, _, _, row, col, byte = nodes[#nodes]:range(true)
                    range[4], range[5], range[6] = row, col, byte
                end
                add(name, range)
                if name == 'statement.outer' and range[5] > 0 then
                    local last = tree:root():descendant_for_range(
                        range[4],
                        range[5] - 1,
                        range[4],
                        range[5] - 1
                    )
                    if last and last:type() == ';' then
                        terminators[tostring(range[6])] = true
                    end
                end
            end
        end
        if metadata.range and metadata.range[7] then
            add(metadata.range[7], { unpack(metadata.range, 1, 6) })
        end
    end
end)

for name, ranges in pairs(captures) do
    table.sort(ranges, function(a, b)
        return a[3] < b[3] or a[3] == b[3] and a[6] < b[6]
    end)
    local unique = {}
    for _, range in ipairs(ranges) do
        local last = unique[#unique]
        if not last or last[3] ~= range[3] or last[6] ~= range[6] then
            unique[#unique + 1] = range
        end
    end
    captures[name] = unique
end
io.stdout:write(
    vim.json.encode({ captures = captures, terminators = terminators })
)
