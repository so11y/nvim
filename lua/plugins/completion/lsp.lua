vim.lsp.enable 'vtsls'
vim.lsp.enable 'vue_ls'
vim.lsp.enable 'jsonls'
vim.lsp.enable 'cssls'
-- vim.lsp.enable('unocss', false)

vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)

        vim.diagnostic.config({
            -- virtual_lines = true,
            virtual_text = false,
            -- virtual_text = {
            --     prefix = '',
            --     spacing = 4,
            --     severity = {
            --         min = vim.diagnostic.severity.ERROR
            --     }
            -- },
            signs = {
                text = {
                    [vim.diagnostic.severity.ERROR] = '󰧞', -- ● •
                    [vim.diagnostic.severity.WARN] = '󰧞',
                    [vim.diagnostic.severity.INFO] = '󰧞',
                    [vim.diagnostic.severity.HINT] = '󱐋'
                }
            },
            underline = true,
            severity_sort = true,
            update_in_insert = false
        })

        local client = vim.lsp.get_client_by_id(args.data.client_id)

        if client and client.server_capabilities.documentHighlightProvider then
            local group = vim.api.nvim_create_augroup("lsp_document_highlight", {
                clear = true
            })

            vim.api.nvim_create_autocmd({"CursorHold", "CursorHoldI"}, {
                group = group,
                buffer = args.buf,
                callback = function()
                    local node = vim.treesitter.get_node()
                    if not node then
                        return
                    end

                    local node_type = node:type()

                    local ignore_types = {"tag_name", "attribute_name", "start_tag", "end_tag", "element"}

                    if vim.tbl_contains(ignore_types, node_type) then
                        vim.lsp.buf.clear_references()
                    else
                        vim.lsp.buf.document_highlight()
                    end
                end
            })

            -- 移动光标立刻清除高亮
            vim.api.nvim_create_autocmd({"CursorMoved", "CursorMovedI"}, {
                group = group,
                buffer = args.buf,
                callback = vim.lsp.buf.clear_references
            })
        end

    end
})
return {{
    'esmuellert/nvim-eslint',
    ft = {"javascript", "typescript", "javascriptreact", "typescriptreact", "vue"},
    config = function()
        local bufnr = vim.api.nvim_get_current_buf()
        local fname = vim.api.nvim_buf_get_name(bufnr)
        if fname == "" then
            return
        end

        local git_root = vim.fs.root(bufnr, ".git")
        if not git_root then
            return
        end

        local config_root = vim.fs.root(bufnr, {
            ".eslintrc.js", 
            ".eslintrc.cjs", 
            ".eslintrc.json", 
            ".eslintrc",
            "eslint.config.js", 
            "eslint.config.mjs"})


        if config_root then
            local config_git_check = vim.fs.root(config_root, ".git")
            if config_git_check == git_root then
                require('nvim-eslint').setup({
                    root_dir = function()
                        return git_root
                    end
                })
            end
        end
    end
}}
