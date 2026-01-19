return { -- 1. 先安装核心插件
{
    "nvim-treesitter/nvim-treesitter",
    opts_extend = {"ensure_installed"},
    main = "nvim-treesitter.config",
    opts = {
        ensure_installed = {"vue", "typescript", "javascript", "html", "css", "tsx", "json", "lua", "vim", "vimdoc",
                            "bash", "markdown"},
        highlight = {
            enable = true,
            additional_vim_regex_highlighting = false
        },
        indent = {
            enable = true
        }
    },
    config = function(_, opts)
        require('nvim-treesitter.install').compilers = {"gcc"}
        require('nvim-treesitter.config').setup(opts)
    end
}, {
    "windwp/nvim-ts-autotag",
    config = function()
        require("nvim-ts-autotag").setup({
            opts = {
                -- 默认是开启的，这里显式列出以供参考
                enable_close = true, -- 自动闭合标签 <div > -> </div>
                enable_rename = true, -- 自动重命名标签 (这就是你想要的功能)
                enable_close_on_slash = true -- 输入 </ 自动闭合
            }
        })
    end
}}
