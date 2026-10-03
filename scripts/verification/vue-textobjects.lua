local file = vim.env.NVIM_TEST_ROOT .. '/alpha/App.vue'
vim.cmd.edit(file)
assert(
    vim.wait(10000, function()
        return vim.treesitter.get_parser(0, nil, { error = false }) ~= nil
    end, 50),
    'Vue parser missing'
)

local cases = {
    {
        name = 'function',
        row = 5,
        needle = 'greet',
        keys = 'vaf',
        expected = 'function greet() { return count.value + 1; }',
    },
    {
        name = 'function-inner',
        row = 5,
        needle = 'greet',
        keys = 'vif',
        expected = 'return count.value + 1;',
    },
    {
        name = 'call',
        row = 3,
        needle = 'ref',
        keys = 'vac',
        expected = 'ref(0)',
    },
    {
        name = 'statement',
        row = 5,
        needle = 'return',
        keys = 'vas',
        expected = 'return count.value + 1;',
    },
    {
        name = 'template-tag',
        row = 7,
        needle = 'button',
        keys = 'vat',
        expected = '<button @click="greet">你好😀{{ count }}</button>',
    },
    {
        name = 'template-inner',
        row = 7,
        needle = 'button',
        keys = 'vit',
        expected = '你好😀{{ count }}',
    },
}

local results = {}
for _, case in ipairs(cases) do
    vim.cmd.edit(file)
    local line = vim.api.nvim_buf_get_lines(0, case.row - 1, case.row, false)[1]
    vim.api.nvim_win_set_cursor(0, {
        case.row,
        assert(line:find(case.needle, 1, true)) - 1,
    })
    vim.cmd.normal({ args = { case.keys }, bang = false })
    local selected = table.concat(
        vim.fn.getregion(vim.fn.getpos('v'), vim.fn.getpos('.'), {
            type = 'v',
        }),
        '\n'
    )
    assert(selected == case.expected, case.name .. ': ' .. selected)
    results[case.name] = selected
end

return { selected = results, errmsg = vim.v.errmsg }
