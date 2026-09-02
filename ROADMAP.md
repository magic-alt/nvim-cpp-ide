# Roadmap

## v0.2 — Configuration foundation

- [x] Modular Lua architecture for Neovim 0.11+
- [x] `minimal` / `cpp` / `agent` profile framework
- [x] CI smoke tests for all Lua profiles on Neovim 0.11+
- [ ] Cold/hot startup benchmarks and demo GIF refresh

## v0.3 — Project task engine

- [ ] Project-root discovery and task abstraction
- [ ] CMake Presets / Ninja / Make detection
- [ ] Unified build / test / lint / format commands
- [ ] Windows path, terminal and toolchain hardening

## v0.4 — Agent foundation

- [ ] `AGENTS.md` template and `:AgentInit`
- [ ] `CLAUDE.md` compatibility bridge
- [ ] Provider-neutral agent registry
- [ ] Codex / Claude Code / Gemini CLI terminal adapters

## v0.5 — IDE ↔ agent context bridge

- [ ] Export diagnostics, Git state, build logs and test results
- [ ] Agent-safe external-file reload and conflict UX
- [ ] Diff-first review workflow

## v0.6+

- [ ] Optional ACP / MCP integration
- [ ] Git worktree multi-agent orchestration
- [ ] Embedded presets for ARM GCC / PlatformIO / Zephyr
- [ ] Agent-native quickstart / FAQ / migration documentation
