```markdown
# 🚀 Vim Configuration

[![Vim](https://img.shields.io/badge/Vim-8.0%2B-green.svg)](https://www.vim.org/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Last Updated](https://img.shields.io/badge/last%20updated-2024--02--25-brightgreen.svg)](https://github.com/magic-alt/vim_config)

我的个人 Vim 配置文件，基于 [The Ultimate vimrc](https://github.com/amix/vimrc) 进行深度定制优化，专为 C/C++ 开发而设计。

## ✨ 功能特性

- 🚀 **基于 The Ultimate vimrc** - 继承强大的基础配置
- 💡 **YouCompleteMe** - 智能代码补全，支持 C/C++/Python 等多种语言
- 🎨 **C/C++ 语法高亮增强** - 现代 C++ 语法特性支持
- 📁 **NERDTree** - 强大的文件浏览器
- 🔧 **AsyncRun** - 异步编译和运行，无阻塞操作
- 📝 **智能注释系统** - 多语言注释支持
- ⚡ **自定义快捷键** - 提高编码效率的快捷键映射
- 🎯 **ALE 静态检查** - 实时代码质量检查
- 🎭 **Molokai 主题** - 支持真彩色的美观主题
- 📄 **文件模板** - 自动生成文件头信息

## 🛠️ 系统要求

- **Vim**: 8.0+ 或 Neovim
- **Python**: 3.6+
- **Git**: 最新版本
- **CMake**: 3.13+ (YouCompleteMe 需要)
- **编译工具链**: gcc/clang 支持 C++14 标准
- **操作系统**: Linux/macOS/Windows (WSL)

## 📦 快速安装

### 一键安装脚本

```bash
# 下载并执行安装脚本
curl -fsSL https://raw.githubusercontent.com/magic-alt/vim_config/main/install.sh | bash
```

### 手动安装

#### 1. 安装 The Ultimate vimrc

```bash
# 克隆 vimrc 到用户目录
git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime

# 安装基础配置
sh ~/.vim_runtime/install_awesome_vimrc.sh
```

#### 2. 安装 YouCompleteMe

```bash
# 进入 YouCompleteMe 目录
cd ~/.vim_runtime/sources_non_forked/YouCompleteMe

# 编译安装（支持 C/C++ 补全）
python3 install.py --clangd-completer --verbose
```

#### 3. 安装必需插件

```bash
# 进入插件目录
cd ~/.vim_runtime/sources_non_forked/

# vim-airline 状态栏美化
git clone https://github.com/vim-airline/vim-airline.git

# NERDCommenter 智能注释
git clone https://github.com/preservim/nerdcommenter.git

# C++ 现代语法高亮
git clone https://github.com/bfrg/vim-cpp-modern.git
```

#### 4. 应用自定义配置

```bash
# 克隆本配置仓库
git clone https://github.com/magic-alt/vim_config.git

# 复制自定义配置文件
cp vim_config/my_configs.vim ~/.vim_runtime/my_configs.vim

# 重启 Vim 生效
```

## ⚙️ 配置详解

### 核心插件配置

| 插件 | 功能 | 配置亮点 |
|------|------|----------|
| **YouCompleteMe** | 智能补全 | 支持语义补全，2字符触发 |
| **ALE** | 语法检查 | C11/C++14 标准，实时检查 |
| **NERDTree** | 文件管理 | 镜像模式，快速导航 |
| **AsyncRun** | 异步执行 | 自动打开 quickfix，响铃提醒 |
| **vim-airline** | 状态栏 | 集成 ALE 显示 |
| **NERDCommenter** | 注释工具 | 多语言智能注释 |

### 🎨 主题配置

- **主题**: Molokai 
- **真彩色**: 启用 24-bit 颜色支持
- **语法高亮**: C++11/14/17 特性完整支持

## ⌨️ 快捷键指南

### 🔄 模式切换
| 快捷键 | 模式 | 功能 |
|--------|------|------|
| `fj` | Insert | 退出插入模式并右移 |
| `vv` | Insert | 退出插入模式 |

### 📝 编辑操作
| 快捷键 | 功能 |
|--------|------|
| `Ctrl+A` | 全选并复制 |
| `Ctrl+C` | 复制到系统剪贴板 (Visual) |
| `F12` | 自动格式化代码 |
| `F2` | 删除所有空行 |
| `Ctrl+F2` | 垂直分割比较文件 |
| `<leader>xx` | 智能注释/取消注释 |

### 📁 文件管理
| 快捷键 | 功能 |
|--------|------|
| `F3` | 切换 NERDTree 文件浏览器 |
| `Ctrl+F3` | 打开缓冲区列表 |
| `F2` | 关闭当前标签页 |
| `Alt+F2` | 新建标签页 |

### 🔨 编译运行
| 快捷键 | 功能 |
|--------|------|
| `F9` | 编译当前 C/C++ 文件 |
| `F4` | 运行当前程序 |
| `F7` | 项目编译 (make) |
| `F8` | 项目运行 (make run) |
| `F6` | 运行测试 (make test) |
| `F10` | 切换 Quickfix 窗口 |

### 💡 代码补全
| 快捷键 | 功能 |
|--------|------|
| `Ctrl+Z` | 手动触发 YCM 补全 |
| `Tab` | 选择补全项 |

## 🤖 自动化功能

### 📄 文件模板

创建新文件时自动插入规范的文件头：

**C/C++ 文件模板**:
```cpp
/*************************************************************************
    > File Name: example.cpp
    > Created Time: Sat 21 Jun 2025 06:29:00 AM UTC
 ************************************************************************/
