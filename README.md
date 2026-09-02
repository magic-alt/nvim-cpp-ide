# 🚀 Neovim/Vim C/C++ IDE Config — 3-minute setup

[![Vim](https://img.shields.io/badge/Vim-8.0%2B-green.svg)](https://www.vim.org/)
[![Neovim](https://img.shields.io/badge/Neovim-0.11%2B-57A143.svg)](https://neovim.io)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![CI](https://img.shields.io/github/actions/workflow/status/magic-alt/nvim-cpp-ide/ci.yml?branch=main)](.github/workflows/ci.yml)

> **CN**：3 分钟把 Neovim/Vim 变成 C/C++ 友好的 IDE，并把仓库、构建任务、Neovim 运行时状态与外部 Coding Agent 连接成可验证、可审查的 AI-native 工作流。  
> **EN**: Turn Neovim/Vim into a C/C++ IDE in 3 minutes, with repository contracts, deterministic project tasks, runtime context snapshots, and diff-first human review for external coding agents.

## Lua edition: Neovim 0.11+

The recommended configuration uses a modular layout:

```text
init.lua
└── lua/nvim_cpp_ide/
    ├── core/       # editor options and keymaps
    ├── plugins/    # lazy.nvim specs
    ├── project/    # root detection + task engine + build backends
    ├── agent/      # AGENTS.md + CLI registry + context + conflict/review UX
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
| `cpp` | default C/C++ IDE | `minimal` + clangd/LSP, completion, formatting, project task engine |
| `agent` | agent-native terminal IDE | `cpp` + repository contracts, runtime context, safe external-file conflict handling, diff-first review, and CLI agent registry |

Linux/macOS example:

```bash
NVIM_CPP_IDE_PROFILE=agent nvim
```

PowerShell example:

```powershell
$env:NVIM_CPP_IDE_PROFILE = 'agent'
nvim
```

The `agent` profile keeps provider SDKs, authentication, model settings, and API keys outside Neovim. Codex, Claude Code, Gemini CLI, and custom agents remain external runtimes launched through a small argv-based registry.

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

The installer backs up the previous config, installs both `init.lua` and the complete modular `lua/` tree, then runs the first lazy.nvim synchronization. Agent Foundation, Context Bridge, conflict detection, and review modules therefore require no separate deployment step.

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
- unified CMake / Ninja / Make project tasks
- AsyncRun single-file compatibility path
- Mason package UI

Recommended external tools:

```text
clangd
clang-format
cmake
ninja or make
lua-language-server
stylua
```

Inside Neovim you can install language tools through Mason, for example:

```vim
:MasonInstall clangd lua-language-server clang-format stylua
```

## Project Task Engine

The task engine gives humans, CI, and coding agents the same project-level interface:

```vim
:ProjectInfo
:ProjectTask configure
:ProjectTask build
:ProjectTask test
:ProjectTask lint
:ProjectTask format
```

Convenience commands are also available:

```vim
:ProjectConfigure
:ProjectBuild
:ProjectTest
:ProjectLint
:ProjectFormat
```

Detection order is explicit project config → CMake → standalone Ninja → Make. CMake uses `CMakePresets.json` / `CMakeUserPresets.json` when available and otherwise falls back to `cmake -S <root> -B <build-dir>`.

The same command contract is usable from a coding agent or CI through headless Neovim:

```bash
cd /path/to/project
NVIM_CPP_IDE_PROFILE=cpp nvim --headless '+ProjectTask build' +qa
```

A failed headless task returns a non-zero process status. Interactive runs are asynchronous and publish their collected output to Quickfix.

Repository-specific conventions can be declared in `.nvim-cpp-ide.json`, including backend selection, CMake preset selection and exact argv-array task overrides. See [Project Task Engine](docs/PROJECT_TASK_ENGINE.md) for the full contract.

## Agent Foundation

Enable the `agent` profile, open a project, then create a shared repository contract:

```vim
:AgentInit
```

`AgentInit` discovers the actual project structure and Project Task Engine state, then creates `AGENTS.md` containing project structure, build/test commands, runtime-context guidance, and a human-review contract.

An existing `AGENTS.md` is not overwritten. Explicit regeneration requires:

```vim
:AgentInit!
```

The command also creates or updates a non-destructive Claude bridge. Existing `CLAUDE.md` content is preserved and the following line is added only when missing:

```markdown
@AGENTS.md
```

The generated contract explicitly tells coding agents not to stage/unstage their own changes unless requested. The Git index is reserved as the human-accepted review boundary.

### Agent registry

The built-in registry contains:

```text
codex  -> codex
claude -> claude
gemini -> gemini
```

Inspect it:

```vim
:AgentList
:AgentProfileInfo
```

Launch an installed CLI at the detected project root:

```vim
:Agent codex
:Agent claude
:Agent gemini
```

Before a registered CLI is launched, Neovim refreshes the IDE ↔ Agent runtime context snapshot described below.

Additional CLI arguments remain argv entries:

```vim
:Agent codex --help
```

Missing agent executables are reported but never installed automatically. The registry is extensible:

```lua
vim.g.nvim_cpp_ide_agents = {
  opencode = { "opencode" },
  local_agent = {
    label = "Local Agent",
    argv = { "my-agent", "--project-mode" },
  },
  gemini = false,
}
```

`AgentTerminal [command...]` remains the generic project-root terminal escape hatch.

See [Agent Foundation](docs/AGENT_FOUNDATION.md) for generation safety, registry customization, and scope boundaries.

## IDE ↔ Agent Context Bridge

The Context Bridge turns runtime state already known by Neovim into a bounded project-local snapshot:

```text
Neovim Runtime State
        ↓
loaded-buffer diagnostics
Git status / staged+unstaged diff summaries
current file / cursor / symbol hint
Project Task Engine contract
last configure/build/test/lint/format results
Quickfix
external-file conflicts
pending/accepted review state
        ↓
.nvim-agent/context.json
.nvim-agent/context.md
        ↓
Codex / Claude Code / Gemini / scripts
```

Refresh it manually:

```vim
:AgentContext
```

Refresh and open the human-readable view:

```vim
:AgentContextOpen
```

Print the current versioned JSON snapshot without writing files:

```vim
:AgentContextPrint
```

The default output directory is disposable runtime state:

```text
.nvim-agent/
├── .gitignore
├── context.json
├── context.md
└── recovery/
```

`.nvim-agent/.gitignore` contains `*`, so context/recovery files do not modify the project-root `.gitignore` or pollute `git status`.

The persisted snapshot intentionally omits source-file contents, complete Git patches, environment variables, provider credentials, terminal history, and the machine-specific project-root path. Agents use it to decide what to inspect next, then read the actual repository and diff themselves.

### Headless / CI deployment

No extra daemon or provider SDK is required:

```bash
cd /path/to/project
NVIM_CPP_IDE_PROFILE=agent \
  nvim --headless -u ~/.config/nvim/init.lua \
  '+AgentContext' +qa
```

To export a focused file plus build/test results in one process:

```bash
NVIM_CPP_IDE_PROFILE=agent \
  nvim --headless -u ~/.config/nvim/init.lua \
  '+edit src/main.cpp' \
  '+ProjectTask build' \
  '+ProjectTask test' \
  '+AgentContext' +qa
```

This filesystem-only design works the same way over SSH, inside containers, and inside independent Git worktrees. Diagnostics reflect currently loaded buffers, and task-result history is session-local rather than a cross-process database.

See [IDE ↔ Agent Context Bridge](docs/AGENT_CONTEXT_BRIDGE.md) for the schema, privacy boundary, deployment recipes, and limitations.

## Agent-safe conflicts + diff-first review

External coding agents can write a file while it is open in Neovim. The agent profile now distinguishes clean buffers from unsaved local edits:

```text
External Agent edits file
        ↓
buffer clean?
   ┌────┴─────┐
  yes         no
   │           │
safe reload   conflict state
               ↓
       explicit buffer/disk choice
```

Clean buffers use `checktime`/`autoread`. Unsaved buffers are never silently overwritten.

Conflict commands:

```vim
:AgentConflicts
:AgentConflictDiff [path]
:AgentConflictKeep [path]
:AgentConflictUseDisk [path]
```

`AgentConflictUseDisk` backs up the unsaved buffer under `.nvim-agent/recovery/` before loading the external disk version.

The Git review model is:

```text
HEAD
  │ accepted/staged
  ▼
Git index
  │ pending/unstaged
  ▼
working tree
```

Review commands:

```vim
:AgentChanges
:AgentDiff [path]
:AgentDiffStaged [path]
:AgentAccept [path]
:AgentKeep [path]
:AgentRevert [path]
:AgentUnaccept [path]
```

`AgentAccept` stages a reviewed file but does not commit. `AgentKeep` leaves it pending. `AgentRevert` first creates a recovery backup and restores only the working tree to the current index, preserving earlier accepted/staged content. `AgentUnaccept` moves an accepted file back to pending without losing working-tree content.

With Gitsigns loaded, hunk-level commands are available:

```vim
:AgentNextHunk
:AgentPrevHunk
:AgentAcceptHunk
:AgentKeepHunk
:AgentRevertHunk
```

File-level commands remain plugin-free and headless-safe, which keeps the workflow deployable over SSH/CI/containers.

A typical loop is:

```text
:Agent codex
    ↓
Agent edits
    ↓
:AgentConflicts
    ↓
:AgentChanges
    ↓
:AgentDiff
    ↓
accept / keep / revert
    ↓
:ProjectBuild
:ProjectTest
    ↓
:AgentContext
    ↓
:AgentDiffStaged
```

See [Agent-safe external changes and diff-first review](docs/AGENT_REVIEW_WORKFLOW.md) for recovery semantics, headless usage, and the complete state machine.

## Keymaps

| Key | Action |
|---|---|
| `<leader>e` | toggle file tree |
| `<leader>ff` | find files |
| `<leader>fg` | live grep |
| `gd` / `gr` | definition / references |
| `<leader>ca` | LSP code action |
| `<leader>lf` | format current buffer |
| `[d` / `]d` | previous / next diagnostic |
| `<leader>dq` | diagnostic location list |
| `F6` | project test |
| `F7` | project build |
| `F8` | project configure |
| `<leader>pi` | project info |
| `<leader>pc/pb/pt/pl/pf` | configure/build/test/lint/format |
| `<leader>ac` | list Agent changes |
| `<leader>ad` | pending Agent diff |
| `<leader>aD` | accepted/staged Agent diff |
| `<leader>ax` | external-file conflicts |
| `[a` / `]a` | previous / next Agent hunk |
| `<leader>aa` | accept current Agent hunk |
| `<leader>ak` | keep current hunk pending |
| `<leader>ar` | revert current pending hunk |
| `F9` | single-file C/C++ compile |
| `F4` | run single-file binary |
| `F10` | quickfix window |

## CI

The primary CI validates configuration loading, project execution, repository-agent contracts, and runtime context export. A dedicated `Agent Review CI` additionally exercises the real conflict/review state machine:

```text
clean external edit → safe reload
        ↓
unsaved buffer + external edit → conflict
        ↓
UseDisk → recovery backup
        ↓
pending working-tree Agent edit
        ↓
accept/stage
        ↓
second pending edit
        ↓
revert to accepted index
        ↓
unaccept back to pending
        ↓
context + Git hygiene verification
```

Network plugin installation is disabled during headless tests so file-level project/agent behavior remains deterministic.

## Roadmap

The project is moving from a traditional editor config toward an agent-native C/C++ engineering environment:

```text
modular config
    ↓
project task engine
    ↓
AGENTS.md + agent registry
    ↓
IDE ↔ agent context bridge
    ↓
external-file conflict UX + diff-first review
    ↓
ACP / MCP + multi-agent worktrees
```

See [ROADMAP.md](ROADMAP.md).

## Contributing

Pull requests are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) and [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## License

[MIT](LICENSE)
