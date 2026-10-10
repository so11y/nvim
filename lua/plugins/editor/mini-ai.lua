local keys = {}
for id, desc in pairs({ q = '引号内部', b = '括号内部' }) do
    keys[#keys + 1] = {
        'i' .. id,
        function()
            local mode = vim.fn.mode(1)
            local operator_pending = mode:sub(1, 2) == 'no'
            local vis_mode = operator_pending and mode:sub(3) or nil
            local reference_region
            if not operator_pending then
                local regions =
                    vim.fn.getregionpos(vim.fn.getpos('v'), vim.fn.getpos('.'))
                local first, last = regions[1][1], regions[#regions][2]
                reference_region = {
                    from = { line = first[2], col = first[3] },
                    to = { line = last[2], col = last[3] },
                }
            end
            require('mini.ai').select_textobject('i', id, {
                n_times = vim.v.count1,
                reference_region = reference_region,
                operator_pending = operator_pending,
                vis_mode = vis_mode == '' and 'v' or vis_mode,
            })
        end,
        mode = { 'x', 'o' },
        desc = desc,
    }
end

for id, desc in pairs({ b = '括号', q = '引号' }) do
    local jump = require('utils.repeatable').jump_pair(function()
        require('config.pair_move').move(true, id)
    end, function()
        require('config.pair_move').move(false, id)
    end)
    for prefix, forward in pairs({ [']'] = true, ['['] = false }) do
        keys[#keys + 1] = {
            prefix .. id,
            function()
                jump({ forward = forward })
            end,
            mode = { 'n', 'x', 'o' },
            desc = (forward and '下一个' or '上一个') .. desc .. '开头',
        }
    end
end

return {
    'nvim-mini/mini.ai',
    version = '*',
    keys = keys,
    opts = {
        mappings = {
            around = '',
            inside = '',
            around_next = '',
            inside_next = '',
            around_last = '',
            inside_last = '',
            goto_left = '',
            goto_right = '',
        },
    },
}
