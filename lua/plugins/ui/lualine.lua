return {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        require("lualine").setup({
            options = {
                theme = "auto", 
                -- 分隔符风格 (看起来像能量条)
                component_separators = { left = '|', right = '|' },
                section_separators = { left = '', right = '' },
                globalstatus = true, -- 全局状态栏 (如果有分屏，只在最底下显示一条)
            },
            sections = {
                lualine_a = { { 'mode', separator = { left = '' }, right_padding = 2 } },
                lualine_b = { 'branch', 'diff', { 'diagnostics', symbols = { error = ' ', warn = ' ', info = ' ', hint = ' ' } } },
                lualine_c = { 
                    -- 显示文件名 (支持相对路径)
                    { 'filename', path = 1 } 
                },
                lualine_x = { 'encoding', 'fileformat', 'filetype' },
                lualine_y = { 'progress' },
                lualine_z = {
                    { 'location', separator = { right = '' }, left_padding = 2 },
                },
            },
        })
    end
}