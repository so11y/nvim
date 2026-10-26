local shortcuts = {
    { 'Alt+z', '普通/插入/可视', '撤销文字修改（Undo）' },
    { 'Alt+y', '普通/插入/可视', '重做已撤销的修改（Redo）' },
    {
        'Alt+u',
        '普通',
        '返回上一个跳转位置，例如从定义回到调用处',
    },
    { 'Alt+i', '普通', '前进到下一个跳转位置' },
    { 'Alt+a', '普通', '全选当前文件' },
    { 'Alt+s', '普通/插入/可视', '保存文件' },
    { 'Alt+d', '普通/插入', '删除当前行，不覆盖剪贴板' },
    { 'Alt+d', '可视', '删除选中内容，不覆盖剪贴板' },
    {
        'Alt+x',
        '普通/可视',
        '剪切当前行或选中内容到系统剪贴板',
    },
    { 'Alt+c', '可视', '复制选中内容到系统剪贴板' },
    { 'Alt+v', '普通/插入/命令行', '粘贴系统剪贴板内容' },
    { 'Alt+v', '可视', '用复制的内容替换选区，保留剪贴板' },
    { 'Alt+j', '普通/可视', '向下移动当前行或选中的多行' },
    { 'Alt+k', '普通/可视', '向上移动当前行或选中的多行' },
    { 'Alt+j', '插入/命令行', '补全菜单：选择下一个候选项' },
    { 'Alt+k', '插入/命令行', '补全菜单：选择上一个候选项' },
    { 'Alt+Shift+J', '普通/插入/可视', '向下添加光标（Alt+J）' },
    { 'Alt+Shift+K', '普通/插入/可视', '向上添加光标（Alt+K）' },
    { 'Alt+/', '普通/可视', '切换当前行或选区的行注释' },
    { 'Alt+Shift+F', '普通/插入', '格式化代码（Alt+F）' },
    {
        'Alt+f',
        '普通',
        '搜索当前文件；回车确认，n/N 继续查找',
    },
    { 'Alt+h', '普通', '切换到上一个缓冲区（文件标签）' },
    { 'Alt+l', '普通', '切换到下一个缓冲区（文件标签）' },
    { 'Alt+<', '普通', '把当前文件标签向左移动' },
    { 'Alt+>', '普通', '把当前文件标签向右移动' },
    { 'Alt+1', '普通', '切换到第 1 个缓冲区' },
    { 'Alt+2', '普通', '切换到第 2 个缓冲区' },
    { 'Alt+3', '普通', '切换到第 3 个缓冲区' },
    { 'Alt+p', '普通', '固定或取消固定当前文件标签' },
    {
        'Alt+w',
        '普通',
        '关闭窗口；最后一个编辑窗口则关闭文件',
    },
    { 'Alt+Up', '普通', '增加窗口高度（Alt+↑）' },
    { 'Alt+Down', '普通', '减少窗口高度（Alt+↓）' },
    { 'Alt+Left', '普通', '减少窗口宽度（Alt+←）' },
    { 'Alt+Right', '普通', '增加窗口宽度（Alt+→）' },
    { 'Alt+b', '普通', '显示或隐藏文件树' },
    { 'Alt+e', '普通', '在文件树中定位当前文件' },
    { 'Alt+t', '普通/终端', '显示或隐藏终端' },
    { 'Alt+g', '普通/终端', '显示或隐藏 opencode 代码助手终端' },
}

return function()
    local items = {}
    for _, shortcut in ipairs(shortcuts) do
        items[#items + 1] = {
            text = table.concat(shortcut, ' '),
            key = shortcut[1],
            mode = shortcut[2],
            desc = shortcut[3],
        }
    end
    return Snacks.picker({
        title = 'Alt 快捷键速查 · j/k 浏览 · i 搜索',
        items = items,
        focus = 'list',
        layout = {
            preset = 'select',
            layout = { width = 0.9, height = 0.75 },
        },
        format = function(item)
            local align = Snacks.picker.util.align
            return {
                { align(item.key, 18), 'Special' },
                { align(item.mode, 22), 'Comment' },
                { item.desc, 'Normal' },
            }
        end,
        confirm = function(picker)
            picker:close()
        end,
    })
end
