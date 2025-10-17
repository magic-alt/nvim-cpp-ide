# Neovim 0.11+ LSP 配置修复说明

## 问题描述

Neovim 0.11 改变了 `vim.lsp.config()` 的 API 签名：
- **旧方式（错误）**: `vim.lsp.config({ servers = { ... } })`
- **新方式（正确）**: `vim.lsp.config("name", opts)` + `vim.lsp.enable("name")`

## 修复内容

### 1. 修正 LSP 配置方式（Lines 357-391）

**修改前：**
```lua
vim.lsp.config({
  on_attach = on_attach,
  capabilities = capabilities,
  servers = {
    clangd = { ... },
    lua_ls = { ... },
  },
})
```

**修改后：**
```lua
local common = { on_attach = on_attach, capabilities = capabilities }

vim.lsp.config("clangd", vim.tbl_deep_extend("force", common, {
  cmd = { "clangd", "--background-index", ... },
  filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
}))

vim.lsp.config("lua_ls", vim.tbl_deep_extend("force", common, {
  settings = { Lua = { ... } },
  filetypes = { "lua" },
}))

vim.lsp.enable("clangd")
vim.lsp.enable("lua_ls")
```

### 2. 修复键位冲突（Lines 349-353）

移除了 `<leader>e` 的诊断绑定，因为它已经被 NvimTreeToggle 占用：

**修改前：**
```lua
map("n", "<leader>e", vim.diagnostic.open_float, "Line diagnostics")
```

**修改后：**
```lua
map("n", "gl", vim.diagnostic.open_float, "Line diagnostics")
-- <leader>e 已被 NvimTreeToggle 占用
```

## 新的键位映射

### LSP 功能
- `gd` - 跳转到定义
- `gD` - 跳转到声明
- `gr` - 查看引用
- `gi` - 跳转到实现
- `gt` - 跳转到类型定义
- `K` - 悬浮文档
- `<C-k>` - 签名帮助
- `<leader>rn` - 重命名
- `<leader>ca` - 代码操作
- `<leader>lf` - 格式化

### 诊断导航
- `[d` - 上一个诊断
- `]d` - 下一个诊断
- `gl` - 显示当前行诊断（悬浮窗口）
- `<leader>q` - 诊断快速修复列表

### 文件树
- `<leader>e` - 切换文件树（NvimTree）
- `<C-n>` - 切换文件树

## 参考

- [Neovim 0.11 News](https://neovim.io/doc/user/news-0.11.html)
- Issue: `name: expected non-wildcard string, got table` from `validate_config_name`

## 测试

启动 Neovim 后应该看到：
```
Using Neovim 0.11+ native LSP config
```

打开 C/C++ 或 Lua 文件时，LSP 应该自动启动并提供补全、诊断等功能。
