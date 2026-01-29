local util = require 'lspconfig.util'
local lsp = vim.lsp

local eslint_files = {
  '.eslintrc',
  '.eslintrc.js',
  '.eslintrc.cjs',
  '.eslintrc.json',
  '.eslintrc.yaml',
  '.eslintrc.yml',
  'eslint.config.js',
  'eslint.config.mjs',
  'eslint.config.cjs',
}

---@type vim.lsp.Config
return {
  cmd = { 'vscode-eslint-language-server', '--stdio' },

  filetypes = {
    'javascript',
    'javascriptreact',
    'typescript',
    'typescriptreact',
    'vue',
  },

  workspace_required = true,

  on_attach = function(client, bufnr)
    vim.api.nvim_buf_create_user_command(bufnr, 'LspEslintFixAll', function()
      client:request_sync('workspace/executeCommand', {
        command = 'eslint.applyAllFixes',
        arguments = {
          {
            uri = vim.uri_from_bufnr(bufnr),
            version = lsp.util.buf_versions[bufnr],
          },
        },
      }, nil, bufnr)
    end, {})
  end,

  root_dir = function(bufnr, on_dir)
    -- ❌ 排除 deno
    if vim.fs.root(bufnr, { 'deno.json', 'deno.jsonc', 'deno.lock' }) then
      return
    end

    -- 项目根：lock > .git
    local root = vim.fs.root(bufnr, {
      'package-lock.json',
      'yarn.lock',
      'pnpm-lock.yaml',
      '.git',
    })

    if not root then
      return
    end

    local filename = vim.api.nvim_buf_get_name(bufnr)
    local files = util.insert_package_json(eslint_files, 'eslintConfig', filename)

    local found = vim.fs.find(files, {
      path = filename,
      upward = true,
      stop = root,
      limit = 1,
    })[1]

    if not found then
      return
    end

    on_dir(root)
  end,

  settings = {
    validate = 'on',
    format = true,
    run = 'onType',
    workingDirectory = { mode = 'auto' },
  },
}
