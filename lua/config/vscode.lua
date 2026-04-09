if not vim.g.vscode then
    return
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  禁用插件
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
vim.g.vscode_disabled_plugins = { -- completion
'neovim/nvim-lspconfig', 'williamboman/mason.nvim', 'williamboman/mason-lspconfig.nvim', 'saghen/blink.cmp',
'mrcjkb/rustaceanvim', 'esmuellert/nvim-eslint', -- ui
'akinsho/bufferline.nvim', 'nvim-neo-tree/neo-tree.nvim', 'folke/noice.nvim', 'rebelot/heirline.nvim',
'Bekaboo/dropbar.nvim', 'NvChad/nvim-colorizer.lua', 'HiPhish/rainbow-delimiters.nvim', 'nvim-zh/colorful-winsep.nvim',
'rachartier/tiny-code-action.nvim', 'rachartier/tiny-inline-diagnostic.nvim', 'petertriho/nvim-scrollbar', -- tool
'folke/snacks.nvim', 'folke/persistence.nvim', 'lewis6991/gitsigns.nvim', 'folke/which-key.nvim', 'nvzone/showkeys',
'MagicDuck/grug-far.nvim', 'folke/lazydev.nvim', -- editor
'kevinhwang91/nvim-ufo', 'stevearc/conform.nvim', 'mfussenegger/nvim-dap', 'smjonas/inc-rename.nvim',
'windwp/nvim-autopairs', 'windwp/nvim-ts-autotag', 'catppuccin/nvim', 'tris203/precognition.nvim'}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  快捷键
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local vscode = require('vscode')
local map = vim.keymap.set

vim.opt.shortmess:append('sS')
-- https://github.com/vscode-neovim/vscode-neovim/issues/2507
vim.o.cmdheight = 50

map("n", "j", function()
    if vim.v.count == 0 then
        vscode.call("cursorDown")
    else
        return "j"
    end
end, {
    expr = true,
    silent = true
})

map("n", "k", function()
    if vim.v.count == 0 then
        vscode.call("cursorUp")
    else
        return "k"
    end
end, {
    expr = true,
    silent = true
})

-- LSP
map('n', '<leader>cr', function()
    vscode.action('editor.action.rename')
end, {
    desc = '代码重命名'
})

map({'n', 'v'}, '<leader>ca', function()
    vscode.action('editor.action.quickFix')
end, {
    desc = 'Code Action'
})

map('n', 'gr', function()
    vscode.action('editor.action.goToReferences')
end, {
    desc = '转到引用'
})

map('n', '<leader>h', function()
    vscode.action('editor.action.showHover')
end, {
    desc = '悬停提示'
})

map('n', 'za', function()
    vscode.action('editor.toggleFold')
end, {
    desc = '折叠切换'
})

-- 查找
map('n', '<leader>fs', function()
    vscode.action('workbench.action.quickOpen')
end, {
    desc = '文件查找'
})
map('n', '<leader>fg', function()
    vscode.action('workbench.action.findInFiles')
end, {
    desc = '全局搜索'
})

-- 分屏（垂直/水平）
map('n', '<leader>sv', function()
    vscode.action('workbench.action.splitEditorRight')
end, {
    desc = '垂直分屏'
})
map('n', '<leader>sh', function()
    vscode.action('workbench.action.splitEditorDown')
end, {
    desc = '水平分屏'
})

-- 符号 / 终端
-- map({'n', 't'}, '<A-t>', function()
--     vscode.action('workbench.action.terminal.toggleTerminal')
-- end, {
--     desc = '切换终端'
-- })

-- 窗口大小
-- map('n', '<A-Up>', function()
--     vscode.action('workbench.action.increaseViewSize')
-- end, {
--     desc = '增加窗口大小'
-- })
-- map('n', '<A-Down>', function()
--     vscode.action('workbench.action.decreaseViewSize')
-- end, {
--     desc = '减少窗口大小'
-- })

-- 可重复诊断跳转
vim.api.nvim_create_autocmd('User', {
    pattern = 'LazyDone',
    once = true,
    callback = function()
        require('utils.repeatable').map_jump('gjx', 'gkx', function()
            vscode.action('editor.action.marker.next')
        end, function()
            vscode.action('editor.action.marker.prev')
        end, '下一个诊断', '上一个诊断')

    end
})
