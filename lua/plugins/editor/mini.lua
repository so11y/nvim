return {
    "echasnovski/mini.ai",
    event = "VeryLazy",
    -- opts = function()
    --     local ai = require("mini.ai")
    --     return {
    --         n_lines = 500,
    --         custom_textobjects = {
    --             q = ai.gen_spec.pair('"', '"', {
    --                 unicode = true
    --             })

    --         },
    --         -- 快捷键映射：确保 i 和 a 正常工作
    --         mappings = {
    --             around = 'a',
    --             inside = 'i'
    --         }
    --     }
    -- end,
    config = function(_, opts)
        require("mini.ai").setup(opts)
    end
}
