return {
    'saghen/blink.indent',
    event = { 'BufReadPost', 'BufNewFile' },
    main = 'blink.indent',
    opts = {
        mappings = {
            object_scope = '',
            object_scope_with_border = '',
            goto_top = '',
            goto_bottom = '',
        },
        static = { char = '│' },
        scope = { char = '│', highlights = { 'BlinkIndentScope' } },
    },
}
