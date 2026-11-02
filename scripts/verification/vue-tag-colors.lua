vim.cmd.edit(vim.env.NVIM_TEST_ROOT .. '/alpha/test.ts')
local ts_buf = vim.api.nvim_get_current_buf()
assert(
    vim.wait(15000, function()
        return #(vim.lsp.semantic_tokens.get_at_pos(ts_buf, 1, 13) or {}) > 0
    end, 50),
    'TypeScript semantic highlighting missing'
)

local lines = {
    '<script setup lang="ts">',
    "import registerDialog from './App.vue';",
    'const registerDialogControl = { Drawer: registerDialog };',
    'const Dialog = { Drawer: { Panel: registerDialog } };',
    "const value = 'test';",
    '</script>',
    '<template>',
    '  <registerDialogControl.Drawer size="700">',
    '  </registerDialogControl.Drawer>',
    '  <registerDialogControl.Drawer />',
    '  <Dialog.Drawer.Panel>',
    '  </Dialog.Drawer.Panel>',
    '  <Dialog.Drawer.Panel />',
    '  <registerDialog />',
    '  <input .value="value" />',
    '</template>',
}
local path = vim.env.NVIM_TEST_ROOT .. '/alpha/MemberTags.vue'
vim.fn.writefile(lines, path)
vim.cmd.edit(path)
local buf = vim.api.nvim_get_current_buf()
vim.wo.foldenable = false
vim.wo.cursorline = false
vim.wo.cursorcolumn = false
vim.diagnostic.enable(false, { bufnr = buf })
vim.api.nvim_win_set_cursor(0, { 1, 0 })

for _, name in ipairs({ 'vue_ls', 'vtsls' }) do
    assert(
        vim.wait(15000, function()
            local client = vim.lsp.get_clients({ bufnr = buf, name = name })[1]
            return client and client.initialized
        end, 50),
        name .. ' missing'
    )
end

local function column(row, word)
    local col = assert(lines[row]:find(word, 1, true))
    return col
end
assert(
    not vim.lsp.semantic_tokens.is_enabled({ bufnr = buf }),
    'Vue semantic highlighting still enabled'
)
assert(
    vim.lsp.semantic_tokens.is_enabled({ bufnr = ts_buf }),
    'Vue disabled TypeScript semantic highlighting'
)
local ts_client = vim.lsp.get_clients({ bufnr = buf, name = 'vtsls' })[1]
local hover = ts_client:request_sync('textDocument/hover', {
    textDocument = { uri = vim.uri_from_bufnr(buf) },
    position = { line = 2, character = 6 },
}, 10000, buf)
assert(
    hover and hover.result and hover.result.contents,
    'Vue LSP hover stopped working'
)

local function color(row, word)
    local pos = vim.fn.screenpos(0, row, column(row, word))
    assert(pos.row > 0, 'Test position is not visible')
    return vim.fn.screenattr(pos.row, pos.col)
end
local function check()
    vim.cmd.redraw()
    local result = {}
    for _, case in ipairs({
        {
            rows = { 8, 9, 10 },
            owner = 'registerDialogControl',
            member = 'Drawer',
        },
        { rows = { 11, 12, 13 }, owner = 'Dialog', member = 'Panel' },
    }) do
        local owner = color(case.rows[1], case.owner)
        local member = color(case.rows[1], case.member)
        assert(
            owner ~= member,
            'Object and component lost their distinct colors'
        )
        for _, row in ipairs(case.rows) do
            assert(color(row, case.owner) == owner, 'Object colors differ')
            assert(color(row, case.member) == member, 'Component colors differ')
        end
        result[#result + 1] = { owner = owner, member = member }
    end
    assert(
        color(11, 'Drawer') == color(12, 'Drawer'),
        'Intermediate member differs'
    )
    assert(
        color(11, 'Drawer') == color(11, 'Panel'),
        'Dotted members have different syntax colors'
    )
    assert(
        color(15, 'input') ~= color(15, 'value'),
        '.value binding became a tag'
    )
    return result
end
local colors = check()
vim.cmd.colorscheme('vscode')
check()
for row = 8, 15 do
    lines[row] = '  ' .. lines[row]
end
vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
check()

for _ = 1, 80 do
    table.insert(lines, 9, '')
end
vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
vim.api.nvim_win_set_cursor(0, { 89, 0 })
vim.cmd.normal({ args = { 'zz' }, bang = true })
vim.cmd.redraw()
assert(vim.fn.screenpos(0, 8, 1).row == 0, 'Opening tag is still on screen')
assert(
    color(89, 'Drawer') == color(90, 'Drawer'),
    'Off-screen opening changed closing color'
)
assert(
    color(89, 'Drawer') ~= color(89, 'registerDialogControl'),
    'Off-screen case lost distinct colors'
)
vim.api.nvim_set_current_buf(ts_buf)
assert(
    vim.lsp.semantic_tokens.is_enabled({ bufnr = ts_buf }),
    'TypeScript semantics changed after Vue edits'
)
assert(
    #(vim.lsp.semantic_tokens.get_at_pos(ts_buf, 1, 13) or {}) > 0,
    'TypeScript semantic tokens were cleared'
)
assert(
    not vim.lsp.semantic_tokens.is_enabled({ bufnr = buf }),
    'Vue semantics restarted after edits'
)
return {
    colors = colors,
    vue_semantic_tokens = false,
    typescript_semantic_tokens = true,
    vue_hover = true,
    unsaved_edit = true,
    offscreen_opening = true,
    errmsg = vim.v.errmsg,
}
