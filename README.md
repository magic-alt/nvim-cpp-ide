# 🚀 Vim/Neovim C/C++ 开发配置

[![Vim](https://img.shields.io/badge/Vim-8.0%2B-green.svg)](https://www.vim.org/)
[![Neovim](https://img.shields.io/badge/Neovim-0.8%2B-57A143.svg)](https://neovim.io)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Last Updated](https://img.shields.io/badge/last%20updated-2024--02--25-brightgreen.svg)](https://github.com/magic-alt/vim_config)

基于 [The Ultimate vimrc](https://github.com/amix/vimrc) 深度定制的 `config.vim`，开箱即用地兼容 Vim 8+ 与 Neovim 0.8+，专注 C/C++ 与嵌入式（含 STM32/VCU）开发场景，内置智能补全、静态检查、异步编译等完整工作流。

## 📑 目录
- [功能亮点](#-功能亮点)
- [环境要求](#-环境要求)
- [快速开始](#-快速开始)
  - [MagicInstall 一键部署](#magicinstall-一键部署)
  - [手动安装](#-手动安装)
- [配置详解](#-配置详解)
  - [核心插件](#核心插件)
  - [主题与语法高亮](#主题与语法高亮)
  - [快捷键总览](#快捷键总览)
  - [异步构建&调试](#异步构建调试)
  - [文件头模板](#文件头模板)
- [嵌入式开发提示](#-嵌入式开发提示)
- [故障排查](#-故障排查)
- [贡献指南](#-贡献指南)
- [许可证](#-许可证)

## ✨ 功能亮点
- 🚀 **一键部署**：内置 `:MagicInstall` 命令，可一键写入 `~/.vim_runtime/my_configs.vim`、`~/.config/nvim/init.vim` 等常用路径。
- 💡 **YouCompleteMe 智能补全**：针对 C/C++/Python 调优，默认启用 2 字符触发语义补全。
- 🛡️ **ALE 实时诊断**：内置 GCC/CMake/C++17 参数，适用于嵌入式交叉编译环境。
- ⚙️ **AsyncRun 自动化**：一键触发 `make`/`run`/`test`/单文件 GCC 编译，集成 quickfix 日志。
- 🌳 **NERDTree 导航**：高频操作绑定到 `<leader>e/f/m`，快速定位工程目录。
- 📄 **文件头模板**：自动生成带时间戳的 C/C++、Shell 文件头，便于嵌入式项目归档。

## 🛠️ 环境要求
- **Vim**：8.0+（建议启用 Python3 支持）
- **Neovim**：0.8+（自动兼容，首次加载会提示执行 `:MagicInstall`）
- **Python**：3.6+（YouCompleteMe 依赖）
- **Git**：最新版本
- **CMake**：≥ 3.13（用于编译 YouCompleteMe）
- **编译链**：gcc/clang，建议支持 C++17 及交叉编译工具链
- **操作系统**：Linux/macOS/Windows（含 WSL）

## ⚡ 快速开始

### MagicInstall 一键部署
该仓库的 `config.vim` 内置 `:MagicInstall` 命令，可自动侦测以下路径并写入配置：
- `~/.vim_runtime/my_configs.vim`（The Ultimate vimrc 用户）
- `~/.config/nvim/init.vim`（Neovim 用户）
- `~/.vim/my_configs.vim`（经典 Vim 用户）

```bash
# 克隆仓库后进入目录
git clone https://github.com/magic-alt/vim_config.git
cd vim_config

# 使用 Vim/Neovim 打开 config.vim 并执行一键安装
vim config.vim "+MagicInstall" +qall
# 或者
nvim config.vim "+MagicInstall" +qall
```

> 首次加载 `config.vim` 时，状态栏会提示 `:MagicInstall`，可在 Vim 内执行命令完成写入。

### 手动安装

#### 1. 安装 The Ultimate vimrc（可选）
```bash
git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
sh ~/.vim_runtime/install_awesome_vimrc.sh
```

#### 2. 编译 YouCompleteMe
```bash
cd ~/.vim_runtime/sources_non_forked/YouCompleteMe
python3 install.py --clangd-completer --verbose
```

#### 3. 安装推荐插件
```bash
cd ~/.vim_runtime/sources_non_forked/
git clone https://github.com/vim-airline/vim-airline.git
git clone https://github.com/preservim/nerdcommenter.git
git clone https://github.com/bfrg/vim-cpp-modern.git
```

#### 4. 应用配置
```bash
cp vim_config/config.vim ~/.vim_runtime/my_configs.vim
# Neovim 用户
mkdir -p ~/.config/nvim
cp vim_config/config.vim ~/.config/nvim/init.vim
```

## ⚙️ 配置详解

### 核心插件
| 插件 | 功能 | 亮点 |
|------|------|------|
| **YouCompleteMe** | 智能补全 | 2 字符触发、阻止预览窗口闪烁，自动启用语义补全 |
| **ALE** | 语法检查 | GCC/C++17 参数预置，集成 vim-airline 状态显示 |
| **NERDTree** | 文件导航 | `<leader>e` 快速打开、`<leader>f` 高亮当前文件 |
| **AsyncRun** | 异步执行 | 预设 F6/F7/F8/F9/F10/F4 快捷键，适配 make & 单文件编译 |
| **vim-commentary** | 注释管理 | 多语言注释风格自动切换 |
| **vim-cpp-modern** | 现代 C++ 语法高亮 | 支持 Concepts、Attributes、Templates 等关键字 |

### 主题与语法高亮
- 使用 **Molokai** 主题，默认启用 24-bit 真彩色（termguicolors）。
- 针对 C/C++ 提供类作用域、模板、Concepts、Attributes 全覆盖高亮。

### 快捷键总览
| 范围 | 快捷键 | 功能 |
|------|--------|------|
| 全局 | `<leader>a` | 全选并保持选区 |
| 全局 | `<leader>q` | 快速退出当前窗口 |
| 编辑 | `fj` / `vv` | 快速退出插入模式 |
| 编辑 | `<C-A>` | 一键全选复制 |
| 编辑 | `<leader>k` | 删除所有空行 |
| 对比 | `<leader>dd` | 当前缓冲区与目标文件垂直 diff |
| NERDTree | `<leader>e` | 打开/关闭目录树 |
| NERDTree | `<leader>f` | 高亮当前文件 |
| 标签页 | `<leader>tn` / `<leader>tc` | 新建/关闭标签页 |
| 注释 | `<leader>cc` | 切换注释（支持可视模式） |

### 异步构建&调试
| 快捷键 | 命令 | 使用场景 |
|---------|-------|----------|
| `F4` | 运行当前文件生成的可执行文件 | 单文件快速验证 |
| `F6` | `make test` | 单元测试入口 |
| `F7` | `make` | 编译整个项目 |
| `F8` | `make run` | 执行程序（适配嵌入式仿真） |
| `F9` | 单文件 GCC 编译 | 快速调试 C/C++ 源文件 |
| `F10` | 切换 quickfix | 查看编译输出 |

### 文件头模板
- **Shell**：自动生成 `#!/bin/bash`、文件名、创建时间等信息。
- **C/C++/Java**：输出带星号边框的注释块，满足嵌入式代码规范。

## 🔧 嵌入式开发提示
1. **STM32/VCU 工程建议**：在 `compile_commands.json` 或 `compile_flags.txt` 中加入交叉编译器参数，YCM 将自动拾取。
2. **调试工具链**：可将 `F6/F7/F8` 命令替换为 `openocd`、`st-flash`、`arm-none-eabi-gdb` 等脚本，AsyncRun 会保持 quickfix 输出。
3. **寄存器头文件补全**：将 SDK 头文件路径加入 `~/.ycm_extra_conf.py` 或 `compile_commands.json`，同时 config.vim 已将 `/usr/include/**` 加入 `path`，便于 `gf`/`:find` 跳转。

## 🚨 故障排查
### YouCompleteMe 编译失败
```bash
sudo apt update
sudo apt install build-essential cmake python3-dev
cd ~/.vim_runtime/sources_non_forked/YouCompleteMe
python3 install.py --clangd-completer --verbose
```

### 插件加载失败
```bash
ls -la ~/.vim_runtime/sources_non_forked/
rm -rf <plugin_name>
git clone <plugin_repository_url>
```

### 颜色主题显示异常
```bash
# 设置终端真彩色
echo 'export TERM=xterm-256color' >> ~/.bashrc
source ~/.bashrc
```

### Vim/Neovim 无法识别 MagicInstall
确保已从仓库根目录加载 `config.vim`：
```bash
vim -u NONE -c "so config.vim" +"MagicInstall" +qall
```
若仍报错，请确认 `autoload` 未被禁用或 `:scriptnames` 中包含 `config.vim`。

## 🤝 贡献指南
1. Fork 本仓库
2. 创建特性分支：`git checkout -b feature/amazing-feature`
3. 提交修改：`git commit -m "Add amazing feature"`
4. 推送分支：`git push origin feature/amazing-feature`
5. 创建 Pull Request 并说明测试情况

## 📄 许可证
本项目采用 [MIT 许可证](LICENSE)。欢迎在个人与商业项目中使用，并请保留版权信息。

---
**⭐ 如果这个配置对您有帮助，请给个 Star！**

> 最后更新: 2025-06-21 | 作者: [magic-alt](https://github.com/magic-alt)
