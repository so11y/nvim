# 回归验证

在配置仓库根目录执行：

```sh
npm --prefix scripts/verification ci
npm --prefix scripts/verification test
```

需要 PATH 中的 Neovim 0.12+、Node.js、npm、Git 和 LazyGit，以及已通过 Lazy 安装的插件、Mason 工具和 Tree-sitter 解析器。普通回归不会安装或更新这些组件；样例项目使用锁文件执行 `npm ci`，因此需要能访问 npm 或已有 npm 缓存。Node 调试检查使用 Mason 的 js-debug-adapter。Git UI 检查需要 LazyGit 已完成首次启动提示。

统一入口从仓库根目录启动 Neovim，并按配置目录名设置 `NVIM_APPNAME`。可用 `NEOVIM_BIN` 指定 Neovim 可执行文件。

## 选择场景

```sh
npm --prefix scripts/verification run test:list
npm --prefix scripts/verification test -- formatting textobjects linked-tags
```

默认运行列表中未标记 optional 的全部场景，包括编辑、格式化、语言服务、Node 调试和 UI 回归。可以一次指定多个场景；失败后继续运行其余场景，最终以非零状态退出。

`mason-commands` 使用已安装的本地注册表，检查原生命令和补全时关闭该测试进程的元数据刷新，避免顺带下载注册表。

以下检查按需显式选择：

| 场景 | 用途与条件 |
| --- | --- |
| `performance` | 结构跳转基准，含大量 Vue 模板注入树 |
| `navigation-performance` | UI 输入与导航计时 |
| `rust-debug` | 需要 Rust 工具链、项目所需 target、链接器及 CodeLLDB |
| `host` | VS Code 宿主桥接；先设置 `NVIM_VSCODE_RUNTIME` 为 vscode-neovim 扩展运行时目录 |
| `installation` | 验证插件、工具版本和解析器是否齐备，不执行安装 |

例如 `npm --prefix scripts/verification test -- performance installation`。`host` 使用扩展的 `vscode-neovim.vim`，通过模拟 RPC 宿主检查动作转发；不控制正在运行的 VS Code。

## 样例与结果

入口在系统临时目录创建 `nvim-verification-results-*`，开始和结束时都会打印绝对路径。目录中保存 `results.json` 汇总、各场景日志及 UI 场景的 JSON 和 `.errors`。性能和安装检查也将 JSON 写入该目录。

`fixtures/` 是版本管理中的只读模板。每次运行只安装一次样例依赖，每个场景使用独立的临时文件副本并共享该次运行的依赖目录；测试中的保存、重命名和格式化不会修改仓库里的模板。结果保留供检查，可在不再需要时删除对应临时目录。

## 脚本分工

| 文件或目录 | 职责 |
| --- | --- |
| `run.mjs` | 场景选择、临时项目、进程执行、结果汇总 |
| `check-ui.mjs` | Neovim RPC、UI 初始化、超时与进程清理、结果收集 |
| `ui/` | 按功能拆分的 UI 场景；`index.mjs` 注册场景名 |
| `*.lua` | 独立或由 UI 执行器运行的 Lua 检查 |
| `create-fixtures.mjs` | 复制模板并安装样例依赖，也可单独运行 |
| `../check-workflows.lua` | 多语言编辑工作流 |
| `../check-performance.lua` | 结构跳转基准 |

新增 UI 场景时在 `ui/index.mjs` 注册即可；新增独立 Lua 场景时在 `run.mjs` 对应列表登记。需要单独调试 UI 执行器时，先运行 `node scripts/verification/create-fixtures.mjs`，按输出设置 `NVIM_TEST_ROOT`，再运行 `node scripts/verification/check-ui.mjs 场景名`；未指定结果路径时仍写入新的临时目录。
