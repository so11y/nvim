local lines = {
    '<template>',
    '  <ScopeLayout un-gap isFull>',
    '    <template #topLeft>',
    '      <el-button @click="registerDialogControl.createView()" type="primary">',
    '      </el-button>',
    '    </template>',
    '    <PageCore />',
    '    <registerDialogControl.Drawer size="700">',
    '      <registerDialog />',
    '    </registerDialogControl.Drawer>',
    '    <Dialog.Drawer.Panel>',
    '    </Dialog.Drawer.Panel>',
    '    <Dialog.Drawer.Panel />',
    '    <input .value="value" />',
    '  </ScopeLayout>',
    '</template>',
    '<script setup>',
    'const value = 1',
    '</script>',
}
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_set_current_buf(buf)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
vim.bo[buf].filetype = 'vue'
vim.wo.foldenable = false
vim.wo.cursorline = false
vim.wo.cursorcolumn = false
vim.api.nvim_win_set_cursor(0, { 18, 0 })
vim.treesitter.get_parser(buf):parse(true)

local function color(row, col)
    local pos = vim.fn.screenpos(0, row, col)
    assert(pos.row > 0, 'Test position is not visible')
    return vim.fn.screenattr(pos.row, pos.col)
end

local tags = {}
for row, line in ipairs(lines) do
    local first, last, name = line:find('</?([%w_.-]+)')
    if name then
        tags[#tags + 1] = {
            row = row,
            first = last - #name + 1,
            last = last,
            name = name,
        }
    end
end

local function check_tags()
    vim.cmd.redraw()
    local expected = color(1, 2)
    for _, tag in ipairs(tags) do
        for col = tag.first, tag.last do
            assert(
                color(tag.row, col) == expected,
                ('Different tag color: %s at %d:%d'):format(
                    tag.name,
                    tag.row,
                    col
                )
            )
        end
    end
    local attribute = assert(lines[14]:find('value', 1, true))
    assert(color(14, attribute) ~= expected, '.value binding became a tag')
    assert(color(8, 35) ~= expected, 'size attribute became a tag')
    assert(color(18, 7) ~= expected, 'Script variable became a tag')
    return expected
end

local before = check_tags()
-- Reproduce the overlapping LSP type/modifier colors deterministically.
local namespace = vim.api.nvim_create_namespace('test.vue-tag-semantic-colors')
local groups = {
    '@lsp.type.class.vue',
    '@lsp.typemod.variable.readonly.vue',
    '@lsp.type.property.vue',
}
local function semantic(row, first, last, group)
    vim.api.nvim_buf_set_extmark(buf, namespace, row - 1, first - 1, {
        end_col = last,
        hl_group = group,
        priority = vim.hl.priorities.semantic_tokens + 2,
    })
end
for index, tag in ipairs(tags) do
    if tag.row ~= 1 then
        semantic(tag.row, tag.first, tag.last, groups[(index % #groups) + 1])
    end
end
semantic(18, 7, 11, groups[1])
local after = check_tags()
assert(before == after, 'Semantic tokens changed tag colors')
vim.cmd.colorscheme('vscode')
check_tags()
return { tags = #tags, semantic_overlay = true, errmsg = vim.v.errmsg }
