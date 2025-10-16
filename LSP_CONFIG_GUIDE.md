# 🔧 Neovim 0.11+ LSP 配置方式说明

## ⚠️  关于警告信息

你可能看到这样的警告：
```
nvim-lspconfig is deprecated. Use vim.lsp.config instead.
```

**这个警告不会影响功能**，只是 Neovim 团队在推进新的 LSP 配置 API。

---

## 📊 三种配置方式对比

### 方案 A: 抑制警告（推荐 ✅）

**文件**: `init.lua` (当前使用)

**优势**:
- ✅ 使用成熟稳定的 `nvim-lspconfig`
- ✅ 社区支持完善，文档齐全
- ✅ 兼容 Neovim 0.8+
- ✅ 只是抑制过渡期警告
- ✅ 功能完全正常

**实现方式**:
```lua
-- 抑制 lspconfig 过渡警告
local notify = vim.notify
vim.notify = function(msg, ...)
  if msg:match("lspconfig") then
    return
  end
  notify(msg, ...)
end

-- 正常使用 nvim-lspconfig
local lspconfig = require("lspconfig")
lspconfig.clangd.setup({ ... })
lspconfig.lua_ls.setup({ ... })
```

**适合**: 所有用户，特别是需要稳定环境的项目

---

### 方案 B: 使用新 API（实验性 ⚠️）

**文件**: `init-modern.lua` (提供备选)

**优势**:
- ✅ 使用 Neovim 0.11+ 原生 API
- ✅ 无需 `nvim-lspconfig` 插件
- ✅ 更简洁的配置语法

**劣势**:
- ❌ API 还在开发中（可能变化）
- ❌ 文档不完整
- ❌ 社区插件可能不兼容
- ❌ 只支持 Neovim 0.11+

**实现方式**:
```lua
-- Neovim 0.11+ 新方式（实验性）
vim.lsp.config({
  on_attach = on_attach,
  capabilities = capabilities,
  
  servers = {
    clangd = { cmd = {...}, filetypes = {...} },
    lua_ls = { settings = {...} },
  }
})
```

**适合**: 尝鲜用户，实验性项目

---

### 方案 C: 忽略警告（不推荐 ❌）

**实现方式**: 什么都不做

**问题**: 每次启动都看到警告，影响体验

---

## 🎯 推荐选择

### 大多数用户 → **方案 A** (当前配置)

**理由**:
1. `nvim-lspconfig` 是成熟的解决方案
2. 有数千个项目在使用
3. 文档完整，社区支持好
4. 只需抑制警告即可

### 尝鲜用户 → **方案 B** (init-modern.lua)

**如何切换**:
```powershell
# 备份当前配置
Copy-Item init.lua init-lspconfig.lua

# 使用新配置
Copy-Item init-modern.lua init.lua

# 重启 Neovim
nvim
```

**切换回来**:
```powershell
Copy-Item init-lspconfig.lua init.lua
nvim
```

---

## 📚 技术背景

### nvim-lspconfig 的作用

`nvim-lspconfig` 是一个**配置集合**，提供了 200+ LSP 服务器的默认配置：

```lua
-- nvim-lspconfig 帮你做的事情
lspconfig.clangd.setup({
  cmd = { "clangd", ... },  -- 默认启动命令
  filetypes = { "c", "cpp" },  -- 默认文件类型
  root_dir = root_pattern(...),  -- 默认项目根目录检测
  -- 还有很多默认设置
})
```

### vim.lsp.config 的目标

Neovim 0.11+ 想把这些默认配置**内置到 Neovim**，不再需要外部插件：

```lua
-- 未来的理想方式（还在开发）
vim.lsp.config({
  servers = {
    clangd = {},  -- Neovim 内置默认配置
    lua_ls = {},  -- 无需手动指定 cmd/filetypes
  }
})
```

### 当前状态（2025-10）

- ✅ `nvim-lspconfig` - 成熟、稳定
- ⚠️  `vim.lsp.config` - 正在开发，API 不稳定
- 📅 预计 Neovim 0.12+ 才会稳定

---

## 🔍 验证当前配置

### 检查警告是否消失

```powershell
nvim --headless "+qa" 2>&1 | Select-String -Pattern "lspconfig|deprecated"
```

如果没有输出，说明警告已被抑制 ✅

### 测试 LSP 功能

```vim
" 在 Neovim 中
:edit test.cpp

" 输入代码
int main() {
    std::cout << "test";
}

" 测试功能
" 1. 补全: 按 <C-Space>
" 2. 悬停: 光标放在 std 上按 K
" 3. 跳转: 光标放在 main 上按 gd
" 4. 格式化: 按 <leader>lf
```

### 查看 LSP 状态

```vim
:LspInfo
:Mason
:checkhealth
```

---

## 📖 相关资源

### nvim-lspconfig 文档
- GitHub: https://github.com/neovim/nvim-lspconfig
- 配置示例: `:help lspconfig-setup`
- 服务器列表: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md

### vim.lsp.config 文档
- Neovim API: `:help vim.lsp.config`
- 迁移指南: `:help lspconfig-nvim-0.11`
- 状态跟踪: https://github.com/neovim/neovim/issues/XXXX

---

## 🎯 总结

### 当前配置（推荐）✅

**文件**: `init.lua`
- ✅ 使用 `nvim-lspconfig`（成熟）
- ✅ 抑制过渡期警告
- ✅ 功能完全正常
- ✅ 社区支持完善

### 备选配置（实验）⚠️

**文件**: `init-modern.lua`
- ⚠️  使用 `vim.lsp.config`（实验）
- ⚠️  API 可能变化
- ⚠️  仅供尝鲜

---

## 💡 建议

1. **继续使用当前配置** (`init.lua`)
2. **关注 Neovim 发布说明**，等待 `vim.lsp.config` API 稳定
3. **定期更新插件**: `:Lazy sync`
4. **如果好奇**，可以测试 `init-modern.lua`，但建议备份

**警告已被抑制，功能完全正常，可以放心使用！** ✅
