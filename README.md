# 🚀 Neovim/Vim C/C++ IDE Config — 3 分钟上手 / 3-minute setup

[![Vim](https://img.shields.io/badge/Vim-8.0%2B-green.svg)](https://www.vim.org/)
[![Neovim](https://img.shields.io/badge/Neovim-0.8%2B-57A143.svg)](https://neovim.io)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Last Commit](https://img.shields.io/github/last-commit/magic-alt/nvim-cpp-ide.svg)](https://github.com/magic-alt/nvim-cpp-ide/commits)
[![CI](https://img.shields.io/github/actions/workflow/status/magic-alt/nvim-cpp-ide/ci.yml?branch=main)](.github/workflows/ci.yml)
[![Stars](https://img.shields.io/github/stars/magic-alt/nvim-cpp-ide.svg?style=social)](https://github.com/magic-alt/nvim-cpp-ide)

> **CN**：3 分钟把 Neovim/Vim 变成 C/C++ 友好的 IDE，开箱即用支持嵌入式场景（STM32/VCU）。  
> **EN**: Turn Neovim/Vim into an IDE for C/C++ in 3 minutes, tuned for embedded workflows.

**⭐ 如果本配置对你有帮助，请顺手点个 Star！**

https://github.com/magic-alt/nvim-cpp-ide

---

## ✨ Highlights / 功能亮点

- 🚀 **One-command setup / 一键部署**：`install.sh` 或内置 `:MagicInstall`（Vim/Neovim 均可）。  
- 💡 **Smart completion**：**YouCompleteMe** tuned for C/C++/Python（2-char trigger，clangd）。  
- 🛡️ **On-the-fly diagnostics**：**ALE** 预置 GCC/C++17/交叉编译参数。  
- ⚙️ **Async build/run**：**AsyncRun** 预置 `make test/run`、单文件 GCC 快速编译。  
- 🌳 **Project nav**：NERDTree 快速跳转（`<leader>e`/`<leader>f`/`<leader>m`）。  
- 🎨 **Ready-to-use UI**：真彩色、稳定状态栏、现代 C++ 语法高亮。  
- 🔧 **Embedded-friendly**：支持 `compile_commands.json` / `compile_flags.txt`，易接入交叉工具链。

> Demo  
> ![Startup](assets/demo-startup.gif) ![Telescope](assets/demo-telescope.gif) ![LSP](assets/demo-lsp.gif)

---

## ⚡ Quick Start / 快速开始（3 行命令）

### Linux/macOS
```bash
# 1) 备份你的旧配置 / Backup
mv -f ~/.config/nvim ~/.config/nvim.bak 2>/dev/null || true
mv -f ~/.vim ~/.vim.bak 2>/dev/null || true

# 2) 一键安装 / Install
bash -c "$(curl -fsSL https://raw.githubusercontent.com/magic-alt/nvim-cpp-ide/main/install.sh)"

# 3) 打开编辑器等待插件初始化 / Open and let it bootstrap
nvim || vim
```

### Windows (PowerShell)
```powershell
# 一键安装 / One-command install
Set-ExecutionPolicy Bypass -Scope Process -Force; `
iwr https://raw.githubusercontent.com/magic-alt/nvim-cpp-ide/main/install.ps1 -UseBasicParsing | iex
```

> 或者在 Vim/Neovim 中执行：`:MagicInstall`（已内置于 `config.vim`）。

---

## 🧩 Features Matrix / 配置特性一览

| 功能             | 插件                           | 说明                      |
| -------------- | ---------------------------- | ----------------------- |
| LSP/Completion | **YouCompleteMe**, `clangd`  | 2 字符触发、语义补全             |
| Diagnostics    | **ALE**                      | GCC/C++17 预置、状态栏集成      |
| Search/Jump    | **Telescope**(可选) / 内置       | Fuzzy 查找文件/符号           |
| Git            | **gitsigns.nvim**(可选)        | 行内变更/Blame              |
| UI             | **vim-airline**, `which-key` | 状态栏与按键提示                |
| Syntax         | **vim-cpp-modern**           | 现代 C++ 关键字完整高亮          |
| Async          | **AsyncRun**                 | F6/F7/F8/F9/F10/F4 预设   |
| Files          | **NERDTree**                 | `<leader>e`/`<leader>f` |

> 重点语言：**C/C++/Python**（嵌入式友好）。更多语言可按指南扩展。

---

## ⌨️ Keymaps / 快捷键总览（Top 10）

- `<leader>e`/`<leader>f`：打开目录树 / 定位当前文件
- `F7`/`F8`/`F6`：`make` / `make run` / `make test`（AsyncRun）
- `F9`：单文件 GCC 快速编译；`F10`：切换 Quickfix
- `fj` 或 `vv`：退出插入模式
- `<leader>cc`：注释切换（支持可视模式）
- `<leader>tn` / `<leader>tc`：新建 / 关闭标签页

---

## � Requirements / 环境要求

- Vim 8.0+（建议启用 Python3）或 Neovim 0.8+
- Python 3.6+、CMake ≥ 3.13、git、gcc/clang（交叉工具链可选）

---

## 📦 Manual Setup（可选）

详见 `install.sh`、`uninstall.sh`，或参考以下手动步骤与 FAQ（包含 The Ultimate vimrc 流程与 YCM 编译指引）。

---

## ❓ FAQ

- **YCM 编译失败？** 请安装 `build-essential cmake python3-dev`，并执行 `install.py --clangd-completer`。
- **颜色错乱？** 确保终端真彩：`TERM=xterm-256color`。
- **MagicInstall 无效？** 确认是通过本仓库的 `config.vim` 打开并执行。

---

## 🔭 Roadmap

见 [ROADMAP.md](ROADMAP.md)：启动速度对比、Windows 友好度、可选 minimal/full 两档配置等。

---

## 🤝 Contributing

欢迎 PR！请先阅读 [CONTRIBUTING.md](CONTRIBUTING.md) 与 [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)。
Issues/PR 模板与 CI 将帮助我们保持质量。

---

## � License

[MIT](LICENSE)

---

### Star History

[![Star History Chart](https://api.star-history.com/svg?repos=magic-alt/nvim-cpp-ide&type=Date)](https://star-history.com/#magic-alt/nvim-cpp-ide&Date)
