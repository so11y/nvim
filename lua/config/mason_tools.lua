local M = {
    tools = {
        'codelldb',
        'css-lsp',
        'emmet-language-server',
        'eslint-lsp',
        'html-lsp',
        'js-debug-adapter',
        'json-lsp',
        'lua-language-server',
        'prettierd',
        'stylua',
        'tree-sitter-cli',
        'vtsls',
        'vue-language-server',
    },
}
M.versions = vim.json.decode(
    table.concat(
        vim.fn.readfile(vim.fn.stdpath('config') .. '/tools.lock.json'),
        '\n'
    )
)

function M.setup()
    local compiler = require('mason-core.installer.compiler')
    local compile = compiler.compile_installer
    compiler.compile_installer = function(spec, opts)
        if spec.name == 'vue-language-server' then
            spec = vim.deepcopy(spec)
            spec.source.extra_packages =
                { 'typescript@' .. M.versions.typescript_sdk }
        end
        return compile(spec, opts)
    end
end

local function wait_package(package)
    local result, failure
    local success = function()
        result = true
    end
    local failed = function(err)
        result, failure = false, err
    end
    package:once('install:success', success)
    package:once('install:failed', failed)
    local done = vim.wait(300000, function()
        return result ~= nil
    end, 50)
    package:off('install:success', success)
    package:off('install:failed', failed)
    assert(done, 'Mason: ' .. package.name .. ': installation timed out')
    assert(result, 'Mason: ' .. package.name .. ': ' .. tostring(failure))
end

function M.install(names)
    local registry = require('mason-registry')
    local refreshed
    registry.refresh(function(ok)
        refreshed = ok
    end)
    assert(
        vim.wait(300000, function()
            return refreshed ~= nil
        end, 50),
        'Mason registry refresh timed out; see :MasonLog'
    )
    assert(refreshed, 'Mason registry refresh failed; see :MasonLog')

    local installs = {}
    for _, name in ipairs(names or M.tools) do
        local version = M.versions.mason[name]
        local package = registry.get_package(name)
        if package:is_installing() then
            wait_package(package)
        end
        local system_cli = name == 'tree-sitter-cli'
            and vim.fn.executable('tree-sitter') == 1
            and not package:is_installed()
        local sdk_ok = true
        if name == 'vue-language-server' and package:is_installed() then
            local sdk = package:get_install_path()
                .. '/node_modules/typescript/package.json'
            sdk_ok = vim.uv.fs_stat(sdk) ~= nil
                and vim.json.decode(
                        table.concat(vim.fn.readfile(sdk), '\n')
                    ).version
                    == M.versions.typescript_sdk
        end
        if
            not system_cli
            and (
                not package:is_installed()
                or (version and package:get_installed_version() ~= version)
                or not sdk_ok
            )
        then
            local install = { package = package }
            local function complete(success, result)
                install.success, install.result = success, result
            end
            package:install({ version = version }, complete)
            installs[#installs + 1] = install
        end
    end
    local done = vim.wait(300000, function()
        for _, install in ipairs(installs) do
            if install.success == nil then
                return false
            end
        end
        return true
    end, 50)
    assert(done, 'Mason installation timed out; see :MasonLog')
    for _, install in ipairs(installs) do
        assert(
            install.success,
            'Mason: '
                .. install.package.name
                .. ': '
                .. tostring(install.result)
        )
    end
end

function M.ensure_cli()
    if vim.fn.executable('tree-sitter') == 1 then
        return
    end
    require('lazy').load({ plugins = { 'mason.nvim' } })
    if vim.fn.executable('tree-sitter') ~= 1 then
        M.install({ 'tree-sitter-cli' })
    end
    assert(
        vim.fn.executable('tree-sitter') == 1,
        'Install Tree-sitter CLI with :Mason; see :MasonLog'
    )
end

return M
