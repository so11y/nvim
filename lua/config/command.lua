vim.api.nvim_create_user_command('ToggleZen', function()
    if vim.opt.number:get() then
        vim.opt.number = false
        vim.opt.relativenumber = false
        vim.opt.signcolumn = 'no'
    else
        vim.opt.number = true
        vim.opt.relativenumber = true
        vim.opt.signcolumn = 'yes'
    end
end, {})

vim.api.nvim_create_autocmd('VimLeave', {
    callback = function()
        io.write('\27[2J')
    end,
})
