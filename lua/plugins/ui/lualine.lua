return {
    "nvim-lualine/lualine.nvim",
    dependencies = {"nvim-tree/nvim-web-devicons"},
    enabled = false,
    config = function()
        require("lualine").setup({
            options = {
                theme = "auto",
                component_separators = {
                    left = '│',
                    right = '│'
                },
                section_separators = {
                    left = '',
                    right = ''
                },
                globalstatus = true
            },
            sections = {
                lualine_a = {{
                    'mode',
                    right_padding = 2
                }},
                lualine_b = {'branch', {
                    'diagnostics',
                    symbols = {
                        error = ' ',
                        warn = ' ',
                        info = ' ',
                        hint = ' '
                    }
                }},
                lualine_c = { -- 显示文件名 (支持相对路径)
                {
                    'filename',
                    path = 1
                }},
                lualine_x = {'encoding', 'fileformat', 'filetype'},
                lualine_y = {'progress'},
                lualine_z = {{
                    'location',
                    left_padding = 2
                }}
            }
        })
    end
}
