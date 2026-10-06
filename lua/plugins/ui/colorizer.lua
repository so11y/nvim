local sass = {
    parsers = { sass = { enable = true, parsers = { css = true } } },
    debounce_ms = 100,
}

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

local function setup_vue_sass()
    local parser = require('colorizer.parser.sass')
    local update = parser.update_variables
    parser.update_variables = function(bufnr, first, last, lines, ...)
        if vim.bo[bufnr].filetype ~= 'vue' then
            return update(bufnr, first, last, lines, ...)
        end
        local contents = {}
        local tree = vim.treesitter.get_parser(bufnr, 'vue'):parse()[1]
        for child in tree:root():iter_children() do
            if child:type() == 'style_element' then
                for body in child:iter_children() do
                    if body:type() == 'raw_text' then
                        vim.list_extend(
                            contents,
                            vim.split(
                                vim.treesitter.get_node_text(body, bufnr),
                                '\n',
                                { plain = true }
                            )
                        )
                    end
                end
            end
        end
        -- The Sass parser owns linewise definitions; clear removed style lines.
        local previous = vim.b[bufnr].colorizer_vue_sass_lines or 0
        vim.b[bufnr].colorizer_vue_sass_lines = #contents
        for index = #contents + 1, previous do
            contents[index] = ''
        end
        return update(bufnr, 0, #contents, contents, ...)
    end
end

return {
    'NvChad/nvim-colorizer.lua',
    event = { 'BufReadPost', 'BufNewFile' },
    config = function(_, opts)
        setup_vue_sass()
        require('colorizer').setup(opts)
    end,
    opts = {
        filetypes = {
            '*',
            scss = sass,
            sass = sass,
            vue = vim.tbl_extend('force', sass, {
                hooks = { should_highlight_color = vue_style_color },
            }),
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
