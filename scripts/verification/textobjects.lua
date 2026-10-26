-- Run: nvim --headless -u NONE -i NONE -n -l scripts/verification/textobjects.lua
local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h:h')
local data = vim.fn.stdpath('data')
vim.opt.rtp:prepend(root)
vim.opt.rtp:append(data .. '/site')
for _, name in ipairs({ 'nvim-treesitter-textobjects', 'nvim-treesitter' }) do
    vim.opt.rtp:append(data .. '/lazy/' .. name)
end
local spec = dofile(root .. '/lua/modules/editor/treesitter/init.lua')[2]
spec.config(nil, spec.opts)
vim.opt.swapfile = false
vim.opt.undofile = false
local report = { checks = 0 }
local function equal(actual, expected, name)
    assert(
        vim.deep_equal(actual, expected),
        name .. ': ' .. vim.inspect(actual)
    )
    report.checks = report.checks + 1
end
local function scratch(lang, text, row, col)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_buf_set_lines(
        buf,
        0,
        -1,
        false,
        vim.split(text, '\n', { plain = true })
    )
    vim.bo[buf].filetype = lang
    vim.api.nvim_win_set_cursor(0, { row or 1, col or 0 })
    return buf
end
local observed
vim.api.nvim_create_user_command('TextobjectsTestObserve', function()
    local mode = vim.fn.mode(1)
    observed = {
        mode = mode,
        cursor = vim.api.nvim_win_get_cursor(0),
        text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n'),
    }
end, {})
local function act(keys)
    observed = nil
    vim.api.nvim_feedkeys(
        vim.keycode(keys .. '<Cmd>TextobjectsTestObserve<CR><Esc>'),
        'xt',
        false
    )
    assert(observed, 'Observer not reached: ' .. keys)
    return observed
end
local function selection(lang, source, keys, expected, row, col)
    scratch(lang, source, row, col)
    act(keys .. 'y')
    equal(vim.fn.getreg('"'), expected, lang .. ' ' .. keys)
end

-- The first action must evaluate Vue queries before any selection callback.
scratch('vue', '<template>\n<div v-for="x in xs">x</div>\n</template>')
equal(act(']l').cursor, { 2, 0 }, 'first-action Vue loop motion')

for _, directive in ipairs({
    'v-for="x in xs"',
    'v-if="ok"',
    'v-else-if="more"',
    'v-else',
}) do
    local id = directive:find('v-for', 1, true) and 'l' or 'd'
    local inner = '\n  你好😀<b>A</b><!-- comment -->{{ x }}\n'
    local element = '<div ' .. directive .. '>' .. inner .. '</div>'
    local source = '<template>\n' .. element .. '\n</template>'
    selection('vue', source, 'va' .. id, element, 2, 2)
    selection('vue', source, 'vi' .. id, inner, 2, 2)
    local tag = '<Item ' .. directive .. ' />'
    selection(
        'vue',
        '<template>\n' .. tag .. '\n</template>',
        'va' .. id,
        tag,
        2,
        2
    )
end
selection(
    'vue',
    '<template><div v-if="ok">   </div></template>',
    'vid',
    '   ',
    1,
    12
)
selection(
    'vue',
    '<template><div v-if="ok"><span v-if="child">child</span>tail</div></template>',
    'vid',
    'child',
    1,
    30
)

local entered_insert = 0
local enter = vim.api.nvim_create_autocmd('InsertEnter', {
    callback = function()
        entered_insert = entered_insert + 1
    end,
})
local empty_source =
    '<template>\n<Item v-if="ok" />\n<div v-else-if="more"></div>\n<Item v-else />\n<div v-if="next">OTHER</div>\n<Item v-for="x in xs" />\n<div v-for="x in xs"></div>\n<div v-for="x in xs">NEXT</div>\n</template>'
