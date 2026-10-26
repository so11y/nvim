return {
    'iamyoki/buffer-reopen.nvim',
    event = 'VeryLazy',
    keys = {
        {
            '<leader>wr',
            '<cmd>BufferHistory reopen<cr>',
            desc = '重新打开上一个关闭的文件',
        },
    },
    config = function()
        -- 插件按名称记录 Buffer，在接入处限制为普通文件。
        local handlers = require('buffer-reopen.event_handlers')
        local on_buf_delete = handlers.on_buf_delete
        handlers.on_buf_delete = function(ev)
            if vim.bo[ev.buf].buftype == '' and vim.bo[ev.buf].buflisted then
                on_buf_delete(ev)
            end
        end
        require('buffer-reopen').setup({})
        vim.keymap.del('n', '<leader>bt')
        vim.keymap.del('n', '<C-S-t>')
    end,
}
