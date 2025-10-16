# Changelog

## v0.2.0
### 重大变更
- 将基于 `vim.lsp.config` 的 Neovim 0.11+ 现代配置提升为默认 `init.lua`，持续提供原 AsyncRun/F 键位等兼容工作流。
- 将 Windows 平台的 `install-lua.ps1`、`install-local-lua.ps1` 与 `first-launch.ps1` 合并为单一入口脚本，可按需执行本地安装、远程安装与首次插件引导。

### 维护记录
- 首次启动流程整合：自动检测/安装 lazy.nvim，调用 `nvim --headless "+Lazy! sync"`，并提示运行 `:Mason`、`:checkhealth` 等检查步骤。
- Neovim 0.11.4 兼容性要点：针对 `vim.tbl_*` 废弃警告、Treesitter 查询错误，提供更新插件、临时禁用 Treesitter 或抑制警告的应对策略，并在必要时建议回退至 0.10.x LTS。
- Mason 推荐安装项：`clangd`、`lua-language-server`、`clang-format`、`stylua`，确保 C/C++ 与 Lua 开发体验一致。

## v0.1.0
- 初版：C/C++/嵌入式定位、YCM/ALE/AsyncRun/NERDTree、MagicInstall、快捷键预设。
