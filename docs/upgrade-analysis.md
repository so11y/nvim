# Neovim 升级分析

角色：ANALYSIS。依据：[迁移约定](C:/Users/Administrator/AppData/Local/nvim/docs/upgrade-contract.md)。范围：这台 Windows 机器上的独立 Neovim、Neovide、VSCode-Neovim 与当前配置。版本核验日期：2026-10-03。本文解释事实和取舍；目标以约定为准，版本以 tools.lock.json / lazy-lock.json 为准，完成状态以执行记录为准。

## 结论

这次需要把运行时、Tree-sitter API、语言服务器所有权、格式化入口、Windows 工具链和宿主启动方式一起迁移。原配置已经使用 vim.lsp.config / vim.lsp.enable，重点是消除并行入口与补齐生命周期，不能把它误写成从旧 lspconfig.setup 整体重写。

最大兼容断点是 Tree-sitter 的 master → main；最大一致性问题是 Conform 与 LSP 分别管理格式化、nvim-eslint 单独启动服务、Mason 默认自动启用与手工启用混用。性能收益主要来自减少启动工作、避免重复 AST 全树遍历与状态栏全文件扫描。

## 1. 基线与升级矩阵

原配置 Git 提交：cde7e723b57aac4edbd957e4b2d1a16668b00b91。隔离升级阶段，原目录 C:/Users/Administrator/AppData/Local/nvim 与 C:/Users/Administrator/AppData/Local/nvim-data 保留；实现位于 C:/Users/Administrator/AppData/Local/nvim-upgrade，数据位于 C:/Users/Administrator/AppData/Local/nvim-upgrade-data，分支 codex/upgrade-nvim-0.12。合并后的当前入口与数据备份见执行记录末节。

