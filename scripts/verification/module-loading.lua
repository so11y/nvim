vim.opt.rtp:prepend(vim.fn.getcwd())
local imports = {}
for _, group in ipairs(require('config.modules')()) do
    for _, entry in ipairs(group.import()) do
        assert(
            not imports[entry.name],
            'Duplicate module entry: ' .. entry.name
        )
        imports[entry.name] = entry
    end
end

for _, name in ipairs({
    'modules.ui.folding',
    'modules.ui.heirline',
    'modules.ui.bufferline',
    'modules.language.lsp',
    'modules.language.formatting',
    'modules.tools.mason',
    'modules.tools.snacks',
    'modules.editor.treesitter',
}) do
    assert(imports[name], 'Module was not discovered: ' .. name)
end

for _, name in ipairs({
    'modules.ui.heirline.components',
    'modules.ui.heirline.statusline',
    'modules.ui.bufferline.git',
    'modules.ui.bufferline.separators',
    'modules.language.formatting.oxfmt',
    'modules.language.lsp.setup',
    'modules.language.lsp.servers.vtsls',
    'modules.tools.snacks.alt_help',
    'modules.editor.treesitter.textobjects',
}) do
    assert(not imports[name], 'Helper was discovered as an entry: ' .. name)
end

vim.opt.rtp:prepend(vim.fn.stdpath('data') .. '/lazy/lazy.nvim')
local config = require('lazy.core.config')
config.options = vim.deepcopy(config.defaults)
local Spec = require('lazy.core.plugin').Spec
local entries =
    { imports['modules.ui.folding'], imports['modules.ui.heirline'] }

vim.opt.foldcolumn = '0'
local native = Spec.new(imports['modules.ui.folding'], { pkg = false })
assert(#native.notifs == 0, vim.inspect(native.notifs))
assert(vim.o.foldcolumn == '1', 'Native module did not apply its options')
assert(next(native.plugins) == nil, 'Native module became a plugin')
local initial = Spec.new(imports['modules.ui.heirline'], { pkg = false })
assert(#initial.notifs == 0, vim.inspect(initial.notifs))
local plugin = initial.plugins['heirline.nvim']
assert(
    plugin and plugin[1] == 'rebelot/heirline.nvim',
    'Plugin declaration was lost'
)
assert(plugin.event == 'VeryLazy', 'Plugin loading event changed')
assert(not package.loaded.heirline, 'Plugin initialized during discovery')
assert(
    not package.loaded['modules.ui.heirline.components'],
    'Plugin helpers loaded before plugin initialization'
)
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'first', 'second', 'third' })
vim.wo.foldmethod = 'manual'
vim.cmd('1,3fold')
vim.cmd('normal! zM')
assert(vim.fn.foldclosed(1) == 1, 'Test fold did not close')

local previous = package.loaded['modules.ui.heirline']
local reloaded = Spec.new(entries, { pkg = false })
assert(#reloaded.notifs == 0, vim.inspect(reloaded.notifs))
assert(
    vim.wo.foldlevel == 0 and vim.fn.foldclosed(1) == 1,
    'Lazy reload reset the closed fold'
)
assert(vim.wo.foldmethod == 'manual', 'Lazy reload reset window options')
assert(
    package.loaded['modules.ui.heirline'] ~= previous,
    'Lazy reload did not reread the plugin declaration'
)
assert(reloaded.plugins['heirline.nvim'].event == 'VeryLazy')
assert(not package.loaded.heirline, 'Lazy reload initialized the plugin early')
assert(vim.v.errmsg == '', vim.v.errmsg)
print(
    'PASS: module discovery, private helpers, lazy loading and preserved folds on reload'
)
