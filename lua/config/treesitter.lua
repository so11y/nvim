local M = {
    parsers = {
        'vue',
        'typescript',
        'tsx',
        'javascript',
        'html',
        'css',
        'scss',
        'lua',
        'bash',
        'markdown',
        'markdown_inline',
        'json',
        'rust',
    },
}

function M.install()
    require('config.mason_tools').ensure_cli()
    if
        vim.fn.has('win32') == 1
        and not vim.env.CC
        and vim.fn.executable('gcc') == 1
    then
        vim.env.CC = 'gcc'
    end
    local treesitter = require('nvim-treesitter')
    assert(
        treesitter.install(M.parsers):wait(300000),
        'Parser installation failed; see :messages'
    )
    assert(
        treesitter.update(M.parsers):wait(300000),
        'Parser update failed; see :messages'
    )
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
    vim.keymap.set('x', '<CR>', 'an', {
        remap = true,
        desc = '扩展语法选区',
    })
    vim.keymap.set('x', '<BS>', 'in', {
        remap = true,
        desc = '收缩语法选区',
    })
end

return M
