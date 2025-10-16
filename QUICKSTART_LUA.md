# ⚡ 快速入门 - Lua 版本

## 🚀 三步快速安装

### Windows

```powershell
# 1. 安装配置
.\install-local-lua.ps1

# 2. 运行首次启动助手（重要！）
.\first-launch.ps1

# 3. 启动 Neovim
nvim
```

### 远程安装 (Windows)

```powershell
# 一键安装
Set-ExecutionPolicy Bypass -Scope Process -Force; `
iwr https://raw.githubusercontent.com/magic-alt/nvim-cpp-ide/main/install-lua.ps1 -UseBasicParsing | iex

# 然后在 Neovim 中等待插件安装（首次启动 ~2 分钟）
nvim
```

### Linux/macOS

```bash
# 安装
git clone --depth 1 https://github.com/magic-alt/nvim-cpp-ide.git /tmp/nvim-cpp-ide
mkdir -p ~/.config/nvim
cp /tmp/nvim-cpp-ide/init.lua ~/.config/nvim/init.lua

# 首次启动（等待插件安装）
nvim
```

---

## 📋 首次启动后必做

### 1. 安装 LSP 服务器

在 Neovim 中执行：

```vim
:Mason
```

然后：
- 移动到 `clangd`，按 `i` 安装
- 移动到 `lua-language-server`，按 `i` 安装  
- 移动到 `clang-format`，按 `i` 安装
- 移动到 `stylua`，按 `i` 安装

或者一键安装：

```vim
:MasonInstall clangd lua-language-server clang-format stylua
```

### 2. 验证安装

```vim
:checkhealth
```

确保没有红色错误。黄色警告通常可以忽略。

### 3. 重启 Neovim

退出并重新打开 Neovim，享受飞速启动！ ⚡

---

## ⌨️ 常用快捷键

### 文件操作
- `<C-n>` - 打开/关闭文件树
- `<leader>ff` - 查找文件 (Telescope)
- `<leader>fg` - 全局搜索 (Telescope)
- `<leader>fb` - 查看缓冲区

### LSP 功能
- `gd` - 跳转到定义
- `gr` - 查找引用
- `K` - 查看文档
- `<leader>rn` - 重命名
- `<leader>ca` - 代码操作
- `<leader>lf` - 格式化代码

### 诊断导航
- `[e` 或 `[d` - 上一个错误
- `]e` 或 `]d` - 下一个错误
- `<leader>e` - 显示行诊断

### 代码补全
- `<C-Space>` - 触发补全
- `<Tab>` - 选择下一项
- `<Shift-Tab>` - 选择上一项
- `<CR>` - 确认选择

### 构建/运行 (AsyncRun)
- `<F6>` - make test
- `<F7>` - make
- `<F8>` - make run
- `<F9>` - 编译当前文件
- `<F10>` - 打开 QuickFix

### 查看更多
- 按 `<Space>` (空格键) - 显示所有 leader 键位
- `:WhichKey` - 查看完整键位映射

---

## 🔥 测试 LSP 功能

### 1. 创建测试文件

```cpp
// test.cpp
#include <iostream>
#include <vector>

int main() {
    std::vector<int> nums = {1, 2, 3, 4, 5};
    
    for (const auto& num : nums) {
        std::cout << num << std::endl;
    }
    
    return 0;
}
```

### 2. 测试功能

- **补全**: 输入 `std::` 然后按 `<C-Space>`
- **悬停文档**: 将光标放在 `vector` 上按 `K`
- **跳转定义**: 将光标放在 `main` 上按 `gd`
- **格式化**: 按 `<leader>lf`

---

## 🎯 性能对比

| 指标 | VimScript 版 | Lua 版 |
|------|--------------|--------|
| 启动时间 | ~150ms | **~80ms** ⚡ |
| 内存占用 | ~120MB | **~100MB** 💾 |
| 插件数量 | 6-8 个 | **25 个** 🎁 |
| 补全引擎 | YCM | **原生 LSP** 🚀 |

---

## 📚 进阶学习

- **完整迁移指南**: `LUA_MIGRATION_GUIDE.md`
- **首次启动指南**: `FIRST_LAUNCH_GUIDE.md`  
- **原始 VimScript 版**: 使用 `.\install-local.ps1`

---

## ❓ 遇到问题？

### 常见问题

1. **"module 'lazy' not found"**
   - 运行 `.\first-launch.ps1` 自动修复

2. **LSP 不工作**
   - 运行 `:Mason` 安装 LSP 服务器
   - 运行 `:LspInfo` 检查状态

3. **补全不触发**
   - 按 `<C-Space>` 手动触发
   - 确保 LSP 服务器已安装

4. **启动很慢**
   - 首次启动慢是正常的（安装插件）
   - 第二次启动应该很快 (~100ms)

### 获取帮助

```vim
:help lua-guide
:help lsp
:checkhealth
```

---

## 🎉 开始使用

现在你拥有一个现代化的 Neovim C/C++ IDE！

**开始编码吧！** 🚀
