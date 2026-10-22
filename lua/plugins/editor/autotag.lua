return {
    {
        'windwp/nvim-ts-autotag',
        event = { 'BufReadPre', 'BufNewFile' },
        opts = {
            opts = {
                enable_rename = false,
            },
        },
    },
}
