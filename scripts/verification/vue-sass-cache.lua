-- Run: nvim --headless -u NONE -i NONE -n -l scripts/verification/vue-sass-cache.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
for _, name in ipairs({ 'nvim-treesitter', 'nvim-colorizer.lua' }) do
    vim.opt.rtp:append(vim.fn.stdpath('data') .. '/lazy/' .. name)
end
require('nvim-treesitter').setup()
vim.o.eventignore = 'all'
vim.o.termguicolors = true
-- Deliver import notifications explicitly so this test is independent of OS timing.
local watchers, handles = {}, {}
require('colorizer.utils').watch_file = function(file, callback)
    watchers[file] = callback
    local handle = vim.uv.new_fs_event()
    handles[#handles + 1] = handle
    return handle
end
local sass = require('colorizer.parser.sass')
local update, calls = sass.update_variables, 0
sass.update_variables = function(...)
    calls = calls + 1
    return update(...)
end
local spec = require('plugins.ui.colorizer')
spec.config(nil, spec.opts)
local directory = vim.fn.tempname()
vim.fn.mkdir(directory, 'p')
local imported = directory .. '/_colors.scss'
vim.fn.writefile({ '$imported: #0000ff;' }, imported)
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_set_current_buf(buf)
vim.api.nvim_buf_set_name(buf, directory .. '/component.vue')
vim.bo.filetype = 'vue'
local opts = require('colorizer.config').new_bo_options(buf, 'filetype')
local buffer = require('colorizer.buffer')
local local_opts = { __event = 'TextChangedI' }
local ns = vim.api.nvim_create_namespace('vue-sass-cache-test')
local function highlight()
    buffer.highlight(buf, ns, 0, 1, opts, local_opts)
end
local function contents(lines)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    highlight()
end
local function variable(name, expected)
    local _, value = sass.parser('$' .. name, 1, buf)
    assert(value == expected, name .. ': ' .. vim.inspect(value))
end
contents({
    '<script setup>const value = 1</script>',
    '<template><p>{{ value }}</p></template>',
    '<style lang="scss">',
    '@use "colors";',
    '$accent: #ff0000;',
    '$alias: $accent;',
    '</style>',
    '<style lang="scss">$second: #00ff00;</style>',
})
variable('accent', 'ff0000')
variable('alias', 'ff0000')
variable('second', '00ff00')
variable('imported', '0000ff')
local initial = calls
for i = 1, 20 do
    vim.api.nvim_buf_set_lines(buf, 0, 1, false, {
        ('<script setup>const value = %d</script>'):format(i),
    })
    highlight()
end
assert(calls == initial, 'Script edits rebuilt unchanged Sass definitions')
vim.api.nvim_buf_set_lines(buf, 1, 1, false, { '<!-- move styles down -->' })
highlight()
assert(calls == initial, 'Moving an unchanged style rebuilt Sass definitions')
vim.api.nvim_buf_set_lines(buf, 5, 6, false, { '$accent: #112233;' })
highlight()
assert(calls == initial + 1)
variable('accent', '112233')
variable('alias', '112233')
-- Import watchers must bypass the unchanged inline-style cache.
vim.fn.writefile({ '$imported: #ff00ff;' }, imported)
watchers[vim.uv.fs_realpath(imported)]()
variable('imported', 'ff00ff')
local_opts.__event = 'TextChangedI'
local before_cleanup = calls
sass.cleanup(buf)
highlight()
assert(
    calls == before_cleanup + 1,
    'Cleanup left a cache without Sass definitions'
)
variable('accent', '112233')
contents({ '<style lang="scss">$accent: #aabbcc;</style>' })
variable('accent', 'aabbcc')
variable('alias', nil)
variable('second', nil)
variable('imported', nil)
contents({ '<template><p>no styles</p></template>' })
variable('accent', nil)
sass.cleanup(buf)
vim.api.nvim_buf_delete(buf, { force = true })
for _, handle in ipairs(handles) do
    handle:close()
end
vim.fn.delete(imported)
vim.fn.delete(directory, 'd')
print(
    'PASS: script edits, shifted styles, style edits, imports, cleanup and removed definitions'
)
