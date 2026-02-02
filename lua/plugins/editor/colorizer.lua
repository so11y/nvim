return {{
    "NvChad/nvim-colorizer.lua",
    event = {"BufReadPost", "BufNewFile"},
    opts = {
        filetypes = {"*"}, -- 对所有文件类型生效
        user_default_options = {
            RGB = true,
            RRGGBB = true,
            names = true,
            RRGGBBAA = true,
            AARRGGBB = true,
            rgb_fn = true,
            hsl_fn = true,
            css_fn = true,
            mode = "virtualtext",
            virtualtext_inline = true,
            tailwind = true,
            sass = {
                enable = true,
                parsers = {"css"}
            },
            virtualtext = "■"
        }
    }
}}
