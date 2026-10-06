vim.opt.rtp:prepend(vim.fn.stdpath('data') .. '/lazy/mason.nvim')
local root = vim.env.NVIM_TEST_ROOT .. '/mason-' .. vim.fn.getpid()
require('mason').setup({ install_root_dir = root, PATH = 'skip' })
local compiler = require('mason-core.installer.compiler')
local Result = require('mason-core.result')
local Package = require('mason-core.package')
local versions = require('config.runtime').versions
local fs = require('mason-core.fs')
local compiled, events = {}, {}
local fail_download, fail_build = false, false
local patched = vim.fn.stdpath('data')
    .. '/mason/packages/efm/efm-langserver_'
    .. versions.mason.efm
    .. '_windows_amd64/efm-langserver.exe'
compiler.compile_installer = function(spec, opts)
    compiled[#compiled + 1] =
        { spec = vim.deepcopy(spec), opts = vim.deepcopy(opts) }
    return Result.success(function(ctx)
        events[#events + 1] = 'download'
        if fail_download then
            return Result.failure('download failed')
        end
        if spec.name == 'efm' then
            local folder = 'efm-langserver_'
                .. versions.mason.efm
                .. '_windows_amd64'
            ctx.fs:mkdir(folder)
            ctx.fs:write_file(
                folder .. '/efm-langserver.exe',
                fs.sync.read_file(patched)
            )
            ctx:link_bin('efm-langserver', folder .. '/efm-langserver.exe')
            local powershell = ctx.spawn.powershell
            ctx.spawn.powershell = function(args)
                events[#events + 1] = 'build'
                assert(
                    not ctx.package:is_installed() or fail_build,
                    'Package was promoted before build'
                )
                assert(
                    args[#args] == ctx.cwd:get(),
                    'Build targeted the published package'
                )
                if fail_build then
                    ctx.fs:write_file(
                        folder .. '/efm-langserver.exe',
                        'unpatched staging probe'
                    )
                    return Result.failure('patch build failed')
                end
                return powershell(args)
            end
        end
        ctx.receipt:with_source({
            type = spec.schema,
            id = 'pkg:github/mattn/' .. spec.name .. '@' .. opts.version,
            raw = spec.source,
        })
        ctx.receipt:with_install_options(opts)
        return Result.success()
    end)
end
require('config.mason_tools').setup()

local vue_spec = {
    name = 'vue-language-server',
    schema = 'registry+v1',
    source = {
        id = 'pkg:npm/vue@latest',
        extra_packages = { 'typescript@latest', 'other' },
    },
}
local original = vim.deepcopy(vue_spec)
local opts = {}
assert(compiler.compile_installer(vue_spec, opts):is_success())
assert(
    opts.version == versions.mason['vue-language-server'],
    'Native install ignored the lock'
)
assert(
    vim.deep_equal(
        compiled[#compiled].spec.source.extra_packages,
        { 'typescript@' .. versions.typescript_sdk }
    ),
    'Vue SDK was not pinned'
)
assert(vim.deep_equal(vue_spec, original), 'Registry spec was mutated')
assert(
    compiler.compile_installer(vue_spec, { version = '0.0.0' }):is_failure(),
    'Conflicting explicit version was accepted'
)
local unmanaged = {
    name = 'unmanaged',
    schema = 'registry+v1',
    source = { id = 'pkg:npm/unmanaged@1' },
}
compiler.compile_installer(unmanaged, { version = '1' })
assert(
    compiled[#compiled].opts.version == '1',
    'Unmanaged package policy changed'
)

local efm = Package:new({
    name = 'efm',
    schema = 'registry+v1',
    description = 'Isolated install regression',
    homepage = '',
    licenses = {},
    languages = {},
    categories = {},
    source = { id = 'pkg:github/mattn/efm-langserver@' .. versions.mason.efm },
}, {
    serialize = function()
        return { proto = 'lua', name = 'regression' }
    end,
})
local success_events = 0
efm:on('install:success', function()
    success_events = success_events + 1
end)
local function install(expected, failure)
    local completed, success, value = false
    efm:install(
        {},
        vim.schedule_wrap(function(ok, result)
            events[#events + 1] = ok and 'success' or 'failure'
            completed, success, value = true, ok, result
        end)
    )
    assert(
        vim.wait(10000, function()
            return completed
        end, 10),
        'Native install did not finish'
    )
    assert(success == expected, tostring(value))
    if failure then
        assert(tostring(value):find(failure, 1, true), 'Wrong install failure')
    end
end
install(true)
assert(
    vim.deep_equal(events, { 'download', 'build', 'success' }),
    'Success published before build'
)
assert(
    efm:get_installed_version() == versions.mason.efm,
    'Receipt recorded the wrong version'
)
local installed = efm:get_install_path()
    .. '/efm-langserver_'
    .. versions.mason.efm
    .. '_windows_amd64/efm-langserver.exe'
local original_binary = fs.sync.read_file(installed)
events = {}
fail_build = true
install(false, 'patch build failed')
assert(
    vim.deep_equal(events, { 'download', 'build', 'failure' }),
    'Build failure was hidden'
)
assert(
    fs.sync.read_file(installed) == original_binary,
    'Failed build replaced the working binary'
)
assert(success_events == 1, 'Failed install emitted success')
events = {}
fail_download = true
install(false, 'download failed')
assert(
    vim.deep_equal(events, { 'download', 'failure' }),
    'Build ran after download failure'
)
return {
    pinned_vue_sdk = true,
    version_conflict_rejected = true,
    staged_efm_build = true,
    failed_build_preserves_install = true,
    success_events = success_events,
    root = root,
    errmsg = vim.v.errmsg,
}
