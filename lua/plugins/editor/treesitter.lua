return { -- 1. 先安装核心插件
{
    "nvim-treesitter/nvim-treesitter",
    opts_extend = {"ensure_installed"},
    -- main = "nvim-treesitter.configs",
    opts = {
        ensure_installed = {"vue", "typescript", "javascript", "html", "css", "tsx", "json", "lua", "vim", "vimdoc",
                            "bash", "markdown"},
        highlight = {
            enable = true
        },
        indent = {
            enable = true
        }
    },
    config = function(_, opts)
        require('nvim-treesitter.install').compilers = {"clang"}
        require("nvim-treesitter.configs").setup(opts)
    end
}, -- 2. 将扩展插件【平级】放置，并设置它们在 treesitter 加载后再加载
{
    "nvim-treesitter/nvim-treesitter-textobjects",
    event = "VeryLazy", -- 延迟加载，防止抢跑
    -- 确保核心插件已经加载
    dependencies = {"nvim-treesitter/nvim-treesitter"},
    config = function()
        -- 这里进行 textobjects 的具体配置
        require("nvim-treesitter.configs").setup({
            textobjects = {
                select = {
                    enable = true,
                    lookahead = true,
                    keymaps = {
                        ["iq"] = "@string.inner", -- 你要的 viq
                        ["aq"] = "@string.outer",
                        ["if"] = "@function.inner",
                        ["af"] = "@function.outer"
                    }
                }
            }
        })
    end
}, -- 3. 针对报错中提到的 autotag 也做同样处理
{
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
