local data = vim.fn.stdpath('data')
vim.opt.rtp:prepend(data .. '/lazy/mason.nvim')
require('mason').setup()
local registry = require('mason-registry')
local versions = vim.json.decode(
    table.concat(
        vim.fn.readfile(vim.fn.stdpath('config') .. '/tools.lock.json'),
        '\n'
    )
)
local result = { requested = versions.mason, installed = {}, failures = {} }
local pending = vim.tbl_count(versions.mason)
local function save_result()
    vim.fn.writefile(
        { vim.json.encode(result) },
        data .. '/tools-install-result.json'
    )
    vim.cmd(next(result.failures) and 'cquit' or 'qa!')
end
local function finish()
    if vim.fn.has('win32') == 1 and not next(result.failures) then
        vim.system(
            {
                'powershell',
                '-NoProfile',
                '-NonInteractive',
                '-File',
                vim.fn.stdpath('config') .. '/scripts/build-efm.ps1',
                '-DataRoot',
                data,
            },
            { text = true },
            vim.schedule_wrap(function(build)
                if build.code ~= 0 then
                    result.failures.efm_patch = build.stderr
                end
                save_result()
            end)
        )
    else
        save_result()
    end
end
registry.refresh(vim.schedule_wrap(function(ok)
    if not ok then
        result.failures.registry = 'Mason registry refresh failed'
        finish()
        return
    end
    for name, version in pairs(versions.mason) do
        local package = registry.get_package(name)
        local sdk_ok = true
        if name == 'vue-language-server' then
            package.spec.source.extra_packages =
                { 'typescript@' .. versions.typescript_sdk }
            local sdk = package:get_install_path()
                .. '/node_modules/typescript/package.json'
            sdk_ok = vim.uv.fs_stat(sdk) ~= nil
                and vim.json.decode(
                        table.concat(vim.fn.readfile(sdk), '\n')
                    ).version
                    == versions.typescript_sdk
        end
        local function done(success, receipt)
            if success then
                local actual = receipt:get_installed_package_version()
                result.installed[name] = actual
                if actual ~= version then
                    result.failures[name] = 'Requested '
                        .. version
                        .. ', installed '
                        .. actual
                end
            else
                result.failures[name] = tostring(receipt)
            end
            print((success and 'INSTALLED ' or 'FAILED ') .. name)
            pending = pending - 1
            if pending == 0 then
                finish()
            end
        end
        if package:get_installed_version() == version and sdk_ok then
            done(true, package:get_receipt():or_else(nil))
        else
            print('INSTALL ' .. name .. '@' .. version)
            package:install({ version = version }, vim.schedule_wrap(done))
        end
    end
end))
