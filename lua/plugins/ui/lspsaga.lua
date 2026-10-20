return {
    'nvimdev/lspsaga.nvim',
    cmd = 'Lspsaga',
    keys = {
        {
            'gra',
            require('config.code_action').open,
            mode = { 'n', 'x' },
            desc = '代码操作',
        },
    },
    opts = {
        ui = { button = { '', '' } },
        lightbulb = { enable = false },
        symbol_in_winbar = { enable = false },
        code_action = {
            keys = {
                quit = { 'q', '<Esc>' },
                exec = { '<CR>', '<Tab>' },
            },
        },
    },
    config = function(_, opts)
        require('lspsaga').setup(opts)
        local function highlight_title()
            vim.api.nvim_set_hl(0, 'SagaActionTitle', { link = 'NormalFloat' })
        end
        highlight_title()
        vim.api.nvim_create_autocmd('ColorScheme', {
            group = require('lspsaga').saga_augroup,
            callback = highlight_title,
        })
        -- This version has no option to disable code action previews.
        require('lspsaga.codeaction.preview').action_preview = function() end
        -- Code actions do not need Saga's background symbol tracking.
        vim.api.nvim_clear_autocmds({ group = 'LspsagaSymbols' })
    end,
}
