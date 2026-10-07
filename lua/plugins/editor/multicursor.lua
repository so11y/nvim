local function from_insert(key)
    return '<Esc>' .. key .. (vim.fn.col('.') > 1 and 'a' or 'i')
end

local function start_insert(command)
    local mc = require('multicursor-nvim')
    if not mc.cursorsEnabled() then
        mc.enableCursors()
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
    'jake-stewart/multicursor.nvim',
    branch = '1.0',
    keys = {
        {
            'gb',
            function()
                local mc = require('multicursor-nvim')
                local inserting = vim.fn.mode(1) == 'niI'
                mc.matchAddCursor(1)
                if inserting then
                    mc.feedkeys('i')
                end
            end,
            mode = { 'n', 'x' },
            desc = '选中下一个相同的词',
        },
        {
            'gb',
            '<C-o>gb',
            mode = 'i',
            remap = true,
            desc = '选中下一个相同的词',
        },
        {
            '<A-J>',
            function()
                require('multicursor-nvim').lineAddCursor(
                    1,
                    { skipEmpty = false }
                )
            end,
            mode = { 'n', 'x' },
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
            '<A-K>',
            function()
                require('multicursor-nvim').lineAddCursor(
                    -1,
                    { skipEmpty = false }
                )
            end,
            mode = { 'n', 'x' },
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
            'mc',
            function()
                require('multicursor-nvim').toggleCursor()
            end,
            mode = { 'n', 'x' },
            desc = '手动添加或移除光标',
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
        {
            'mcc',
            function()
                require('multicursor-nvim').clearCursors()
            end,
            mode = { 'n', 'x' },
            desc = '取消所有光标',
        },
    },
    config = function()
        local mc = require('multicursor-nvim')
        mc.setup()
        mc.addKeymapLayer(function(map)
            map('n', '<Esc>', mc.clearCursors, { desc = '退出多光标' })
        end)
    end,
}
