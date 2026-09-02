local M = {}

local function md_cell(value)
  value = tostring(value or "")
  value = value:gsub("\n", " "):gsub("|", "\\|")
  return value
end

local function argv(value)
  if type(value) ~= "table" then
    return ""
  end
  return vim.json.encode(value)
end

local function task_status(result)
  if not result then
    return "not run"
  end
  if result.code == 0 then
    return "success"
  end
  return "failed (exit " .. tostring(result.code or "?") .. ")"
end

local function diagnostics_section(snapshot, lines)
  local diagnostics = snapshot.diagnostics or {}
  local counts = diagnostics.counts or {}
  table.insert(lines, "## Diagnostics")
  table.insert(lines, "")
  table.insert(lines, ("- Total: **%d**%s"):format(diagnostics.count or 0, diagnostics.truncated and " (truncated)" or ""))
  table.insert(lines, ("- ERROR: %d · WARN: %d · INFO: %d · HINT: %d"):format(
    counts.ERROR or 0,
    counts.WARN or 0,
    counts.INFO or 0,
    counts.HINT or 0
  ))
  table.insert(lines, "")

  if #(diagnostics.items or {}) == 0 then
    table.insert(lines, "No project-local diagnostics are currently loaded.")
    table.insert(lines, "")
    return
  end

  table.insert(lines, "| Severity | Location | Source | Message |")
  table.insert(lines, "|---|---|---|---|")
  for _, item in ipairs(diagnostics.items or {}) do
    local location = ("%s:%d:%d"):format(item.file or "?", item.line or 0, item.column or 0)
    table.insert(lines, ("| %s | `%s` | %s | %s |"):format(
      md_cell(item.severity),
      md_cell(location),
      md_cell(item.source),
      md_cell(item.message)
    ))
  end
  table.insert(lines, "")
end

local function git_section(snapshot, lines)
  local git = snapshot.git or {}
  table.insert(lines, "## Git")
  table.insert(lines, "")
  if not git.available then
    table.insert(lines, "Git metadata is unavailable for this project root.")
    table.insert(lines, "")
    return
  end

  table.insert(lines, ("- Branch: `%s`"):format(git.branch or "detached"))
  table.insert(lines, ("- HEAD: `%s`"):format(git.head or "unknown"))
  table.insert(lines, ("- Dirty: `%s`"):format(git.dirty and "yes" or "no"))
  if git.branch_status then
    table.insert(lines, ("- Status: `%s`"):format(md_cell(git.branch_status)))
  end
  table.insert(lines, ("- Unstaged diff: +%d / -%d across %d file(s)"):format(
    git.unstaged and git.unstaged.added or 0,
    git.unstaged and git.unstaged.deleted or 0,
    git.unstaged and git.unstaged.count or 0
  ))
  table.insert(lines, ("- Staged diff: +%d / -%d across %d file(s)"):format(
    git.staged and git.staged.added or 0,
    git.staged and git.staged.deleted or 0,
    git.staged and git.staged.count or 0
  ))
  table.insert(lines, "")

  if #(git.changed_files or {}) > 0 then
    table.insert(lines, "| Status | Path |")
    table.insert(lines, "|---|---|")
    for _, item in ipairs(git.changed_files or {}) do
      table.insert(lines, ("| `%s` | `%s` |"):format(md_cell(item.status), md_cell(item.path)))
    end
    table.insert(lines, "")
  end
end

local function external_changes_section(snapshot, lines)
  local state = snapshot.external_changes or {}
  table.insert(lines, "## External file conflicts")
  table.insert(lines, "")
  table.insert(lines, ("- Conflicts: **%d**"):format(state.count or 0))
  table.insert(lines, "")
  if #(state.items or {}) == 0 then
    table.insert(lines, "No loaded buffer currently conflicts with an external on-disk change.")
    table.insert(lines, "")
    return
  end

  table.insert(lines, "| File | Reason | Local modified | Detected |")
  table.insert(lines, "|---|---|---|---|")
  for _, item in ipairs(state.items or {}) do
    table.insert(lines, ("| `%s` | %s | %s | %s |"):format(
      md_cell(item.file),
      md_cell(item.reason),
      item.local_modified and "yes" or "no",
      md_cell(item.detected_at)
    ))
  end
  table.insert(lines, "")
end

local function review_section(snapshot, lines)
  local review = snapshot.review or {}
  table.insert(lines, "## Diff-first review")
  table.insert(lines, "")
  if review.available == false then
    table.insert(lines, "Review metadata is unavailable: " .. md_cell(review.reason))
    table.insert(lines, "")
    return
  end

  table.insert(lines, ("- Changed files: **%d**"):format(review.changed_count or 0))
  table.insert(lines, ("- Pending working-tree review: **%d**"):format(review.pending_count or 0))
  table.insert(lines, ("- Accepted/staged: **%d**"):format(review.accepted_count or 0))
  table.insert(lines, "")

  if #(review.files or {}) == 0 then
    table.insert(lines, "No Git changes are awaiting or carrying review state.")
    table.insert(lines, "")
    return
  end

  table.insert(lines, "| File | Git | Pending | Accepted |")
  table.insert(lines, "|---|---|---|---|")
  for _, item in ipairs(review.files or {}) do
    table.insert(lines, ("| `%s` | `%s` | %s | %s |"):format(
      md_cell(item.path),
      md_cell(item.status),
      item.pending and "yes" or "no",
      item.accepted and "yes" or "no"
    ))
  end
  table.insert(lines, "")
