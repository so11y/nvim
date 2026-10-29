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

-- 让 Windows Terminal 复制分屏时沿用 Neovim 的当前目录。
if vim.env.WT_SESSION and not vim.g.vscode and not vim.g.neovide then
    vim.api.nvim_create_autocmd({ 'VimEnter', 'DirChanged', 'FocusGained' }, {
        group = vim.api.nvim_create_augroup('config.wt_cwd', { clear = true }),
        callback = function()
            vim.api.nvim_ui_send('\27]9;9;"' .. vim.fn.getcwd() .. '"\27\\')
        end,
    })
end

vim.api.nvim_create_autocmd('VimLeave', {
    callback = function()
        io.write('\27[2J')
    end,
})