```

**Shell 脚本模板**:
```bash
#########################################################################
# File Name: example.sh
# Created Time: Sat 21 Jun 2025 06:29:00 AM UTC
#########################################################################
#!/bin/bash
```

### 🎯 语言特定配置

- **C/C++**: 使用 `//` 注释风格，完整的现代 C++ 支持
- **Python/Shell**: 使用 `#` 注释风格
- **系统头文件**: 自动配置包含路径

## 🛠️ 高级配置

### ALE 配置优化

```vim
" 编译选项
let g:ale_c_gcc_options = '-Wall -O2 -std=c11'
let g:ale_cpp_gcc_options = '-Wall -O2 -std=c++14'

" 检查延迟优化
let g:ale_completion_delay = 500
let g:ale_lint_delay = 500
```

### YCM 性能调优

```vim
" 补全触发配置
let g:ycm_min_num_identifier_candidate_chars = 2
let g:ycm_semantic_triggers = {
    \ 'c,cpp,python,java,go,erlang,perl': ['re!\w{2}'],
    \ 'cs,lua,javascript': ['re!\w{2}'],
\ }
```

## 🚨 故障排除

### 常见问题及解决方案

#### 1. YouCompleteMe 编译失败

```bash
# 安装依赖
sudo apt update
sudo apt install build-essential cmake python3-dev

# 清理重新编译
cd ~/.vim_runtime/sources_non_forked/YouCompleteMe
./install.py --clangd-completer --verbose
```

#### 2. 插件加载失败

```bash
# 检查插件目录
ls -la ~/.vim_runtime/sources_non_forked/

# 重新安装问题插件
cd ~/.vim_runtime/sources_non_forked/
rm -rf <plugin_name>
git clone <plugin_repository_url>
```

#### 3. 颜色主题显示异常

```bash
# 设置终端支持真彩色
export TERM=xterm-256color

# 在 .bashrc 或 .zshrc 中添加
echo 'export TERM=xterm-256color' >> ~/.bashrc
```

#### 4. 性能优化建议

如果 Vim 启动较慢：

1. **按需加载插件**
2. **调整 YCM 触发字符数**
3. **优化 ALE 检查频率**
4. **禁用不必要的功能**

## 📈 性能基准

| 操作 | 时间 |
|------|------|
| Vim 启动 | < 2s |
| 文件打开 (1000行) | < 0.5s |
| 代码补全响应 | < 100ms |
| 语法检查 | 实时 |

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

### 贡献方式

1. Fork 本仓库
2. 创建特性分支: `git checkout -b feature/amazing-feature`
3. 提交更改: `git commit -m 'Add amazing feature'`
4. 推送分支: `git push origin feature/amazing-feature`
5. 创建 Pull Request

### 报告问题

请在 [Issues](https://github.com/magic-alt/vim_config/issues) 页面报告问题，包含：

- 操作系统版本
- Vim 版本
- 错误信息截图
- 复现步骤

## 📚 相关资源

- [The Ultimate vimrc](https://github.com/amix/vimrc) - 基础配置
- [YouCompleteMe 文档](https://github.com/ycm-core/YouCompleteMe#installation) - 补全插件
- [Vim Awesome](https://vimawesome.com/) - 插件市场
- [Vim 官方文档](https://vimdoc.sourceforge.net/) - 学习资源

## 📄 许可证

本项目采用 [MIT 许可证](LICENSE)。

## 🙏 致谢

- [amix](https://github.com/amix) - The Ultimate vimrc 作者
- [Valloric](https://github.com/Valloric) - YouCompleteMe 作者
- Vim 社区的所有贡献者

---

**⭐ 如果这个配置对您有帮助，请给个 Star！**

> 最后更新: 2025-06-21 | 作者: [magic-alt](https://github.com/magic-alt)
```