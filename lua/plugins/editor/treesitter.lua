return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    dependencies = { -- ✅ 必须依赖：textobjects 插件
    "nvim-treesitter/nvim-treesitter-textobjects"},
    -- ✅ 使用 opts 来定义配置表，而不是写死在 setup 里
    opts = {
        install = {
            prefer_git = true
        },
        -- 确保安装的解析器
        ensure_installed = {"vue", "typescript", "javascript", "html", "css", "tsx", "json", "lua", "vim", "vimdoc",
                            "bash", "markdown"},
        auto_install = true,
        highlight = {
            enable = true
        },
        indent = {
            enable = true
        },

        -- textobjects 配置
        textobjects = {
            select = {
                enable = true,
                lookahead = true, -- 自动跳到下一个匹配项
                keymaps = {
                    -- 块选择
                    ["ib"] = "@block.inner",
                    ["ab"] = "@block.outer",
                    -- 引号选择 (你的目标 viq)
                    ["iq"] = "@string.inner",
                    ["aq"] = "@string.outer"
                }
            }
        }
    },
    -- ✅ 标准 config 函数：接收上面的 opts 并传给 setup
    config = function(_, opts)
        -- require('nvim-treesitter.install').compilers = {"clang"}
        require("nvim-treesitter.configs").setup(opts)
    end
}
