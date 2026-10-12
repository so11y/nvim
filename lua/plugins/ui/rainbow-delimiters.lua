return {
    'HiPhish/rainbow-delimiters.nvim',
    main = 'rainbow-delimiters.setup',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {
        highlight = {
            'RainbowDelimiterBlue',
            'RainbowDelimiterGreen',
            'RainbowDelimiterYellow',
            'RainbowDelimiterOrange',
            'RainbowDelimiterRed',
            'RainbowDelimiterViolet',
        },
        query = {
            javascript = 'rainbow-delimiters',
        },
    },
}
