vim.opt.rtp:prepend(vim.fn.stdpath('data') .. '/lazy/mason.nvim')
local compiler = require('mason-core.installer.compiler')
local Result = require('mason-core.result')
local versions = require('config.mason_tools').versions
local compiled = {}
compiler.compile_installer = function(spec, opts)
    compiled[#compiled + 1] =
        { spec = vim.deepcopy(spec), opts = vim.deepcopy(opts) }
    return Result.success(function()
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
local opts = { version = versions.mason['vue-language-server'] }
assert(compiler.compile_installer(vue_spec, opts):is_success())
assert(
    opts.version == versions.mason['vue-language-server'],
    'Native install version changed'
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
    compiler.compile_installer(vue_spec, { version = '0.0.0' }):is_success()
        and compiled[#compiled].opts.version == '0.0.0',
    'Explicit Mason version was overridden'
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

return {
    pinned_vue_sdk = true,
    explicit_version_preserved = true,
    unmanaged_version_preserved = true,
}
