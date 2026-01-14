return {
    "kevinhwang91/nvim-ufo",
    dependencies = {"kevinhwang91/promise-async"},
    event = "BufReadPost",
    config = function()
        -- 基础设置：保持打开所有折叠，显示折叠列
        vim.o.foldcolumn = '1'
        vim.o.foldlevel = 99
        vim.o.foldlevelstart = 99
        vim.o.foldenable = true

        require('ufo').setup({
            -- 只用 treesitter，它对嵌套识别最快最简单
            provider_selector = function()
                return {'treesitter', 'indent'}
            end
        })
    end
}
