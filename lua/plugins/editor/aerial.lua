return {
    "stevearc/aerial.nvim",
    opts = {
        backends = {"lsp", "treesitter", "markdown", "man"},
        layout = {
            default_direction = "prefer_right",
            placement = "edge",
            resize_to_content = false,
            max_width = {40, 0.2},
            min_width = 25
        },
        close_on_select = false,
        show_guides = true,

        filter_kind = {"Class", "Constructor", "Enum", "Function", "Interface", "Method", "Struct", "Trait", "Variable",
                       "Constant", "Module", "Package", "Field", "Property", "Key", "String", "Array", "Object"},
        show_icons = true
    },

    config = function(_, opts)
        local aerial = require("aerial")
        aerial.setup(opts)

        -- 监听 'aerial' 文件类型 (也就是大纲窗口被打开时)
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "aerial",
            callback = function(args)
                -- 在大纲窗口中，每当光标移动 (CursorMoved)，就触发滚动
                vim.api.nvim_create_autocmd("CursorMoved", {
                    buffer = args.buf,
                    callback = function()
                        -- 调用 select 方法，jump=false 表示只同步位置，不抢夺光标焦点
                        pcall(aerial.select, {
                            jump = false
                        })
                    end
                })
            end
        })
    end,

    keys = {{
        "<leader>o",
        "<cmd>AerialToggle!<cr>",
        desc = "大纲开关"
    }}
}
