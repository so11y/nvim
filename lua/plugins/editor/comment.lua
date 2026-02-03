return {
    "numToStr/Comment.nvim",
    event = {"BufReadPost", "BufNewFile"},
    config = function()
        require("Comment").setup({
            -- 配置 Alt+/ 为注释键
            toggler = {
                line = '<A-/>'
            },
            opleader = {
                line = '<A-/>',
                block = 'gB'
            },
            extra = {
                above = 'gcO',
                below = 'gco',
                eol = 'gcA'
            }
        })
    end
}
