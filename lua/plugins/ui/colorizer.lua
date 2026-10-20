local function vue_style_color(_, _, match)
    vim.treesitter.get_parser(match.bufnr, 'vue'):parse()
    local node = vim.treesitter.get_node({
        bufnr = match.bufnr,
        pos = { match.line_nr, match.col - 1 },
        ignore_injections = true,
    })
    while node do
        local kind = node:type()
        if kind == 'style_element' then
            return true
        end
        if kind == 'attribute' or kind == 'directive_attribute' then
            local name = node:named_child(0)
            local text = name
                and vim.treesitter.get_node_text(name, match.bufnr)
            return text == 'style' or text == 'class'
        end
        node = node:parent()
    end
    return false
end

return {
    'NvChad/nvim-colorizer.lua',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {
        filetypes = {
            '*',
            vue = {
                hooks = { should_highlight_color = vue_style_color },
            },
        },
        options = {
            parsers = {
                hex = { default = true, rrggbbaa = true, aarrggbb = true },
                css_fn = true,
                tailwind = { enable = true },
            },
            display = {
                mode = 'virtualtext',
                virtualtext = { char = '■', position = 'after' },
            },
        },
    },
}
