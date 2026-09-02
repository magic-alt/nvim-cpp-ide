# Agent-safe external changes and diff-first review

This document describes the human review layer built on top of the Agent Foundation, Project Task Engine, and IDE ↔ Agent Context Bridge.

The design keeps two independent kinds of state separate:

```text
buffer ↔ disk
    │
    └── external-file conflict safety

Git index ↔ working tree
    │
    └── diff-first code review
```

That distinction matters. An unsaved Neovim buffer must never be silently replaced just because an external coding agent wrote the same file, while a clean on-disk Agent edit should remain easy to inspect, accept, keep pending, or revert.

## Review model

The review workflow treats Git state as a lightweight approval protocol:

```text
HEAD
  │
  │ accepted/staged diff
  ▼
Git index
  │
  │ pending/unstaged diff
  ▼
working tree
```

- **working-tree changes** are pending review;
- **staged/index changes** are human-accepted;
- `AgentAccept` stages a reviewed file;
- `AgentUnaccept` moves it back to pending review;
- `AgentRevert` restores only the working tree to the current index;
- accepted staged content is therefore not destroyed by reverting a later pending Agent edit.

Generated `AGENTS.md` files tell coding agents not to stage/unstage their own changes unless the user explicitly requests it. This preserves the Git index as the human review boundary.

## External-file detection

The `agent` profile tracks an on-disk baseline for loaded normal file buffers.

Relevant events include:

```text
BufReadPost
BufWritePost
BufFilePost
FocusGained
BufEnter
CursorHold
```

When the file signature changes:

```text
external disk change
        ↓
Neovim buffer clean?
   ┌────┴─────┐
  yes         no
   │           │
checktime      conflict state
safe reload    no silent overwrite
```

Deletion on disk is treated conservatively as a conflict rather than silently discarding the in-memory buffer.

### Conflict commands

```vim
:AgentConflicts
:AgentConflictDiff [path]
:AgentConflictKeep [path]
:AgentConflictUseDisk [path]
```

`AgentConflicts` lists active conflicts. In an attached Neovim UI it populates Quickfix; in headless mode it prints JSON.

`AgentConflictDiff` opens a side-by-side scratch comparison:

```text
local unsaved buffer | current disk version
```

Neither side is writable from the review tab.

`AgentConflictKeep` means:

```text
keep local unsaved buffer
        +
acknowledge current disk version
```

The buffer remains modified. A later normal `:write` is still an explicit user action and may replace the disk version.

`AgentConflictUseDisk` means:

```text
unsaved local buffer
        ↓
backup to .nvim-agent/recovery/
        ↓
reload current disk version
```

This is intentionally recovery-backed so selecting the disk version does not destroy the discarded local buffer state.

## Diff-first review commands

```vim
:AgentChanges
:AgentDiff [path]
:AgentDiffStaged [path]
:AgentAccept [path]
:AgentKeep [path]
:AgentRevert [path]
:AgentUnaccept [path]
```

### AgentChanges

`AgentChanges` summarizes Git porcelain state and labels files as:

```text
pending
accepted
accepted+pending
```

A file can be `accepted+pending` when a reviewed version is already staged and the Agent subsequently modifies the working tree again.

### AgentDiff

`AgentDiff` shows the pending review surface:

```text
working tree
    vs
Git index
```

This is the important default comparison because the index is the accepted baseline.

`AgentDiffStaged` shows:

```text
Git index
    vs
HEAD
```

so the developer can review everything currently accepted before committing.

Untracked text files are represented as new-file patches even though ordinary `git diff` does not include them.

In headless mode the same commands print patch text instead of opening a scratch diff buffer.

### AgentAccept

```vim
:AgentAccept src/foo.cpp
```

is equivalent to accepting the current file-level working-tree state into the review boundary:

```text
git add -- src/foo.cpp
```

It does not commit.

### AgentKeep

```vim
:AgentKeep src/foo.cpp
```

is intentionally non-mutating. The file remains pending/unstaged for later review.

### AgentRevert

```vim
:AgentRevert src/foo.cpp
```

first creates a recovery backup when on-disk content exists, then restores the working tree to the current Git index:

```text
pending working-tree version
        ↓ backup
.nvim-agent/recovery/
        ↓
git restore --worktree
        ↓
accepted index version
```