end

local function project_section(snapshot, lines)
  local project = snapshot.project or {}
  table.insert(lines, "## Project")
  table.insert(lines, "")
  table.insert(lines, ("- Root: `%s`"):format(project.root or "."))
  table.insert(lines, ("- Backend: `%s`"):format(project.backend or "unresolved"))
  if project.config_file then
    table.insert(lines, ("- Task config: `%s`"):format(project.config_file))
  end
  table.insert(lines, "")
  table.insert(lines, "### Resolved tasks")
  table.insert(lines, "")
  table.insert(lines, "| Action | Available | argv | cwd |")
  table.insert(lines, "|---|---|---|---|")
  for _, action in ipairs({ "configure", "build", "test", "lint", "format" }) do
    local task = project.tasks and project.tasks[action]
    if task and task.available then
      table.insert(lines, ("| %s | yes | `%s` | `%s` |"):format(
        action,
        md_cell(argv(task.argv)),
        md_cell(task.cwd or ".")
      ))
    else
      table.insert(lines, ("| %s | no | %s |  |"):format(action, md_cell(task and task.reason or "not resolved")))
    end
  end
  table.insert(lines, "")
end

local function task_results_section(snapshot, lines)
  local results = snapshot.task_results or {}
  local by_action = results.by_action or {}
  table.insert(lines, "## Last task results")
  table.insert(lines, "")
  table.insert(lines, "| Action | Result | Completed | argv |")
  table.insert(lines, "|---|---|---|---|")
  for _, action in ipairs({ "build", "test", "lint", "format", "configure" }) do
    local result = by_action[action]
    table.insert(lines, ("| %s | %s | %s | `%s` |"):format(
      action,
      task_status(result),
      md_cell(result and result.completed_at or ""),
      md_cell(result and argv(result.argv) or "")
    ))
  end
  table.insert(lines, "")
end

local function quickfix_section(snapshot, lines)
  local quickfix = snapshot.quickfix or {}
  table.insert(lines, "## Quickfix")
  table.insert(lines, "")
  table.insert(lines, ("- Title: `%s`"):format(md_cell(quickfix.title)))
  table.insert(lines, ("- Items: **%d**%s"):format(quickfix.count or 0, quickfix.truncated and " (truncated)" or ""))
  table.insert(lines, "")
  if #(quickfix.items or {}) == 0 then
    table.insert(lines, "Quickfix is empty.")
    table.insert(lines, "")
    return
  end

  table.insert(lines, "| Location | Type | Message |")
  table.insert(lines, "|---|---|---|")
  for _, item in ipairs(quickfix.items or {}) do
    local location = item.file or "?"
    if item.line then
      location = location .. ":" .. item.line
      if item.column then
        location = location .. ":" .. item.column
      end
    end
    table.insert(lines, ("| `%s` | %s | %s |"):format(md_cell(location), md_cell(item.type), md_cell(item.text)))
  end
  table.insert(lines, "")
end

function M.markdown(snapshot)
  local current = snapshot.current or {}
  local symbol = current.symbol and current.symbol.name or nil
  local lines = {
    "# Neovim Agent Context",
    "",
    ("Generated: `%s`"):format(snapshot.generated_at or "unknown"),
    "",
    "> Runtime snapshot only. File contents, full Git patches, environment variables, credentials, and machine-specific project-root paths are intentionally omitted.",
    "",
    "## Runtime focus",
    "",
    ("- Profile: `%s`"):format(snapshot.runtime and snapshot.runtime.profile or "unknown"),
    ("- Neovim: `%s`"):format(snapshot.runtime and snapshot.runtime.neovim or "unknown"),
    ("- Current file: `%s`"):format(current.file or "none"),
    ("- Filetype: `%s`"):format(current.filetype or ""),
    ("- Cursor: `%s:%s`"):format(current.cursor and current.cursor.line or "?", current.cursor and current.cursor.column or "?"),
    ("- Current symbol hint: `%s`%s"):format(
      symbol or "none",
      current.symbol and current.symbol.source and (" (" .. current.symbol.source .. ")") or ""
    ),
    ("- Buffer modified: `%s`"):format(current.modified and "yes" or "no"),
    "",
  }

  project_section(snapshot, lines)
  task_results_section(snapshot, lines)
  git_section(snapshot, lines)
  external_changes_section(snapshot, lines)
  review_section(snapshot, lines)
  diagnostics_section(snapshot, lines)
  quickfix_section(snapshot, lines)

  table.insert(lines, "## Agent usage")
  table.insert(lines, "")
  table.insert(lines, "Treat this snapshot as advisory runtime state. Use `:AgentChanges` / `:AgentDiff` before accepting or reverting agent edits, resolve external-file conflicts before destructive review actions, and regenerate with `:AgentContext` when state changes materially.")
  table.insert(lines, "")

  return table.concat(lines, "\n")
end

return M
