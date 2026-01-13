return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
        require("nvim-treesitter.configs").setup({
            -- 确保安装了 vue 和 typescript 的解析器
            ensure_installed = { 
                "vue", "typescript", "javascript", "html", "css", 
                "json", "lua", "vim", "vimdoc" 
            },
            auto_install = true,
            highlight = { enable = true },
            indent = { enable = true },
            -- 针对 Vue 的特殊上下文识别
            autotag = { enable = true },
            textobjects = {
                select = {
                    enable = true,
                    lookahead = true,
                    keymaps = {
                        ["ib"] = "@block.inner",
                        ["ab"] = "@block.outer",
                        ["iq"] = "@string.inner",
                        ["aq"] = "@string.outer",
                    },
                },
            },
        })
    end,
    dependencies = {
        "windwp/nvim-ts-autotag", -- 自动闭合 HTML/Vue 标签 (<div> -> </div>)
    }
}