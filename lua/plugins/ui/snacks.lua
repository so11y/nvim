return {{
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
        dashboard = {
            enabled = true
        },
        explorer = {
            enabled = false
        },
        indent = {
            enabled = true,
            animate = {
                enabled = true
            },
            scope = {
                enabled = true, -- enable highlighting the current scope
                underline = true -- underline the start of the scope
            },
            chunk = {
                enabled = true
            }
        },
        input = {
            enabled = true
        },
        notifier = {
            enabled = true,
            style = "notification"
        },
        scope = {
            enabled = true,
            cursor = false
        },
        styles = {
            terminal = {
                relative = "editor",
                border = "rounded",
                position = "float",
                backdrop = 60,
                height = 0.9,
                width = 0.9,
                zindex = 50
            }
        }
    },

    keys = {{
        "<A-i>",
        function()
            require("snacks").terminal()
        end,
        desc = "[Snacks] Toggle terminal",
        mode = {"n", "t"}
    }, -- Notification
    {
        "<leader>n",
        function()
            require("snacks").picker.notifications()
        end,
        desc = "[Snacks] Notification history"
    }}
}}