for _, case in ipairs({
    { 2, 'id' },
    { 3, 'id' },
    { 4, 'id' },
    { 6, 'il' },
    { 7, 'il' },
}) do
    for _, prefix in ipairs({ 'd', 'c', '2d', '2c', 'v' }) do
        local buf = scratch('vue', empty_source, case[1], 2)
        local tick = vim.api.nvim_buf_get_changedtick(buf)
        local inserts = entered_insert
        vim.fn.setreg('"', 'KEEP')
        local result = act(prefix .. case[2])
        equal(
            result.text,
            empty_source,
            'empty inner text: ' .. prefix .. case[2]
        )
        equal(result.mode, 'n', 'empty inner mode')
        equal(result.cursor, { case[1], 2 }, 'empty inner cursor')
        equal(vim.fn.getreg('"'), 'KEEP', 'empty inner register')
        equal(
            vim.api.nvim_buf_get_changedtick(buf),
            tick,
            'empty inner changedtick'
        )
        equal(entered_insert, inserts, 'empty inner never enters Insert')
    end
end
vim.api.nvim_del_autocmd(enter)

for _, lang in ipairs({ 'javascript', 'typescript', 'tsx' }) do
    for _, source in ipairs({
        'let value = getValue();',
        'return value;',
        'foo();',
        'let value = getValue()',
        'if (ok) { foo(); }',
        'if (ok) foo();',
        'do { foo(); } while (ok);',
        'const text = "你好😀";',
        'const text = "ends;inside"',
    }) do
        selection(lang, source, 'vas', source)
        selection(lang, source, 'vis', (source:gsub(';$', '')))
    end
    selection(lang, 'function f() { return x; }', 'vis', 'return x', 1, 15)
    selection(
        lang,
        'function f() { return x; }',
        'vis',
        'function f() { return x; }',
        1,
        0
    )
    selection(
        lang,
        'let value = f();\nlet other = g();',
        'v2is',
        'let value = f()'
    )
    selection(
        lang,
        'let value = f();\nlet other = g();',
        'v2as',
        'let value = f();'
    )
end
for _, script in ipairs({ '<script>', '<script setup lang="ts">' }) do
    selection(
        'vue',
        script
            .. '\nlet value = getValue();\n</script>\n<template><div>text;</div></template>',
        'vis',
        'let value = getValue()',
        2,
        0
    )
end
selection(
    'vue',
    '<template><div>text;</div></template>',
    'vis',
    '<div>text;</div>',
    1,
    12
)
selection('rust', 'fn f() { let value = f(); }', 'vis', 'let value = f()', 1, 9)
selection('lua', 'local value = f()', 'vis', 'local value = f()')
for _, lang in ipairs({ 'text', 'json' }) do
    for _, keys in ipairs({ 'dis', 'cis', 'das', 'cas' }) do
        scratch(
            lang,
            lang == 'json' and '{"a":1}' or 'First sentence. Second sentence.',
            1,
            2
        )
        local before = vim.api.nvim_get_current_line()
        local result = act(keys)
        equal(result.text, before, 'unsupported ' .. lang .. ' ' .. keys)
        equal(result.mode, 'n', 'unsupported cancels operator')
    end
end

for _, selection_option in ipairs({ 'inclusive', 'exclusive' }) do
    vim.o.selection = selection_option
    selection(
        'javascript',
        'function f() { return "你好😀"; }',
        'vif',
        'return "你好😀";',
        1,
        0
    )
    selection('javascript', 'foo(a, b);', 'vic', '(a, b)', 1, 0)
    selection('javascript', 'foo(a, b);', 'vic', 'a, b', 1, 4)
    selection('javascript', 'foo(a, b);', 'via', 'b', 1, 7)
    selection(
        'javascript',
        'const text = "你好😀";',
        'vis',
        'const text = "你好😀"'
    )
    selection(
        'javascript',
        'const text = "你好😀"',
        'vis',
        'const text = "你好😀"'
    )
    selection(
        'vue',
        '<template><div v-if="ok">你好😀</div></template>',
        'vid',
        '你好😀',
        1,
        12
    )
end
vim.o.selection = 'inclusive'
scratch('javascript', 'let value = f();')
equal(act('dis').text, ';', 'dis preserves terminator')
scratch('javascript', 'let value = f();')
equal(act('cisREPLACED<Esc>').text, 'REPLACED;', 'cis preserves terminator')
scratch('javascript', 'let value = f();\nnext();')
equal(act('Vis').mode, 'V', 'linewise Visual preserved')
scratch('javascript', 'let value = f();\nnext();')
equal(act('dVis').text, 'next();', 'forced linewise operator preserved')
equal(vim.v.errmsg, '', 'no editor errors')
vim.api.nvim_del_user_command('TextobjectsTestObserve')
print(vim.json.encode(report))
return report
