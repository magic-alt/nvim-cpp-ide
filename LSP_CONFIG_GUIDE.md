# 🔧 Neovim 0.11+ LSP 配置方式说明

## ⚠️  关于警告信息

你可能看到这样的警告：
```
nvim-lspconfig is deprecated. Use vim.lsp.config instead.
```

**这个警告不会影响功能**，只是 Neovim 团队在推进新的 LSP 配置 API。

---

## 📊 两种配置方式对比

### 方案 A: Neovim 0.11+ 原生 API（默认 ✅）

**文件**: `init.lua`

**优势**:
- ✅ 直接使用 `vim.lsp.config`，减少对第三方插件的依赖
- ✅ 与 lazy.nvim、Mason 的初始化流程无缝整合
- ✅ 代码更精简，便于后续跟随 Neovim 官方演进

**注意事项**:
- ⚠️ 需要 Neovim 0.11 nightly 或以上版本（提供 `vim.lsp.config`）
- ⚠️ API 仍在快速演进，如遇到重大变更请关注 `CHANGELOG.md`

**实现方式**:
```lua
vim.lsp.config({
  on_attach = on_attach,
  capabilities = capabilities,
  servers = {
    clangd = {
      cmd = {
        "clangd",
        "--background-index",
        "--clang-tidy",
        "--header-insertion=iwyu",
        "--completion-style=detailed",
        "--function-arg-placeholders",
      },
      filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
    },
    lua_ls = {
      settings = {
        Lua = {
          diagnostics = { globals = { "vim" } },
          workspace = { checkThirdParty = false },
          telemetry = { enable = false },
        },
      },
    },
  },
})
```

**适合**: 已升级到 Neovim 0.11+、希望体验最新原生 LSP 流程的用户

---

### 方案 B: 继续使用 `nvim-lspconfig`（兼容 0.8~0.10 ⚠️）

**文件**: `config.vim`（VimScript 版本）或仓库历史版本中的 `init.lua`

**优势**:
- ✅ 支持稳定版 Neovim 0.8~0.10 以及 Vim 8.0+
- ✅ 生态成熟，文档、示例丰富

**注意事项**:
- ⚠️ 需要继续安装 `nvim-lspconfig`、`mason-lspconfig` 等插件
- ⚠️ 建议通过 `CHANGELOG.md` 确认兼容性更新

**切换方式**:
```powershell
# 使用 VimScript 版本（兼容 0.8~0.10）
Copy-Item config.vim "$env:LOCALAPPDATA\nvim\init.vim" -Force

# 或者检出历史版本的 init.lua（v0.1.0 仍基于 nvim-lspconfig）
git checkout v0.1.0 init.lua
```

**适合**: 仍在使用 Neovim 0.10 及更早版本、或需要 Vim 兼容性的环境

---

### 方案 C: 忽略警告（不推荐 ❌）

**实现方式**: 什么都不做

**问题**: 每次启动都看到警告，且无法享受新 API 优化

---

## 🎯 推荐选择

- **已经升级 Neovim 0.11+** → 选择方案 A（仓库默认配置）
- **必须保持兼容 0.8~0.10 或 Vim** → 选择方案 B（使用 `config.vim` 或 v0.1.0 的 `init.lua`）

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

### 当前配置（默认）✅

**文件**: `init.lua`
- ✅ 使用 `vim.lsp.config` 原生 API
- ✅ 与 lazy.nvim、Mason 深度集成
- ✅ 针对 Neovim 0.11+ 调优

### 兼容配置（旧版）⚠️

**文件**: `config.vim` 或 v0.1.0 的 `init.lua`
- ⚠️ 基于 `nvim-lspconfig`，适合 Neovim 0.8~0.10 / Vim 8.0+
- ⚠️ 需要保留旧版依赖与插件

---

## 💡 建议

1. **Neovim 0.11+ 用户** → 按默认 `init.lua` 使用，并定期 `:Lazy sync` / `:Mason` 更新。
2. **需要旧版兼容** → 复制 `config.vim` 或检出 v0.1.0 的 `init.lua`。
3. **关注 `CHANGELOG.md`** → 第一时间获知兼容性修复与 API 变动。
4. **遇到问题** → 可使用 `install-lua.ps1 -FirstLaunchOnly` 重新执行 Lazy 同步。
