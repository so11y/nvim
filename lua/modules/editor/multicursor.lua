local function from_insert(key)
    return '<Esc>' .. key .. (vim.fn.col('.') > 1 and 'ma' or 'mi')
end

local function enable_cursors()
    if vim.b.visual_multi == 1 then
        vim.cmd('call b:VM_Selection.Maps.enable()')
    end
end

local function start_insert(command)
    if vim.b.visual_multi == 1 then
        enable_cursors()
        return '<Plug>(VM-' .. command .. ')'
    end
    if vim.fn.mode() == 'n' then
        return command
    end
    local anchor, cursor = vim.fn.getpos('v'), vim.fn.getpos('.')
    local at_start = cursor[2] < anchor[2]
        or (cursor[2] == anchor[2] and cursor[3] <= anchor[3])
    return (at_start ~= (command == 'i') and 'o' or '') .. '<Esc>' .. command
end

return {
    'mg979/vim-visual-multi',
    event = 'VeryLazy',
    init = function()
        vim.g.VM_default_mappings = 0
        vim.g.VM_live_editing = 1
        vim.g.VM_set_statusline = 0
        vim.g.VM_add_cursor_at_pos_no_mappings = 1
        vim.g.VM_skip_shorter_lines = 0
        vim.g.VM_maps = {
            ['Find Under'] = 'gb',
            ['Find Subword Under'] = 'gb',
            ['Add Cursor Down'] = '<A-J>',
            ['Add Cursor Up'] = '<A-K>',
            ['Add Cursor At Pos'] = '',
            ['Find Operator'] = '',
            ['Select Operator'] = '',
            J = '',
            Undo = '<A-z>',
            Redo = '<A-y>',
        }
        vim.g.VM_custom_remaps = { ['<CR>'] = 'a' }
    end,
    config = function()
        local insert_mappings = {}
        local group = vim.api.nvim_create_augroup('config.multicursor', {
            clear = true,
        })
        -- VM removes its buffer mappings without restoring the ones it replaced.
        vim.api.nvim_create_autocmd('User', {
            group = group,
            pattern = 'visual_multi_start',
            callback = function()
                insert_mappings = vim.api.nvim_buf_get_keymap(0, 'i')
            end,
        })
        vim.api.nvim_create_autocmd('User', {
            group = group,
            pattern = 'visual_multi_exit',
            callback = function()
                for _, mapping in ipairs(insert_mappings) do
                    vim.fn.mapset('i', false, mapping)
                end
                insert_mappings = {}
            end,
        })
    end,
    keys = {
        {
            'gb',
            '<Plug>(VM-Find-Under)',
            mode = 'n',
            desc = '选中当前词或下一个相同的词',
        },
        {
            'gb',
            '<Plug>(VM-Find-Subword-Under)',
            mode = 'x',
            desc = '选中下一个相同的选区',
        },
        {
            'gb',
            function()
                local action = vim.b.visual_multi == 1
                        and '<Plug>(VM-Find-Next)'
                    or '<Plug>(VM-Find-Under)'
                return '<Esc>' .. action .. 'mi'
            end,
            mode = 'i',
            expr = true,
            remap = true,
            desc = '选中当前词或下一个相同的词',
        },
        {
            '<A-J>',
            '<Plug>(VM-Add-Cursor-Down)',
            mode = 'n',
            desc = '向下添加光标',
        },
        {
            '<A-J>',
            function()
                return from_insert('<A-J>')
            end,
            mode = 'i',
            expr = true,
            remap = true,
            desc = '向下添加光标',
        },
        {
            '<A-J>',
            '<Esc><A-J>',
            mode = 'x',
            remap = true,
            desc = '向下添加光标',
        },
        {
            '<A-K>',
            '<Plug>(VM-Add-Cursor-Up)',
            mode = 'n',
            desc = '向上添加光标',
        },
        {
            '<A-K>',
            function()
                return from_insert('<A-K>')
            end,
            mode = 'i',
            expr = true,
            remap = true,
            desc = '向上添加光标',
        },
        {
            '<A-K>',
            '<Esc><A-K>',
            mode = 'x',
            remap = true,
            desc = '向上添加光标',
        },
        {
            'mc',
            '<Plug>(VM-Add-Cursor-At-Pos)',
            mode = 'n',
            desc = '手动添加或移除光标',
        },
        {
            'mc',
            '<Esc><Plug>(VM-Add-Cursor-At-Pos)',
            mode = 'x',
            desc = '手动添加或移除光标',
        },
        {
            'mm',
            enable_cursors,
            mode = { 'n', 'x' },
            desc = '启用所有光标',
        },
        {
            'mi',
            function()
                return start_insert('i')
            end,
            mode = { 'n', 'x' },
            expr = true,
            desc = '在所有光标前插入',
        },
        {
            'ma',
            function()
                return start_insert('a')
            end,
            mode = { 'n', 'x' },
            expr = true,
            desc = '在所有光标后插入',
        },
    },
}
