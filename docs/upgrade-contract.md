# Neovim 迁移约定

角色：CONTRACT。权威来源：本次对话中的用户指令。范围：当前 Windows 配置的独立 Neovim/Neovide 与既有 VSCode 集成。只在本范围内定义目标、职责和验收；分析、计划与执行记录不得改变这些约定。

- D1（LOCKED，用户原话）：全部统一到 LSP，格式器通过服务器接入。
- D2（LOCKED，用户原话）：独立 Neovim / Neovide 统一原生 LSP；VSCode 继续使用宿主语言功能。
- D3（DERIVED）：编辑器运行时和必要工具采用当前稳定维护方案并固定版本/提交，项目 SDK、依赖锁与 Rust 工具链约束保留。
- D4（DERIVED）：Mason 负责安装；原生配置负责启用。Rust 客户端由 rustaceanvim 独占启动。一个 buffer 的一次格式化由一个选定客户端负责，手动与保存入口一致。
- D5（DERIVED）：保留精确 AST 文本对象、注入语言行为、既有快捷键、片段和折叠预览。语法编辑由 Tree-sitter 提供，调试由 DAP 提供；语言语义能力遵循 D1。
- D6（DERIVED）：独立配置/数据目录验收后再切换日常启动入口；保留旧二进制、配置和数据，可恢复旧入口。正在运行的旧编辑会话由用户保存后重启，迁移不得强制终止。
- D7（LOCKED）：独立 Neovim/Neovide 的可视模式 `Enter` 从当前语法节点开始逐级扩选至全文，`Backspace` 按原路径逐级回缩；Vue 的 `<script>` 与 `<template>` 同样适用。保留现有键位，VSCode-Neovim 继续调用宿主选区。
- D8（LOCKED）：Hover 在编辑窗口及已进入浮窗时均可用 `Esc` 关闭，进入浮窗后仍按首次打开时的 Markdown 效果显示；Code Action 菜单不显示服务器标为禁用的动作，其他入口也不得执行禁用动作，自动预览不得产生缓冲区错误。
- D9（LOCKED）：面包屑默认隐藏，需要时可手动开启与关闭。
- D10（LOCKED）：独立 Neovim/Neovide 的 HTML 与 Vue `<template>` 标签操作由进程内 `tag_fix` Lua LSP 提供，复用现有 Tree-sitter 与 Emmet；只提供 Code Action。`<leader>ca` 沿用 Tiny 光标旁菜单，固定的删除、去外层、合法的空标签展开／合并动作可预览；包裹元素或可视选区只在执行时询问 Emmet 缩写，取消不改文本，确认后核对目标 buffer 和文本版本。Vue `<script>`/`<style>` 交给原有服务器；菜单使用 Blink 配色、圆角边框和 Enter/Tab 选择，并保持紧凑可调的尺寸。
- D11（LOCKED）：`<leader>cr` 使用 Neovim 原生 LSP 重命名；Vue 标签由 `vue_ls` 处理，代码符号仍由对应语言服务器处理。HTML/Vue 配对标签在插入模式实时同步，`ciw`/`caw` 清空标签名后的继续输入也须保持关联；不保留未使用的 IncRename 命令。VSCode-Neovim 沿用宿主语言能力。
- D12（LOCKED）：折叠行中的 HTML/Vue/JSX/TSX 标签保留原有层级前景色；仍可见的对应结束标签须与之同色，背景与普通行一致。

## 验收条件

1. 目标运行时、启用插件提交与工具实际安装版本匹配锁文件。
2. 原生 LSP 在代表语言中完成初始化、补全、诊断、跳转、重命名和代码操作，多个项目根彼此正确。
3. Lua/JS/TS/Vue/Rust 格式化实际改变文本；项目风格优先，保存和手动行为一致，失败可见。Windows 路径含空格及 Unicode 时也可工作。
4. Vue hybrid、Rust 项目工具链、AST 注入/选区/交换/重复跳转和 UFO 预览可用。
5. 真实 UI 下验证 Unicode 大纲、空响应、片段和会话恢复，代表性 Node/Rust DAP 会话可命中断点与结束。
6. VSCode 模式不启动 Neovim 语言客户端；新 CLI/GUI/宿主入口读取同一目标配置与数据。
7. 在代表样例中测量升级前后性能，明确首次开销；交付完整分析、执行步骤、已执行证据及恢复命令。

语法检查或插件安装成功不能单独证明日常可用。业务项目自己的完整 CI、所有框架/浏览器调试矩阵不作为本次编辑器迁移的完成宣称。