| 部件 | 实际原版本 | 目标/处理 | 原因 |
| --- | --- | --- | --- |
| Neovim | 0.11.5 | 0.12.5 稳定版，独立目录 | 原生 API 与插件运行时统一 |
| Neovide | 0.13.3 | 0.16.2 | 图形宿主同步 |
| Node | 全局 22.22 | 编辑器专用 24.21.0 LTS | npm LSP/格式器/DAP 运行时固定，全局项目 Node 保留 |
| nvim-lspconfig | 2.6.0 | 2.12.0 | 使用服务器定义，启动仍由原生 LSP 管理 |
| Mason / mason-lspconfig | 2.2.1 / 2.1.0 | 2.3.1 / 2.3.0，mason-org | automatic_installation 已过时；关闭 automatic_enable |
| Blink | 1.8.0 | 1.10.2 | LSP capabilities、原生片段、模糊匹配二进制 |
| rustaceanvim | 7.1.9 | 9.2.1 | Rust 与 Cargo/DAP 集成同步 |
| Tree-sitter / textobjects | master 旧 API | main，提交锁定 | API 整体重构，不能只修改 branch |
| vtsls | 0.3.0 | 0.3.0 | 本身已是目标稳定版，补齐 Vue 和客户端重构命令 |
| Vue language server | 3.2.2 | 3.3.12 | hybrid 与 vtsls 转发链 |
| ESLint / HTML / CSS / JSON LSP | 4.10.0 系列 | 4.10.0，固定安装 | 接入与项目根识别调整 |
| LuaLS | 3.16.4 | 3.19.1 | 原生诊断、补全及工作区分析 |
| prettierd / StyLua | 0.25.1 / 2.3.1 | 0.29.0 / 2.5.2 | 经 efm 接入 |
| efm | 原来未使用 | 0.0.57 + Windows 补丁 | 保留格式器和风格，同时走 LSP |
| js-debug / CodeLLDB | 1.85.0 / 1.12.1 | 1.140.0 / 1.12.3 | JS/TS/Vue 与 Rust 调试 |
| Tree-sitter CLI / GCC | 旧编译环境 | 0.27.0 / MinGW GCC 16.1.0 | 重建 Windows 解析器 DLL |
| Rust | 默认 1.93.1 | 编辑器 RA 1.99.0；默认/项目固定版本保留 | 防止编辑器升级改变项目编译目标 |
| VSCode-Neovim | 1.20.0 | 1.20.0，已是稳定目标 | 核验 [官方变更记录](https://github.com/vscode-neovim/vscode-neovim/blob/master/CHANGELOG.md)，原生 profile 支持 |
| Go | 编辑器不需常驻 | 1.27.1，仅用于 efm 构建 | 运行 efm 不需要 Go |

升级时 45 个独立模式插件均核对安装 HEAD，且无跟踪文件修改，详见 [升级插件证据](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/plugins.json)。后续审计另补齐宿主插件锁，当前状态见第 8 节与执行记录。稳定标签优先；维护方案需要 main 的插件固定完整 SHA。lazy.nvim、Noice 等当前提交已经满足目标，核验后保留。

TypeScript 分两层：服务器兼容的全局 JS SDK 固定为 5.9.3，项目 SDK 由 vtsls.autoUseWorkspaceTsdk 选择。Vue 的 Mason 安装原来会浮动拉取 typescript，现显式固定全局 SDK。新的 TypeScript 原生编译器可执行文件不能直接替代 tsserver JavaScript API；编辑器升级也不应改写项目依赖锁。

## 2. LSP 所有权

按 D1/D2/D4 分工：

~~~mermaid
flowchart LR
  M[Mason 固定版本安装] --> C[Neovim 原生 LSP]
  C --> T[vtsls + Vue hybrid]
  C --> E[ESLint / LuaLS / HTML / CSS / JSON]
  C --> F[efm → prettierd / StyLua]
  R[rustaceanvim] --> A[原生 rust-analyzer → 项目 rustfmt]
  C --> U[补全 / 诊断 / 跳转 / 重命名 / 代码操作 / 大纲]
  A --> U
  V[VSCode-Neovim 按键] --> H[VSCode 宿主语言功能]
~~~

| 原配置事实 | 日常影响 | 修复 |
| --- | --- | --- |
| LspAttach 每次 clear 同一高亮 augroup | 第二个项目 attach 后删除第一个 buffer 的事件 | 全局组建立一次，按 buffer 注册/解除 |
| 每次 attach 重设诊断 | 全局规则重复配置 | setup 一次 |
| nvim-eslint 首文件 config 与 .git 判断 | 无 .git、不同根及部分 flat config 扩展名漏服务 | 原生 eslint，官方 root_dir + auto workingDirectory |
| Rust/ESLint 同时 ft 与 BufReadPre | 无关语言首次读文件也加载 | Rust 仅 rust filetype，ESLint 原生按 filetype/root 启用 |
| 修改 server_capabilities 关闭格式 | 真实能力与 UI 所见不一致 | 保留能力，格式模块选唯一客户端 |
| Conform 单独执行且关闭错误通知 | 格式化不经过原生 LSP | efm + 统一格式入口 |
| 提取函数返回 editor.action.rename，但无客户端 handler | 生成代码后无法进入重命名 | 原生 show_document + buf.rename，处理编码 |

实现位置：[LSP 生命周期](C:/Users/Administrator/AppData/Local/nvim/lua/config/lsp.lua)、[格式入口](C:/Users/Administrator/AppData/Local/nvim/lua/config/format.lua)、[vtsls 集成](C:/Users/Administrator/AppData/Local/nvim/lua/lsp/vtsls.lua)。Vue 委托官方 vue_ls.on_init 转发，并以一个上下文适配修正多工作区归属（第 8 节）；不同时启动旧 Volar/ts_ls。vtsls 注册 @vue/typescript-plugin；Vue hybrid 与 vtsls 共同完成 SFC 能力。

Rust 只有 rustaceanvim 启动 RA；可执行文件固定在 1.99.0 工具链，cargo/rustfmt 通过 rustup 解析项目约束。RA 子进程 PATH 把 rustup 放在旧 Mason rustfmt shim 前，避免旧 rustfmt 抢占。打开 Rust 文件不加载 DAP，F5 才进 Cargo 调试。

## 3. 格式化与 Windows 修复

选择规则由 C:/Users/Administrator/AppData/Local/nvim-upgrade/lua/config/format.lua 单独定义：Lua/JS/TS/React/Vue/HTML/CSS/SCSS/JSON 使用 efm；Rust 使用 rust-analyzer。Alt+Shift+F 与保存调用同一函数，保留普通/插入模式与 2 秒同步超时。

项目 .prettierrc 与 StyLua 配置优先；没有项目配置时，C:/Users/Administrator/AppData/Local/nvim-upgrade/format/prettier.json 对齐当前 VSCode 设置。ESLint 保留诊断与修复，format=false，避免与 Prettier 争抢同次保存。没有新增选区格式化键，efm 范围格式化关闭。

实测 efm 0.0.57 用 exec.Command(cmd, /c, command) 启动含引号命令失败：普通 exe 可用，而带引号的 prettierd.cmd/Node 命令返回空结果。因此根因不在 Prettier 配置。Windows 补丁提供 cmd.exe /d /s /c 的完整命令行，其他平台保持 sh -c。另一个实测问题是格式器非零退出时只记日志并返回空编辑；补丁改为返回含退出状态及 stdout/stderr 的 LSP 错误。原生同步 buf.format 对该 RPC 错误没有用户提示，因此统一格式入口直接使用原生 request_sync / apply_text_edits，并显示错误或超时。失败保持内容不变，通知去掉 ANSI 颜色控制码。

补丁：C:/Users/Administrator/AppData/Local/nvim-upgrade/patches/efm-windows-command.patch。构建：C:/Users/Administrator/AppData/Local/nvim-upgrade/scripts/build-efm.ps1，核对源提交、补丁、Go 与产物 SHA。独立目录重编译 SHA 与安装产物一致；没有修改插件仓库。未来 efm 更新先核对上游修复，再移除补丁/构建依赖。

已覆盖 JS、Vue、含空格/中文/单引号的文件名，以及两个项目不同 Prettier 风格。efm 提供协议，项目/格式器继续定义风格。

## 4. Tree-sitter 和编辑体验

main 移除旧 configs/highlight/indent/incremental_selection/textobjects 集成，改用 setup、vim.treesitter.start、indentexpr 与新 textobjects API。先 install 缺少的解析器，再 update；单独 update 会跳过缺失语言。

保留自定义 queries、af/if 等文本对象、gj*/gk*、;/,、参数交换及折叠预览。补齐 tsx、rust、markdown_inline，12 个语言及其查询依赖均已重建。后续 Vue 交互复现表明，优先调用 LSP `selectionRange` 会使 `<script>` 内第一次扩选直接跳到全文；按 D7 改用 0.12 原生 `an`/`in`，由语法树处理 Vue 注入树，缺少解析器时由原生动作回退 LSP。

textobjects main 的移动/交换只查主语言树，直接替换会漏 Vue 内嵌 TS。C:/Users/Administrator/AppData/Local/nvim-upgrade/lua/config/ast_move.lua 遍历主树和注入树，按文本版本及 256 行窗口建立索引，再二分跳转；修改/filetype 改变重建，BufWipeout 清理。参数交换显式访问注入树，限制同一参数列表，保留相邻交换及点重复。

按 D1/D5，格式与语义补全/诊断/跳转/重构经 LSP；参数/引号/函数体的精确文本对象需要语法树，调试需要 DAP。documentSymbol 不能替代这些 AST 编辑语义。

UFO 首选 LSP foldingRange，后备已安装的 Tree-sitter/indent，摘要与浮窗预览保留。Vue hybrid 同时连接 vue_ls 和 vtsls：实测前者返回完整 SFC 折叠，后者声明能力但对 Vue 返回空列表。UFO 默认只取第一个客户端，先打开 TypeScript 再打开 Vue 会导致全部折叠丢失。因此 Vue 经 UFO 的自定义提供器直接请求 vue_ls；LspAttach 后刷新折叠，避免初始化前的语法后备一直保留。VSCode 调用宿主折叠/选区/大纲，不启动 Neovim 语言插件。

## 5. 性能证据

以下是升级初验时的历史对照，当前语法跳转复核见第 9 节。本机代表样例不能外推为所有项目保证。旧版用保留的 0.11.5/配置，新版用 0.12.5/配置。启动交替运行 5 次、真实 RPC UI attach，取 Lazy startuptime 中位数，文件缓存已热。AST/搜索使用 1千/5千/2万行合成 JS，重复操作取 7 次中位数，采样间完整 Lua GC。

| 场景 | 修改前 | 修改后 | 实际限制 |
| --- | ---: | ---: | --- |
| 空白 UI 启动 | 40.28 ms，23 个加载插件 | 28.75 ms，10 个 | Lazy 启动指标，不含语言首次索引 |
| 2万行重复 AST 跳转 | 914.67 ms | 0.097 ms | 命中文本未变的索引 |
| 2万行首次 AST 索引 | 每次都需遍历 | 885.68 ms | 初验时的全量索引；当前结果见第 9 节 |
| 2万行重复搜索计数 | 4.954 ms | 0.034 ms | 输入不变才复用 |

减少工作：Neo-tree/GrugFar/Showkeys/Flash 移除 VeryLazy；Rust/DAP/opencode 按入口加载；日常启动不自动安装工具。诊断一次 count，搜索依 buffer/tick/cursor/pattern/options 重算。AST 缓存避免弱表被 GC 清除导致重复扫描。

初验时首次大文件索引仍有明显停顿；后续按窗口索引已单独复核。更大真实项目需要再测。初验证据：C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/evidence/performance.json 与 startup-performance.json；脚本：C:/Users/Administrator/AppData/Local/nvim-upgrade/scripts/check-performance.lua。

## 6. 宿主和调试

JS 调试服务器默认 localhost 在本机解析到 ::1，而 DAP 连 127.0.0.1；现显式同一 IPv4。Node 断点/继续/结束，以及 Cargo 构建后 CodeLLDB 断点/正常终止已验证。JS/TS/React/Vue 共用 Node/Chrome 配置；项目 launch.json 可给出框架命令与指定运行时。

Rust initialized 不代表 Cargo 模型完成。过早 debuggables 只有 cargo check --workspace；等真正 run target 出现后实测成功，不给运行时加重试框架。

大纲采用 Snacks matcher.on_done 公共钩子，UTF-8 字节光标按各项 LSP encoding 转换，范围末端排除。中文/emoji、同一行多函数用例正确选中 narrow。JS/TS/React/Vue 片段加载与占位符展开/跳转、UFO 预览、会话保存恢复、Noice 消息已运行。

真实 JSON-RPC null 在 0.12 归一化为 nil；协议空响应下大纲/hover/highlight 无错。直接把 vim.NIL 塞进插件回调不等同真实客户端路径，因此未给 Snacks/Dropbar 添加无证据补丁。

## 7. 切换和维护

按 D6 保留旧二进制/配置/数据。核查时 3 个旧 VSCode-Neovim 会话运行，核心及配置来自原目录；不能运行中替换整棵目录。新 profile nvim-upgrade 的 CLI/GUI/VSCode 入口已切换到同一配置/数据，旧会话保存后由用户重启。VSCode 扩展 1.20.0 原生支持 NVIM_APPNAME；实际扩展运行时已验证宿主 RPC 和零原生客户端，不使用额外 init 引导。

旧功能删除候选：0。Conform/nvim-eslint 的功能由原生入口承接；清理的是重复实现。原来禁用的 precognition 仅去掉无效锁项。项目依赖锁、默认 Rust、全局 Node 保留。

维护成本是 efm 补丁、SDK 固定和 Tree-sitter main 查询 ABI。后续先更新锁，再重跑验收；网络代理/TLS 调整只用于安装过程，不关闭证书验证。未测试任意业务仓库完整 CI、全部浏览器框架调试或当前 VSCode 窗口人工重启。

## 8. 升级后的配置审计

以升级提交 97f8ca2 为本次清理基线；D1—D6 保持原定义。清理依据是已安装插件/核心源码、配置引用和真实执行，未删除日常功能。未使用的状态栏导出、转发环境模块、失效选项和停用方案注释已移除；禁用的 Precognition 意图仍保留。

| 发现 | 处理与边界 |
| --- | --- |
| vtsls.autoUseWorkspaceTsdk 只在分析中承诺，配置未启用 | 显式启用；真实 projectInfo 返回的标准库路径必须来自项目 node_modules/typescript/lib，不能只比较相同版本号 |
| Vue 服务器请求不带 buffer，官方 handler 在多根场景选择全局第一个 TS 客户端 | [Vue 适配](C:/Users/Administrator/AppData/Local/nvim/lua/lsp/vue_ls.lua) 按发起 Vue 工作区选择所属 vtsls，补齐连接 buffer 后委托官方 handler；转发协议、回调和初始化重试仍由上游实现，不解析各种 payload 形状 |
| 读取普通文件就加载安装管理器；Mason PATH 与语言启用混在加载链 | runtime 统一加入已安装工具 PATH；Mason 使用 PATH=skip，两个安装插件按命令加载；全部 Mason/LspInstall 入口归 mason-lspconfig 一处注册，automatic_enable=false 保持 |
| 诊断可见性条件每次渲染复制诊断列表，即使计数已缓存 | DiagnosticChanged/BufEnter 更新一次计数，内层按缓存控制显示；从空诊断变为有诊断再恢复均覆盖 |
| Dropbar 先构建整条路径，再只取文件名 | 使用官方 sources.path.max_depth=1，保留文件图标和 Markdown/LSP/语法后备 |
| Colorizer 旧配置仍可转换，但 Sass parsers 使用列表而非有效映射 | 改用结构化 options.parsers/display；CSS 函数 Sass 变量真实解析为 ff0000，虚拟色块与位置保留 |
| 0.12 原生能力和上游默认重复配置 | 去掉 foldingRange 默认值、ESLint workingDirectory、Vue 已废弃 hybridMode、EFM 重复全局标记、Blink 默认项；格式规则仍集中在 config/format.lua，单工具 cwd 标记保留 |
| Snacks 仍调用废弃的诊断跳转接口 | 改用 vim.diagnostic.jump/on_jump；保留方向、;/, 重复、循环与浮窗 |
| 仅 VSCode 启用的多光标插件未锁定 | 增补一个宿主插件 SHA，原有 45 个提交不变；独立与宿主合计 46 个锁定插件 |

两根验收夹具必须各有真实包管理锁标记。原 Beta 缺标记，使 vtsls 找到用户目录上层的锁；只断言客户端 ID 不同无法检验根正确。新增 Beta 样例与锁标记，保留官方 vtsls 单仓库/monorepo 根算法，测试明确核对两个 TS 根。

VSCode 的 cmdheight=50 保留：已安装 1.20.0 包含旧问题修复，但当前宿主仍按消息行数超过 cmdheight 时展开 Output。注释已改为说明当前行为，不能将该设置仅因旧 issue 已关闭判为冗余。

本轮性能在同一进程交替运行 5 轮、每轮完整 GC，500 条合成诊断和 200 次组件计算取中位数。状态栏结果文本、高亮组及间距逐轮相同；文件名/图标逐轮相同。原始结果见 [组件性能](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/config-audit-ui-performance.json)。

| 场景 | 基线 | 清理后 | 减少的实际工作 |
| --- | ---: | ---: | --- |
| 200 次 Heirline 计算 | 128.308 ms | 4.4081 ms | diagnostic.get 400 → 0；每轮初始化 count 都为 1，后续缓存渲染不查诊断 |
| 200 次 Dropbar 路径源计算 | 24.5061 ms | 8.4779 ms | fs_stat 800 → 200，创建 4 → 1 个路径符号 |

这些是组件/路径源成本，不是整机启动或每次按键的总耗时。无文件、修改文件、未命名和终端状态栏也逐项比较了显示结果；详细功能回归和失败处理以执行记录为准。

## 9. 升级后交互问题定位

Vue 选区复现路径是可视模式 `v` 后第一次 `Enter`：旧映射只要发现任一 LSP 声明 `selectionRange` 就调用原生 LSP 请求，结果随客户端选择及服务器返回变化，`<script>` 中可直接变为全文。0.12 的原生 `an`/`in` 会沿 Tree-sitter 节点及注入树扩展、按历史回缩；Vue `<script>`、`<template>` 的真实按键测试均从当前节点逐级到根。

Hover 实际由 Noice 接管 `vim.lsp.buf.hover`，因此 Neovim 原生浮窗变量不在原路径上。为 D8 的可预测 Esc 行为，关闭 Noice 的 Hover 覆盖，保留其消息 UI；用 Neovim 原生浮窗的 `textDocument/hover` 标识精确关闭 Hover，不影响其他浮窗。

Code Action 的 `Buffer operation failed` 在 18 个真实 vtsls 动作中定位到插件预览写入：14 个动作被服务器标为 `disabled`，其错误内容可能包含换行，插件把它作为单个 `nvim_buf_set_lines` 元素，触发 `'replacement string' item contains newlines`。插件当前 main 与本地锁定提交相同；配置层在预览前处理禁用动作，并对其他预览行拆分换行。执行入口也阻止禁用动作，列表显示原因。面包屑原插件按文件自动附着，现将自动附着关闭，按键仍可按需显示。

## 10. 导航与编辑性能复核

2026-10-03 在同一 Neovim 0.12.5、插件和合成 JavaScript 样本中，交替运行 5 轮旧索引与当前索引。每轮先解析语法树，只计首次跳转回调；重复跳转仍取 7 次中位数。旧实现一次扫描整个文件：2 万行产生 57 万条查询捕获，遍历约 684 ms、排序约 138 ms。当前实现按光标附近的 256 行窗口查询，单窗口约 7296 条捕获、约 6 ms；只有找不到目标时才继续向相邻窗口搜索。

| 文件行数 | 首次跳转旧索引中位数 | 当前中位数 | 当前重复跳转中位数 |
| --- | ---: | ---: | ---: |
| 1000 | 30.14 ms | 8.35 ms | 0.016 ms |
| 5000 | 184.36 ms | 9.48 ms | 0.020 ms |
| 20000 | 856.96 ms | 12.70 ms | 0.028 ms |

全量与分窗口的捕获位置集合在 2 万行 JavaScript 及 TypeScript、TSX、Vue、Rust 样本中一致。跨越多个窗口的父函数会被 Tree-sitter 在后续查询中重复返回；若不按捕获起始行归属窗口，从长函数内部反向跳转会跳过更近的内层函数。负对照触发该失败，过滤后通过。跨 256 行边界、Vue 注入函数、正反跳转、`;`/`,`、文本修改后失效均通过；真实 UI 的 `3gjf` 与连续三次 `gjf` 到达相同位置。

另以 1504 行 Vue、1002 棵主/注入树做已编译查询的 5 轮对照：旧全量索引首次跳转中位数 30.84 ms，当前按窗口跳转 2.93 ms。跳过根范围与当前窗口无交集的树，单独将热查询样本从约 6.61 ms 降到 4.71 ms。完全冷的首次调用仍约 50 ms，其中 TypeScript 文本对象查询编译约 45.5 ms；预加载该查询会把开销转移到启动阶段，因此保持按需编译。

附着 vtsls 的 2400 行 TypeScript、130×40 UI 中，每轮连续输入 300 个移动键。基线与当前配置的映射/原生中位数分别为：`j` 391/402 ms、405/412 ms；`k` 390/360 ms、373/370 ms。差值小且方向不稳定，不能证明 `j/k` 表达式映射是瓶颈。交替忽略 `CursorMoved` 的 `j` 中位数为 385 ms，同组正常约 404 ms，收益约 0.06 ms/键，不足以据此关闭诊断或 LSP 高亮事件。`h/l` 未设表达式映射。真实 UI 首次 AST 跳转还包含解析器、RPC 和重绘开销，不能直接等同于上表的回调计时；没有匹配捕获时可能仍扫描到文件末尾。

另一个确定的热路径是状态栏搜索计数：旧配置把光标位置和 changedtick 放进缓存键，位置变化就执行 `searchcount(recompute=1)`，每次重新扫描全文件。2 万行直接测量，300 次强制重算耗时 2760.79 ms；`recompute=0` 仅 5.64 ms，但真实按键后当前位置会滞后，不能直接替代。现保留相同 Neovim 计数函数，在搜索模式/选项/窗口改变时立即计算；光标移动或编辑时延后 120 ms，连续输入只保留最后一次重算。代价是快速移动期间状态栏短暂显示上次计数，停下后刷新到准确值；真实状态栏已验证。

2400 行 TypeScript、附着 vtsls 的真实 UI 中，连续 300 次 `j` 的搜索开启/关闭中位数，修改前分别为 685.99/413.45 ms；修改后同轮为 474.54/469.04 ms。100 字符连续插入，修改后搜索开启/关闭为 27.45/30.94 ms。计时包含 UI、映射及插件事件，样本有波动；数据只能说明本样本的搜索额外开销基本消失，不能外推为所有文件的键入延迟。

其他跳转的代码路径没有发现每次 `h/j/k/l` 都发起的 LSP 请求：`gd`/`gr` 按需进入 Snacks LSP picker，`gjx`/`gkx` 调用原生诊断跳转并在目标处开浮窗。真实 UI 已验证诊断正反跳转、`;`/`,` 重复和回绕，LSP 定义请求返回目标；这不等于所有项目的服务器响应时间已有上界，因此没有改动这些按需入口。

原始样本和等价性结果见 [导航性能证据](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/navigation-performance.json)；复跑入口为 `scripts/check-performance.lua` 和 `scripts/verification/check-ui.mjs navigation-performance`。面包屑按 D9 保持默认关闭，真实 UI 已复验，无需修改该配置。

## 11. 主树环境与配置审计（2026-10-04）

日常入口已切到主树 `nvim`，数据目录连接到已验收的 0.12.5 依赖。旧版 0.11.5 的核心、独立数据和 GUI 备份已按 D6 清理。此前旧/新性能数据取自合并前同一套升级配置；为核实主树入口，用当前主树在 130×40 真实 UI、附着 vtsls 的 2400 行 TypeScript 样本中重新运行 `navigation-performance`。七轮交替测试里，300 次 `j` 的映射/原生中位数分别为 1.369/1.367 ms 每键，`k` 为 1.260/1.291 ms 每键；同轮结果未显示 `j/k` 映射的可辨识额外成本。搜索开启/关闭时连续 `j` 的中位数为 2.930/2.687 ms 每键，含 UI、事件和服务器工作，不能全部归因于状态栏。完整样本见[主树导航证据](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/main-tree-navigation-20261004.json)。这次是热缓存合成样本，不覆盖业务项目冷启动或完整索引。

代码审计发现一处可复现的窗口行为错误：[Snacks 窗口键位](C:/Users/Administrator/AppData/Local/nvim/lua/plugins/tool/snacks.lua)把当前 help 窗口排除在编辑窗口外，却在统计其他窗口时将 help 算入。仅有一个编辑窗口和一个 help 分屏时，从编辑窗口按 `<A-w>` 会关闭编辑窗口，留下 help。后续修复应共用同一编辑窗口判定，再复验编辑窗口、help、quickfix、Neo-tree 和浮窗组合。

[precognition 规格](C:/Users/Administrator/AppData/Local/nvim/lua/plugins/editor/precognition.lua)已 `enabled=false`，对应键位不可达，属于可删除的失效配置。Tiny Code Action 的多个补丁分别覆盖菜单、单动作直执行、resolve 和底层 apply 路径；它们承担禁用动作过滤和执行拦截，不能仅凭数量判为重复。同步保存格式化最多等待 2000 ms，Code Action 等待服务器最多 3000 ms；这是可感知的响应上限，但本轮未测得具体项目卡顿，因此不据此修改语义或删除功能。除上述窗口问题外，没有测得值得为性能再改生产配置的瓶颈。

## 官方依据

- [Neovim 0.12.5](https://github.com/neovim/neovim/releases/tag/v0.12.5)：运行时与 Windows 包。
- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)：原生 config/enable 与服务器定义。
- [Tree-sitter main](https://github.com/nvim-treesitter/nvim-treesitter/tree/main)、[textobjects main](https://github.com/nvim-treesitter/nvim-treesitter-textobjects/tree/main)：API 断点。
- [Neovim Tree-sitter 选区](https://neovim.io/doc/user/treesitter/)：`an`/`in` 的节点扩展与回缩。
- [Mason-lspconfig](https://github.com/mason-org/mason-lspconfig.nvim)：automatic_enable。
- [Vue Neovim 集成](https://github.com/vuejs/language-tools/wiki/Neovim)：Vue/vtsls 组合。
- [vtsls](https://github.com/yioneko/vtsls)：SDK、设置、客户端命令。
- [efm](https://github.com/mattn/efm-langserver)、[rustaceanvim](https://github.com/mrcjkb/rustaceanvim)：格式器接入与 Cargo 调试。
- [Neovide 0.16.2](https://github.com/neovide/neovide/releases/tag/0.16.2)：GUI 包。
