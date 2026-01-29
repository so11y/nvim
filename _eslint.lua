local lsp = vim.lsp

local eslint_files = {'.eslintrc', '.eslintrc.js', '.eslintrc.cjs', '.eslintrc.json', '.eslintrc.yaml', '.eslintrc.yml',
                      'eslint.config.js', 'eslint.config.mjs', 'eslint.config.cjs'}

---@type vim.lsp.Config
return {
    cmd = {'vscode-eslint-language-server', '--stdio'},

    filetypes = {'javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'vue'},

    workspace_required = true,

    on_attach = function(client, bufnr)
        vim.api.nvim_buf_create_user_command(bufnr, 'LspEslintFixAll', function()
            client:request_sync('workspace/executeCommand', {
                command = 'eslint.applyAllFixes',
                arguments = {{
                    uri = vim.uri_from_bufnr(bufnr),
                    version = lsp.util.buf_versions[bufnr]
                }}
            }, nil, bufnr)
        end, {})

    end,

    root_dir = function(bufnr, on_dir)
        -- ❌ 排除 Deno
        if vim.fs.root(bufnr, {'deno.json', 'deno.jsonc', 'deno.lock'}) then
            return
        end

        -- 项目根：优先 lock 文件，再 .git
        local root = vim.fs.root(bufnr, {'package-lock.json', 'yarn.lock', 'pnpm-lock.yaml', '.git'})
        if not root then
            return
        end

        -- 检查项目里是否有 ESLint 配置文件
        local found = vim.fs.find(eslint_files, {
            path = root,
            upward = false,
            limit = 1
        })[1]

        print('ESLint root_dir:', root)

        if not found then
            return
        end

        on_dir(root)
    end,

    settings = {
        validate = 'on',
        format = true,
        run = 'onType',
        workingDirectory = {
            mode = 'auto'
        }
    }
}
