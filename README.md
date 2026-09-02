# 🚀 Neovim/Vim C/C++ IDE Config — 3-minute setup

[![Vim](https://img.shields.io/badge/Vim-8.0%2B-green.svg)](https://www.vim.org/)
[![Neovim](https://img.shields.io/badge/Neovim-0.11%2B-57A143.svg)](https://neovim.io)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![CI](https://img.shields.io/github/actions/workflow/status/magic-alt/nvim-cpp-ide/ci.yml?branch=main)](.github/workflows/ci.yml)

> **CN**：3 分钟把 Neovim/Vim 变成 C/C++ 友好的 IDE，并为 Coding Agent 工作流提供可扩展基础。  
> **EN**: Turn Neovim/Vim into a C/C++ IDE in 3 minutes, with an extensible foundation for coding-agent workflows.

## Lua edition: Neovim 0.11+

The recommended configuration now uses a modular layout instead of a monolithic `init.lua`:

```text
init.lua
└── lua/nvim_cpp_ide/
    ├── core/       # editor options and keymaps
    ├── plugins/    # lazy.nvim specs
    ├── project/    # project-root primitives
    ├── agent/      # provider-neutral agent profile foundation
    ├── lsp.lua
    ├── tasks.lua
    └── profile.lua
```

The default behavior remains the full C/C++ IDE experience.

### Profiles

Choose a profile with `NVIM_CPP_IDE_PROFILE` or `vim.g.nvim_cpp_ide_profile`:

| Profile | Purpose | Includes |
|---|---|---|
| `minimal` | lightweight editor | navigation, Treesitter, Telescope, Git/UI helpers |
| `cpp` | default C/C++ IDE | `minimal` + clangd/LSP, completion, formatting, AsyncRun |
| `agent` | agent-ready foundation | `cpp` + safe external-file detection and provider-neutral agent terminal |

Linux/macOS example:

```bash
NVIM_CPP_IDE_PROFILE=agent nvim
```

PowerShell example:

```powershell
$env:NVIM_CPP_IDE_PROFILE = 'agent'
nvim
```

The `agent` profile deliberately does **not** bind the configuration to Codex, Claude Code, Gemini CLI or another provider yet. It establishes the lifecycle and terminal/file-sync primitives that future adapters can share.

## Quick start

### Recommended Lua version — Neovim 0.11+

#### Linux/macOS

```bash
mv -f ~/.config/nvim ~/.config/nvim.bak.$(date +%Y%m%d) 2>/dev/null || true

git clone --depth 1 https://github.com/magic-alt/nvim-cpp-ide.git /tmp/nvim-cpp-ide
mkdir -p ~/.config/nvim
cp /tmp/nvim-cpp-ide/init.lua ~/.config/nvim/init.lua
cp -R /tmp/nvim-cpp-ide/lua ~/.config/nvim/lua

nvim
```

#### Windows PowerShell

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; `
iwr https://raw.githubusercontent.com/magic-alt/nvim-cpp-ide/main/install-lua.ps1 -UseBasicParsing | iex
```

The installer backs up the previous config, installs both `init.lua` and the modular `lua/` tree, then runs the first lazy.nvim synchronization.

### Legacy VimScript version — Vim 8.0+ / older Neovim

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/magic-alt/nvim-cpp-ide/main/install.sh)"
```

The legacy `config.vim` path remains available for Vim compatibility. New feature development targets Neovim 0.11+ first.

## C/C++ feature set

The default `cpp` profile includes:

- Neovim 0.11 native `vim.lsp.config` / `vim.lsp.enable`
- clangd and lua_ls configuration
- nvim-cmp + LuaSnip completion
- Treesitter syntax/AST support
- Telescope navigation
- nvim-tree file explorer
- gitsigns Git hunks/blame
- conform.nvim formatting
- AsyncRun build/test/run compatibility
- Mason package UI

Recommended external tools:

```text
clangd
clang-format
lua-language-server
stylua
```

Inside Neovim you can install them through Mason, for example:

```vim
:MasonInstall clangd lua-language-server clang-format stylua
```

## Agent profile foundation

With `NVIM_CPP_IDE_PROFILE=agent`, two provider-neutral primitives are enabled:

```vim
:AgentProfileInfo
:AgentTerminal [command]
```

`AgentTerminal` opens a terminal rooted at the detected project root. Root detection currently recognizes `.git`, `CMakePresets.json`, `CMakeLists.txt`, `Makefile`, `meson.build`, `platformio.ini` and `west.yml`.

The profile also runs conservative `:checktime` checks when focus/buffer state changes, but only when the current buffer is not locally modified. This prepares Neovim for files changed by external coding agents without silently overwriting local edits.

## Keymaps

| Key | Action |
|---|---|
| `<leader>e` | toggle file tree |
| `<leader>ff` | find files |
| `<leader>fg` | live grep |
| `gd` / `gr` | definition / references |
| `<leader>ca` | LSP code action |
| `<leader>lf` | format |
| `[d` / `]d` | previous / next diagnostic |
| `<leader>dq` | diagnostic location list |
| `F7` / `F8` / `F6` | `make` / `make run` / `make test` |
| `F9` | single-file C/C++ compile |
| `F10` | quickfix window |

## CI

The primary CI path now validates the configuration that the README recommends:

```text
Neovim stable (must satisfy 0.11+)
        ↓
minimal profile smoke test
        ↓
cpp profile smoke test
        ↓
agent profile smoke test
        ↓
PowerShell installer parser check
```

Network plugin installation is disabled during profile smoke tests, while the plugin spec is still constructed so modular configuration errors fail CI deterministically.

## Roadmap

The project is moving from a traditional editor config toward an agent-native C/C++ engineering environment:

```text
modular config
    ↓
project task engine
    ↓
AGENTS.md / agent registry
    ↓
IDE ↔ agent context bridge
    ↓
diff/review workflow
    ↓
ACP / MCP + multi-agent worktrees
```

See [ROADMAP.md](ROADMAP.md).

## Contributing

Pull requests are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) and [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## License

[MIT](LICENSE)
