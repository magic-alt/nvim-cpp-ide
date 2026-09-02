# Roadmap

## v0.2 — Configuration foundation

- [x] Modular Lua architecture for Neovim 0.11+
- [x] `minimal` / `cpp` / `agent` profile framework
- [x] CI smoke tests for all Lua profiles on Neovim 0.11+
- [ ] Cold/hot startup benchmarks and demo GIF refresh

## v0.3 — Project task engine

- [x] Project-root discovery and task abstraction
- [x] CMake Presets / Ninja / Make detection
- [x] Unified configure / build / test / lint / format commands
- [x] Headless task execution contract with process exit-code propagation
- [x] Project-local `.nvim-cpp-ide.json` overrides
- [ ] Windows path, terminal and toolchain hardening

## v0.4 — Agent foundation

- [x] Code-backed `AGENTS.md` template and `:AgentInit[!]`
- [x] Project structure + Project Task Engine contract injection
- [x] Non-destructive `CLAUDE.md` → `@AGENTS.md` compatibility bridge
- [x] Provider-neutral argv-based agent registry
- [x] Codex / Claude Code / Gemini CLI project-root launch adapters
- [x] Registry extension/disable mechanism for custom agent CLIs
- [x] CI fixture for generation, overwrite safety, Claude bridge, and registry behavior

## v0.5 — IDE ↔ agent context + review bridge

- [x] Export loaded-buffer LSP diagnostics and Quickfix state
- [x] Export Git status plus staged/unstaged diff summaries without persisting full patches
- [x] Export current file/cursor and best-effort symbol focus
- [x] Retain last per-action configure/build/test/lint/format results in the Neovim session
- [x] Persist versioned `.nvim-agent/context.json` + human-readable `context.md`
- [x] Auto-refresh context before launching a registered external agent CLI
- [x] Keep `.nvim-agent/` disposable and locally ignored without mutating project-root `.gitignore`
- [x] Headless/CI/SSH/container/worktree deployment documentation and CI fixture
- [x] Safely auto-reload clean buffers after external edits
- [x] Detect unsaved-buffer vs external-disk conflicts without overwriting local edits
- [x] Recovery-backed `keep-buffer` / `use-disk` conflict resolution
- [x] Diff-first Git review with working tree = pending and index = human-accepted boundary
- [x] `AgentChanges` / pending diff / accepted diff workflow
- [x] File-level accept / keep / revert / unaccept operations
- [x] Gitsigns-backed next/previous + accept/keep/revert hunk workflow
- [x] Context snapshot integration for conflict and review state
- [x] Dedicated external-edit/review state-machine CI

## v0.6+

- [ ] Optional ACP / MCP integration
- [ ] Git worktree multi-agent orchestration
- [ ] Embedded presets for ARM GCC / PlatformIO / Zephyr
- [ ] Agent-native quickstart / FAQ / migration documentation
