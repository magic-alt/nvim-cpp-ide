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

## v0.5 — IDE ↔ agent context bridge

- [ ] Export diagnostics, Git state, build logs and test results
- [ ] Persist a machine-readable current-context snapshot for external agents
- [ ] Agent-safe external-file reload and conflict UX
- [ ] Diff-first review workflow

## v0.6+

- [ ] Optional ACP / MCP integration
- [ ] Git worktree multi-agent orchestration
- [ ] Embedded presets for ARM GCC / PlatformIO / Zephyr
- [ ] Agent-native quickstart / FAQ / migration documentation
