# 🚀 首次启动指南 / First Launch Guide

## ⚠️ 重要提示

首次启动 Lua 版本配置时，Neovim 需要：
1. 下载并安装 lazy.nvim 插件管理器
2. 下载并安装所有插件（~20 个）
3. 编译 Treesitter 语法解析器

**这个过程需要 2-5 分钟，请耐心等待！**

---

## 📝 正确的首次启动流程

### 步骤 1: 安装配置

```powershell
# Windows
.\install-local-lua.ps1

# 或远程安装
Set-ExecutionPolicy Bypass -Scope Process -Force; `
iwr https://raw.githubusercontent.com/magic-alt/nvim-cpp-ide/main/install-lua.ps1 -UseBasicParsing | iex
```

### 步骤 2: 首次启动（重要！）

```powershell
# 方式 A: 直接启动（推荐）
nvim

# 首次启动会看到：
# - "Installing lazy.nvim plugin manager..."
# - 插件安装进度条
# - Treesitter 编译信息
# - 等待完成后按 Enter 或 q 退出

# 方式 B: 强制同步安装（如果方式 A 有问题）
nvim --headless "+Lazy! sync" +qa
```

### 步骤 3: 重启 Neovim

```powershell
nvim
```

现在应该没有错误了！

---

## 🔍 常见首次启动问题

### 问题 1: "module 'lazy' not found"

**原因**: Git 克隆 lazy.nvim 失败

**解决方案**:
```powershell
# 手动克隆 lazy.nvim
$lazypath = "$env:LOCALAPPDATA\nvim-data\lazy\lazy.nvim"
git clone --filter=blob:none https://github.com/folke/lazy.nvim.git --branch=stable $lazypath

# 重启 Neovim
nvim
```

### 问题 2: 网络超时

**原因**: GitHub 连接慢

**解决方案 A - 使用镜像**:
```powershell
# 编辑 init.lua，替换 GitHub URL
# 将所有 "https://github.com/" 改为 "https://mirror.ghproxy.com/https://github.com/"
```

**解决方案 B - 使用代理**:
```powershell
# 设置 Git 代理
git config --global http.proxy http://127.0.0.1:7890
git config --global https.proxy http://127.0.0.1:7890
```

### 问题 3: LSP 服务器未安装

**原因**: 只安装了插件，还需要安装 LSP 服务器

**解决方案**:
```vim
# 在 Neovim 中执行
:Mason

# 在 Mason 界面中:
# 1. 移动到 clangd
# 2. 按 'i' 安装
# 3. 等待安装完成
# 4. 重复安装 lua-language-server, clang-format

# 或者命令行安装
:MasonInstall clangd lua-language-server clang-format stylua
```

---

## ✅ 验证安装成功

### 1. 检查插件状态

```vim
:Lazy
```

应该看到所有插件都是绿色 ✓

### 2. 检查 LSP 服务器

```vim
:Mason
```

应该看到已安装的服务器

### 3. 测试 LSP 功能

```vim
# 打开一个 C++ 文件
:e test.cpp

# 输入一些代码
int main() {
    std::cout << "Hello";
}

# 按 <C-Space> 应该出现补全菜单
# 将光标放在 std 上按 K 应该显示文档
```

### 4. 运行健康检查

```vim
:checkhealth
```

查看是否有红色错误。黄色警告通常可以忽略。

---

## 🎯 完整的首次设置清单

- [ ] 安装配置文件
- [ ] 首次启动 Neovim（等待插件安装）
- [ ] 重启 Neovim
- [ ] 运行 `:Mason` 安装 LSP 服务器
  - [ ] clangd
  - [ ] lua-language-server  
  - [ ] clang-format
  - [ ] stylua
- [ ] 运行 `:checkhealth` 验证
- [ ] 测试代码补全 (`<C-Space>`)
- [ ] 测试文件树 (`<C-n>`)
- [ ] 测试 Telescope (`<leader>ff`)

---

## 🚨 如果一切都失败了

### 完全重置

```powershell
# 删除所有 Neovim 数据
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\nvim"
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\nvim-data"

# 重新安装
.\install-local-lua.ps1
nvim
```

### 使用 VimScript 版本

如果 Lua 版本持续有问题，可以先使用稳定的 VimScript 版本：

```powershell
.\install-local.ps1  # 安装 config.vim
nvim
```

---

## 📊 预期首次启动时间

| 阶段 | 时间 | 说明 |
|------|------|------|
| 克隆 lazy.nvim | ~10s | 下载插件管理器 |
| 下载插件 | ~60s | 下载 20+ 个插件 |
| 编译 Treesitter | ~30s | 编译语法解析器 |
| **总计** | **~2 分钟** | 取决于网速 |

后续启动：~100ms ⚡

---

## 💡 提示

1. **第一次启动很慢是正常的**，不要中途关闭！
2. 看到很多文字滚动是正常的，这是插件在安装
3. 如果卡住超过 5 分钟，按 `Ctrl+C` 退出，然后重试
4. 安装完成后重启 Neovim，体验会变得飞快！

---

## 🎉 安装成功后

恭喜！你现在拥有一个现代化的 Neovim C/C++ IDE：

- ⚡ 原生 LSP 补全
- 🎨 Treesitter 语法高亮
- 📁 nvim-tree 文件浏览
- 🔍 Telescope 模糊搜索
- 🎯 一键格式化
- 🚀 启动速度 ~80ms

**按 `<Space>` 查看所有快捷键！**

**阅读 `LUA_MIGRATION_GUIDE.md` 了解更多功能！**
