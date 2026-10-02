local M = {
    parsers = {
        'vue',
        'typescript',
        'tsx',
        'javascript',
        'html',
        'css',
        'lua',
        'bash',
        'markdown',
        'markdown_inline',
        'json',
        'rust',
    },
}

function M.install()
    local treesitter = require('nvim-treesitter')
    assert(
        treesitter.install(M.parsers):wait(300000),
        'Parser installation timed out'
    )
    return treesitter.update(M.parsers):wait(300000)
end

function M.setup()
    require('nvim-treesitter').setup()
    local group =
        vim.api.nvim_create_augroup('config.treesitter', { clear = true })
    vim.api.nvim_create_autocmd('FileType', {
        group = group,
        callback = function(ev)
            local lang =
                vim.treesitter.language.get_lang(vim.bo[ev.buf].filetype)
            if lang and vim.list_contains(M.parsers, lang) then
                vim.treesitter.start(ev.buf, lang)
                vim.bo[ev.buf].indentexpr =
                    "v:lua.require'nvim-treesitter'.indentexpr()"
            end
        end,
    })
    if vim.g.vscode then
        return
    end
    local function select(direction)
        if
            #vim.lsp.get_clients({
                bufnr = 0,
                method = 'textDocument/selectionRange',
            }) > 0
        then
            vim.lsp.buf.selection_range(direction)
        else
            vim.cmd.normal({ direction > 0 and 'an' or 'in', bang = false })
        end
    end
    vim.keymap.set('x', '<CR>', function()
        select(1)
    end, { desc = 'Expand syntax selection' })
    vim.keymap.set('x', '<BS>', function()
        select(-1)
    end, { desc = 'Shrink syntax selection' })
end

return M
