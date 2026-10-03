require('lazy').load({ plugins = { 'nvim-colorizer.lua' } })

local config = require('colorizer.config')
local current = config.get_bo_options('filetype', '', 'typescript')
    or config.options.options
local previous = vim.deepcopy(current)
previous.parsers.sass = { enable = true, parsers = { css = true } }

local bufnr = vim.api.nvim_create_buf(false, true)
local lines = {}
for i = 1, 20000 do
    lines[i] = ('export const value%d = someFunction(argument);'):format(i)
end
vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

local ns = vim.api.nvim_create_namespace('colorizer-performance')
local results = { previous = {}, current = {} }
for i = 1, 8 do
    local order = i % 2 == 0 and { 'current', 'previous' }
        or { 'previous', 'current' }
    for _, name in ipairs(order) do
        local options = name == 'current' and current or previous
        local start = vim.uv.hrtime()
        require('colorizer.buffer').highlight(bufnr, ns, 0, 40, options, {
            __event = 'TextChangedI',
        })
        table.insert(results[name], (vim.uv.hrtime() - start) / 1e6)
    end
end
for _, samples in pairs(results) do
    table.sort(samples)
end
local median = function(samples)
    return (samples[4] + samples[5]) / 2
end
local vue = config.get_bo_options('filetype', '', 'vue')
local scss = config.get_bo_options('filetype', '', 'scss')

return {
    neovim = tostring(vim.version()),
    lines = #lines,
    visible_lines = 40,
    samples_ms = results,
    median_ms = {
        previous = median(results.previous),
        current = median(results.current),
    },
    sass_enabled = {
        typescript = current.parsers.sass.enable,
        vue = vue.parsers.sass.enable,
        scss = scss.parsers.sass.enable,
    },
    debounce_ms = {
        typescript = current.debounce_ms,
        vue = vue.debounce_ms,
        scss = scss.debounce_ms,
    },
}
