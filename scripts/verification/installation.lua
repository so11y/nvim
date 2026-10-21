local report = {}
local ok, err = xpcall(function()
    local Plugin = require('lazy.core.plugin')
    local plugins = require('lazy.core.config').plugins
    for name, plugin in pairs(plugins) do
        assert(plugin._.installed, 'Plugin is missing: ' .. name)
        assert(not Plugin.has_errors(plugin), 'Plugin failed: ' .. name)
    end
    report.plugins = vim.tbl_count(plugins)

    local registry = require('mason-registry')
    local tools = require('config.mason_tools')
    local versions = tools.versions
    local parsers = require('config.treesitter').parsers
    for _, name in ipairs(tools.tools) do
        local version = versions.mason[name]
        local package = registry.get_package(name)
        local system_cli = name == 'tree-sitter-cli'
            and vim.fn.executable('tree-sitter') == 1
            and not package:is_installed()
        if not system_cli then
            assert(
                not package:is_installing(),
                'Build ended before installation: ' .. name
            )
            assert(package:is_installed(), 'Tool is missing: ' .. name)
            if version then
                assert(
                    package:get_installed_version() == version,
                    'Tool version mismatch: ' .. name
                )
            end
        end
    end
    local installed = require('nvim-treesitter.config').get_installed('parsers')
    for _, lang in ipairs(parsers) do
        assert(
            vim.list_contains(installed, lang),
            'Parser is missing: ' .. lang
        )
    end
    report.tools = #tools.tools
    local sdk = registry.get_package('vue-language-server'):get_install_path()
        .. '/node_modules/typescript/package.json'
    report.typescript_sdk =
        vim.json.decode(table.concat(vim.fn.readfile(sdk), '\n')).version
    assert(
        report.typescript_sdk == versions.typescript_sdk,
        'Vue SDK version mismatch'
    )

    for _, lang in ipairs(parsers) do
        assert(vim.treesitter.language.add(lang))
    end
    report.parsers = #parsers
    local files = vim.fs.find(function(name)
        return name:match('%.lua$') ~= nil
    end, {
        path = vim.fn.stdpath('config'),
        type = 'file',
        limit = math.huge,
    })
    for _, filename in ipairs(files) do
        assert(loadfile(filename))
    end
    report.lua_files = #files
end, debug.traceback)
if not ok then
    report.error = err
    print(err)
end
vim.fn.writefile(
    { vim.json.encode(report) },
    vim.env.NVIM_TEST_OUTPUT or (vim.fn.tempname() .. '-installation.json')
)
vim.cmd(ok and 'qa!' or 'cquit')
