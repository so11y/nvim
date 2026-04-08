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
    'catppuccin/nvim',
    'tris203/precognition.nvim',
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  快捷键
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local vsc = require('vscode')
local map = vim.keymap.set

-- LSP
map({ 'n', 'v' }, '<leader>ca', function() vsc.action('editor.action.quickFix') end,          { desc = 'Code Action' })
map('n',          'gr',          function() vsc.action('editor.action.goToReferences') end,    { desc = '转到引用' })
map('n',          '<leader>h',   function() vsc.action('editor.action.showHover') end,         { desc = '悬停提示' })
map('n',          '<leader>cr',  function() vsc.action('editor.action.rename') end,            { desc = '重命名' })
map({ 'n', 'v' }, '<leader>cf',  function() vsc.action('editor.action.formatDocument') end,    { desc = '格式化' })
map('n',          'za',          function() vsc.action('editor.toggleFold') end,               { desc = '折叠切换' })

-- 查找
map('n', '<leader>fs', function() vsc.action('workbench.action.quickOpen') end,                { desc = '文件查找' })
map('n', '<leader>fg', function() vsc.action('workbench.action.findInFiles') end,              { desc = '全局搜索' })

-- 符号 / 终端
map('n',          '<A-o>', function() vsc.action('workbench.action.gotoSymbol') end,           { desc = '文档符号' })
map({ 'n', 't' }, '<A-t>', function() vsc.action('workbench.action.terminal.toggleTerminal') end, { desc = '切换终端' })

-- 跳转历史（VSCode jumplist 替代 Neovim 的 C-o/C-i）
map('n', '<A-u>', function() vsc.action('workbench.action.navigateBack') end,                  { desc = '光标位置撤销' })
map('n', '<A-i>', function() vsc.action('workbench.action.navigateForward') end,               { desc = '光标位置重做' })

-- 窗口大小
map('n', '<A-Up>',   function() vsc.action('workbench.action.increaseViewSize') end,           { desc = '增加窗口大小' })
map('n', '<A-Down>', function() vsc.action('workbench.action.decreaseViewSize') end,           { desc = '减少窗口大小' })

-- 可重复诊断跳转
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