The command refuses to run if the matching loaded buffer has unsaved edits. Resolve/save the buffer first so Git operations never silently destroy editor state.

For an untracked file, revert backs up the file and removes it. Untracked directories are deliberately refused because recursive deletion is too destructive for an editor review primitive.

### AgentUnaccept

`AgentUnaccept` performs the inverse review-state transition:

```text
accepted/staged
      ↓
git restore --staged
      ↓
pending/unstaged
```

The working-tree content is retained.

## Hunk workflow

When `gitsigns.nvim` is loaded, the agent profile exposes:

```vim
:AgentNextHunk
:AgentPrevHunk
:AgentAcceptHunk
:AgentKeepHunk
:AgentRevertHunk
```

The default mappings are:

```text
]a            next agent-change hunk
[a            previous agent-change hunk
<leader>aa    accept/stage current hunk
<leader>ak    keep current hunk pending and move on
<leader>ar    revert current pending hunk
```

Inside the read-only `AgentDiff` scratch buffer, next/previous hunk navigation searches unified-diff `@@` headers directly, so patch navigation does not require Gitsigns. Staging/resetting a hunk does require Gitsigns because it operates on the real source buffer.

File-level commands remain available without any plugin and are the supported headless/CI contract.

## Recovery directory

Potentially destructive review decisions use:

```text
.nvim-agent/
├── .gitignore
├── context.json
├── context.md
└── recovery/
    └── <timestamp>-<operation>/...
```

The local `.nvim-agent/.gitignore` contains:

```gitignore
*
```

so context snapshots and recovery files stay out of normal repository status without modifying the project root `.gitignore`.

Recovery files are local safety artifacts, not a version-control mechanism. Git remains the authoritative review history.

## Context Bridge integration

The existing schema v1 stays backward-compatible and gains additive sections:

```json
{
  "external_changes": {
    "count": 0,
    "items": []
  },
  "review": {
    "available": true,
    "changed_count": 2,
    "pending_count": 1,
    "accepted_count": 1,
    "files": []
  }
}
```

`context.md` mirrors the same state under:

```text
## External file conflicts
## Diff-first review
```

Accept/revert/unaccept operations refresh the context snapshot on a best-effort basis. Project build/test commands can then be run and `:AgentContext` regenerated to expose post-review validation state.

## Recommended interactive loop

```text
:Agent codex
      ↓
Agent edits repository
      ↓
Focus returns to Neovim
      ↓
clean buffers auto-reload
modified conflicts are flagged
      ↓
:AgentConflicts
      ↓
resolve buffer/disk conflicts
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
review accepted staged diff
      ↓
:AgentDiffStaged
```

## Headless / SSH / container usage

The file-level review API is provider-neutral and requires no daemon or database.

Examples:

```bash
NVIM_CPP_IDE_PROFILE=agent \
  nvim --headless -u ~/.config/nvim/init.lua \
  '+AgentChanges' +qa
```

```bash
NVIM_CPP_IDE_PROFILE=agent \
  nvim --headless -u ~/.config/nvim/init.lua \
  '+AgentDiff src/foo.cpp' +qa
```

Mutating commands can also be called headlessly:

```bash
nvim --headless '+AgentAccept src/foo.cpp' +qa
nvim --headless '+AgentRevert src/foo.cpp' +qa
```

Use these only in workflows where the Git-index approval semantics are intentional.

## CI coverage

`Agent Review CI` exercises the state machine with a real tracked fixture:

```text
clean external edit
    ↓
safe reload
    ↓
unsaved local edit + external edit
    ↓
conflict retained
    ↓
UseDisk recovery backup
    ↓
pending Agent edit
    ↓
accept/stage
    ↓
second pending edit
    ↓
revert to accepted index
    ↓
unaccept back to pending
    ↓
context snapshot verification
```

The test also verifies that `.nvim-agent/` recovery/context artifacts do not pollute Git status.

## Scope boundary

This stage does not add:

- automatic committing;
- Agent-controlled staging by default;
- recursive deletion of untracked directories;
- daemonized filesystem watchers;
- ACP/MCP transport;
- multi-agent worktree scheduling.

Those remain separate layers so the review boundary stays understandable and auditable.
