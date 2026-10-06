local M = {}

function M.efm_command(package_root)
    return {
        'powershell',
        '-NoProfile',
        '-NonInteractive',
        '-File',
        vim.fn.stdpath('config') .. '/scripts/build-efm.ps1',
        '-DataRoot',
        vim.fn.stdpath('data'),
        '-PackageRoot',
        package_root,
    }
end

function M.setup()
    local versions = require('config.runtime').versions
    local compiler = require('mason-core.installer.compiler')
    local Result = require('mason-core.result')
    local compile = compiler.compile_installer
    compiler.compile_installer = function(spec, opts)
        local version = versions.mason[spec.name]
        if version then
            if opts.version and opts.version ~= version then
                return Result.failure(
                    spec.name
                        .. ' is pinned to '
                        .. version
                        .. ' in tools.lock.json'
                )
            end
            opts.version = version
        end
        if spec.name == 'vue-language-server' then
            spec = vim.deepcopy(spec)
            spec.source.extra_packages =
                { 'typescript@' .. versions.typescript_sdk }
        end
        local compiled = compile(spec, opts)
        if spec.name ~= 'efm' or vim.fn.has('win32') == 0 then
            return compiled
        end
        -- Mason promotes the staged package only after this installer succeeds.
        return compiled:map(function(install)
            return function(ctx)
                return install(ctx):and_then(function()
                    local command = M.efm_command(ctx.cwd:get())
                    local executable = table.remove(command, 1)
                    return ctx.spawn[executable](command)
                end)
            end
        end)
    end
end

return M
