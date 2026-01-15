return {{
    "NvChad/nvim-colorizer.lua",
    event = "VeryLazy",
    opts = {
        filetypes = {"*"}, -- 对所有文件类型生效
        user_default_options = {
            RGB = true, -- #RGB 格式
            RRGGBB = true, -- #RRGGBB 格式
            names = true, -- "Red", "Blue" 等颜色名称
            RRGGBBAA = true, -- #RRGGBBAA 格式
            AARRGGBB = true, -- 0xAARRGGBB 格式
            rgb_fn = true, -- CSS rgb() 和 rgba() 函数
            hsl_fn = true, -- CSS hsl() 和 hsla() 函数
            css = true, -- 启用所有 CSS 功能: rgb_fn, hsl_fn, names, RGB, RRGGBB
            css_fn = true, -- 启用所有 CSS 函数: rgb_fn, hsl_fn
            -- 模式选择：
            -- "background" (背景显示颜色), 
            -- "foreground" (文字显示颜色), 
            -- "virtualtext" (在文字后面显示一个色块)
            mode = "background",
            tailwind = true, -- ✅ 支持 Tailwind CSS 颜色
            sass = {
                enable = true,
                parsers = {"css"}
            }, -- 支持 Sass
            virtualtext = "■"
        }
    }
}}
