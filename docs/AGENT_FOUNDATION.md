# Agent Foundation

The `agent` profile keeps Neovim as a control/review surface while external coding-agent CLIs remain the agent runtime.

The foundation has four responsibilities:

1. make the repository agent-readable through a shared `AGENTS.md` contract;
2. reuse the Project Task Engine instead of making agents guess build/test commands;
3. bridge Claude Code to the shared contract without duplicating instructions;
4. provide a small provider-neutral registry for launching external agent CLIs at the project root.

## Enable the profile

```bash
NVIM_CPP_IDE_PROFILE=agent nvim
```

PowerShell:

```powershell
$env:NVIM_CPP_IDE_PROFILE = 'agent'
nvim
```

## Generate the repository contract

Run:

```vim
:AgentInit
```

The command discovers the current project root and creates `AGENTS.md` from actual repository state when the file does not already exist. The generated contract includes:

- project name and repository-relative root notation;
- detected build backend;
- visible top-level repository directories;
- important project markers such as `README.md`, `CMakeLists.txt`, `CMakePresets.json`, `Makefile`, and `.nvim-cpp-ide.json`;
- resolved `configure`, `build`, `test`, `lint`, and `format` tasks from the Project Task Engine;
- the equivalent headless `ProjectTask` vocabulary;
- generic repository-safe working rules for agents.

Resolved native commands are written as argv JSON arrays rather than shell-quoted strings. This keeps the generated contract machine-readable and avoids encoding Unix/Windows quoting assumptions into the repository.

The generator deliberately does not infer domain-specific rules from source code. For example, it will not invent claims such as "no heap allocation" or "ISR functions must not block" unless the repository owner adds those rules manually.

### Regeneration safety

`AgentInit` is intentionally idempotent and non-destructive:

- if `AGENTS.md` does not exist, it is generated;
- if `AGENTS.md` already exists, its contents are preserved;
- the Claude bridge is still checked/created even when an existing `AGENTS.md` is preserved.

Use the explicit bang form only when regeneration is intended:

```vim
:AgentInit!
```

`AgentInit!` replaces the existing `AGENTS.md` with a fresh generated baseline. This makes hand-maintained repository rules hard to destroy accidentally while still providing a deterministic refresh path.

Generated `AGENTS.md` deliberately excludes machine-specific absolute workspace paths and the current Git branch so the file can be committed and reused across clones, worktrees, CI, and agent runtimes.

## Claude bridge

`AgentInit` also ensures that the project root contains a Claude compatibility bridge:

```markdown
@AGENTS.md
```

If `CLAUDE.md` does not exist, it is created with the bridge. If it already exists, its existing content is preserved and `@AGENTS.md` is appended only when that exact bridge line is missing.

The shared repository policy therefore stays in one place:

```text
AGENTS.md
   ├── Codex / compatible agent readers
   └── CLAUDE.md -> @AGENTS.md
```

Provider-specific authentication, model settings, permissions, and runtime configuration stay in the provider CLI rather than in `AGENTS.md`.

## Agent registry

The default registry contains:

```text
codex  -> codex
claude -> claude
gemini -> gemini
```

Inspect availability:

```vim
:AgentList
```

Launch a registered agent at the detected project root:

```vim
:Agent codex
:Agent claude
:Agent gemini
```

Additional CLI arguments are passed as argv entries rather than concatenated into an opaque shell string:

```vim
:Agent codex --help
```

The registry checks whether the first argv entry is executable. Missing CLIs are reported but never installed automatically.

## Custom agents

Extend or override the registry from the Neovim configuration:

```lua
vim.g.nvim_cpp_ide_agents = {
  opencode = { "opencode" },
  local_agent = {
    label = "Local Agent",
    argv = { "my-agent", "--project-mode" },
  },
}
```

Disable a default entry:

```lua
vim.g.nvim_cpp_ide_agents = {
  gemini = false,
}
```

This keeps the core provider-neutral while allowing other runtimes to use the same project-root terminal lifecycle.

## Commands

```vim
:AgentProfileInfo
:AgentInit
:AgentInit!
:AgentList
:Agent <name> [args...]
:AgentTerminal [command...]
```

`AgentProfileInfo` reports the active profile, Project Task Engine contract, and registry availability.

`AgentTerminal` remains a generic escape hatch for opening a project-root terminal without selecting a registered coding agent.

## Project Task Engine integration

The generated `AGENTS.md` embeds the tasks already resolved by the project layer. An agent therefore sees the same execution contract as the human using Neovim:

```text
configure
build
test
lint
format
```

The canonical headless interface remains:

```bash
nvim --headless '+ProjectTask build' +qa
```

Headless failures propagate a non-zero exit status, allowing Codex, Claude Code, Gemini CLI, CI, or another orchestrator to treat validation failures as actual failures.

## External file changes

The existing agent profile file watcher is retained. On focus/buffer events Neovim calls `:checktime` only for ordinary buffers that have no unsaved local modification. This lets external agents update files without silently overwriting local edits.

## Scope boundary

This stage intentionally does not implement:

- API clients for OpenAI, Anthropic, or Google;
- automatic login/API-key management;
- ACP/MCP transports;
- semantic context export;
- automated diff acceptance;
- multi-agent worktree scheduling.

Those layers can now build on a stable repository contract, task contract, and agent registry rather than duplicating project discovery.
