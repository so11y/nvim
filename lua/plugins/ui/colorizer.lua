local sass = {
    parsers = { sass = { enable = true, parsers = { css = true } } },
    debounce_ms = 100,
}

return {
    'NvChad/nvim-colorizer.lua',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {
        filetypes = { '*', scss = sass, sass = sass, vue = sass },
        options = {
            parsers = {
                hex = { default = true, rrggbbaa = true, aarrggbb = true },
                css_fn = true,
                tailwind = { enable = true },
            },
            display = {
                mode = 'virtualtext',
                virtualtext = { char = '■', position = 'after' },
            },
        },
    },
}
