return {
    'NvChad/nvim-colorizer.lua',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {
        filetypes = { '*' },
        options = {
            parsers = {
                hex = { default = true, rrggbbaa = true, aarrggbb = true },
                css_fn = true,
                tailwind = { enable = true },
                sass = { enable = true, parsers = { css = true } },
            },
            display = {
                mode = 'virtualtext',
                virtualtext = { char = '■', position = 'after' },
            },
        },
    },
}
