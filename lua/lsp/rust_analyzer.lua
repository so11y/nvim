return {
    inlayHints = {
        bindingModeHints = { enable = false },
        chainingHints = { enable = true }, -- 链式调用提示
        closingBraceHints = { enable = true, minLines = 25 }, -- 大括号结尾提示
        closureReturnTypeHints = { enable = 'always' }, -- 闭包返回类型
        lifetimeElisionHints = { enable = 'never' }, -- 生命周期隐藏提示
        parameterHints = { enable = true }, -- 参数名提示
        reborrowHints = { enable = 'never' },
        typeHints = {
            enable = true,
            hideNamedTempTypes = false,
            hideClosureInitialization = false,
            allowObviousTypeHints = true,
        },
    },
}
