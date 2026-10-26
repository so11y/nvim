local function import_module(module)
    return {
        name = module,
        -- 无返回值的模块缓存为 true，在 Lazy 清缓存前跳过已执行的原生配置。
        cond = function()
            return package.loaded[module] ~= true
        end,
        import = function()
            local spec = require(module)
            return spec == true and {} or spec
        end,
    }
end

local function discover(directory, namespace)
    local imports = {}
    for name, kind in vim.fs.dir(directory) do
        local path = directory .. '/' .. name
        local module = namespace .. '.' .. name
        if kind == 'directory' then
            if vim.uv.fs_stat(path .. '/init.lua') then
                imports[#imports + 1] = import_module(module)
            else
                -- 分类目录保留为 Lazy import，新增入口时也能触发重载。
                imports[#imports + 1] = {
                    name = module,
                    import = function()
                        return discover(path, module)
                    end,
                }
            end
        elseif kind == 'file' and name:sub(-4) == '.lua' then
            imports[#imports + 1] =
                import_module(namespace .. '.' .. name:sub(1, -5))
        end
    end
    table.sort(imports, function(a, b)
        return a.name < b.name
    end)
    return imports
end

return function()
    return discover(vim.fn.stdpath('config') .. '/lua/modules', 'modules')
end
