if not vim.g.vscode then
    return
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  禁用插件
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
vim.g.vscode_disabled_plugins = {
    -- completion
    'neovim/nvim-lspconfig',
    'williamboman/mason.nvim',
    'williamboman/mason-lspconfig.nvim',
    'saghen/blink.cmp',
    'mrcjkb/rustaceanvim',
    'esmuellert/nvim-eslint',

    -- ui
    'akinsho/bufferline.nvim',
    'nvim-neo-tree/neo-tree.nvim',
    'folke/noice.nvim',
    'rebelot/heirline.nvim',
    'Bekaboo/dropbar.nvim',
    'NvChad/nvim-colorizer.lua',
    'HiPhish/rainbow-delimiters.nvim',
    'nvim-zh/colorful-winsep.nvim',
    'rachartier/tiny-code-action.nvim',
    'rachartier/tiny-inline-diagnostic.nvim',
    'petertriho/nvim-scrollbar',

    -- tool
    'folke/snacks.nvim',
    'folke/persistence.nvim',
    'lewis6991/gitsigns.nvim',
    'folke/which-key.nvim',
    'nvzone/showkeys',
    'MagicDuck/grug-far.nvim',
    'folke/lazydev.nvim',

    -- editor
    'kevinhwang91/nvim-ufo',
    'stevearc/conform.nvim',
    'mfussenegger/nvim-dap',
    'smjonas/inc-rename.nvim',
    'windwp/nvim-autopairs',
    'windwp/nvim-ts-autotag',
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  快捷键
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local vsc = require('vscode')
local map = vim.keymap.set

map({ 'n', 'v' }, '<leader>ca', function() vsc.action('editor.action.quickFix') end,          { desc = 'Code Action' })
map('n',          'gd',          function() vsc.action('editor.action.revealDefinition') end,  { desc = '转到定义' })
map('n',          'gr',          function() vsc.action('editor.action.goToReferences') end,    { desc = '转到引用' })
map('n',          '<leader>k',   function() vsc.action('editor.action.showHover') end,         { desc = '悬停提示' })
map('n',          'za',          function() vsc.action('editor.toggleFold') end,               { desc = '折叠切换' })

vim.api.nvim_create_autocmd('User', {
    pattern = 'LazyDone',
    once = true,
    callback = function()
        require('utils.repeatable').map_jump('gjx', 'gkx',
            function() vsc.action('editor.action.marker.next') end,
            function() vsc.action('editor.action.marker.prev') end,
            '下一个诊断', '上一个诊断')
    end,
})
