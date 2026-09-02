local function assert_contains(value, needle, label)
  assert(type(value) == "string" and value:find(needle, 1, true), (label or "value") .. " missing: " .. needle)
end

local root = vim.fn.getcwd()
local relative = "src/main.c"
local file = vim.fs.joinpath(root, relative)
local original = vim.fn.readfile(file, "b")

local function write_file(lines)
  assert(vim.fn.writefile(lines, file, "b") == 0, "failed to write fixture file")
end

local function git(args, allow_failure)
  local argv = { "git", "-C", root }
  vim.list_extend(argv, args)
  local result = vim.system(argv, { text = true }):wait()
  if not allow_failure then
    assert(result.code == 0, result.stderr or result.stdout or "git command failed")
  end
  return result
end

local function find_file(snapshot)
  for _, item in ipairs(snapshot.files or {}) do
    if item.path == relative then
      return item
    end
  end
  return nil
end

local function cleanup()
  git({ "restore", "--source=HEAD", "--staged", "--worktree", "--", relative }, true)
  vim.fn.delete(vim.fs.joinpath(root, ".nvim-agent"), "rf")
end

local ok, err = xpcall(function()
  vim.cmd("edit " .. vim.fn.fnameescape(relative))
  local bufnr = vim.api.nvim_get_current_buf()
  local conflicts = require("nvim_cpp_ide.agent.conflicts")
  local review = require("nvim_cpp_ide.agent.review")

  assert(vim.fn.exists(":AgentChanges") == 2)
  assert(vim.fn.exists(":AgentDiff") == 2)
  assert(vim.fn.exists(":AgentAccept") == 2)
  assert(vim.fn.exists(":AgentRevert") == 2)
  assert(vim.fn.exists(":AgentConflicts") == 2)

  -- Clean buffers are safe to reload after an external edit.
  write_file({
    "int main(void) {",
    "  // external clean reload",
    "  return 11;",
    "}",
  })
  assert(conflicts.check(bufnr) == nil)
  assert(not vim.bo[bufnr].modified)
  assert_contains(table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n"), "return 11;", "clean reload buffer")

  -- Unsaved local edits must not be overwritten by a second external edit.
  vim.api.nvim_buf_set_lines(bufnr, 1, 3, false, {
    "  // local unsaved edit",
    "  return 77;",
  })
  assert(vim.bo[bufnr].modified)
  write_file({
    "int main(void) {",
    "  // external conflicting edit with different size",
    "  return 99;",
    "}",
  })
  local conflict = conflicts.check(bufnr)
  assert(conflict and conflict.reason == "changed-on-disk")
  assert(conflict.local_modified == true)
  assert_contains(table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n"), "return 77;", "conflicting local buffer")
  assert(conflicts.snapshot().count == 1)

  local disk_result, disk_err = conflicts.use_disk()
  assert(disk_result, disk_err)
  assert(disk_result.recovery and disk_result.recovery:find(".nvim-agent/recovery", 1, true))
  local recovery_path = vim.fs.joinpath(root, disk_result.recovery:gsub("^%./", ""))
  assert(vim.fn.filereadable(recovery_path) == 1, "conflict recovery backup missing")
  assert(not vim.bo[bufnr].modified)
  assert_contains(table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n"), "return 99;", "disk-selected buffer")
  assert(conflicts.snapshot().count == 0)

  -- Working tree is pending review; the Git index is the accepted boundary.
  write_file({
    "int main(void) {",
    "  // pending agent edit",
    "  return 33;",
    "}",
  })
  assert(conflicts.check(bufnr) == nil)
  local pending = review.snapshot(root)
  local pending_file = find_file(pending)
  assert(pending_file and pending_file.pending == true and pending_file.accepted == false)
  local pending_diff = assert(review.diff_text(relative, { staged = false }))
  assert_contains(pending_diff, "return 33;", "pending diff")

  local accepted, accept_err = review.accept(relative)
  assert(accepted, accept_err)
  local staged = review.snapshot(root)
  local staged_file = find_file(staged)
  assert(staged_file and staged_file.accepted == true and staged_file.pending == false)
  local accepted_diff = assert(review.diff_text(relative, { staged = true }))
  assert_contains(accepted_diff, "return 33;", "accepted diff")

  -- A later agent edit becomes pending on top of the already accepted index.
  write_file({
    "int main(void) {",
    "  // second pending agent edit",
    "  return 44;",
    "}",
  })
  assert(conflicts.check(bufnr) == nil)
  local mixed = review.snapshot(root)
  local mixed_file = find_file(mixed)
  assert(mixed_file and mixed_file.accepted == true and mixed_file.pending == true)

  local reverted, revert_err = review.revert(relative)
  assert(reverted, revert_err)
  assert(reverted.baseline == "index")
  assert(reverted.recovery and reverted.recovery:find(".nvim-agent/recovery", 1, true))
  assert_contains(table.concat(vim.fn.readfile(file, "b"), "\n"), "return 33;", "reverted working tree")
  local after_revert = find_file(review.snapshot(root))
  assert(after_revert and after_revert.accepted == true and after_revert.pending == false)

  -- Unaccept moves the staged file back to pending review without losing content.
  local unaccepted, unaccept_err = review.unaccept(relative)
  assert(unaccepted, unaccept_err)
  local after_unaccept = find_file(review.snapshot(root))
  assert(after_unaccept and after_unaccept.accepted == false and after_unaccept.pending == true)
  assert_contains(table.concat(vim.fn.readfile(file, "b"), "\n"), "return 33;", "unaccepted working tree")

  local context = require("nvim_cpp_ide.agent.context").write()
  assert(context.snapshot.external_changes.count == 0)
  assert(context.snapshot.review.available == true)
  assert(context.snapshot.review.pending_count >= 1)
  assert(context.snapshot.review.accepted_count == 0)
  assert_contains(require("nvim_cpp_ide.agent.context").markdown(context.snapshot), "## Diff-first review", "context markdown")
  assert_contains(require("nvim_cpp_ide.agent.context").markdown(context.snapshot), "## External file conflicts", "context markdown")

  local runtime_status = git({ "status", "--short", "--", ".nvim-agent" })
  assert(vim.trim(runtime_status.stdout or "") == "", ".nvim-agent recovery/context files polluted Git status")

  -- Generated AGENTS.md must preserve the human-review boundary contract.
  local rendered = require("nvim_cpp_ide.agent.template").render_project()
  assert_contains(rendered, "Git index as the human-accepted boundary", "AGENTS template")
  assert_contains(rendered, "Do not stage, unstage", "AGENTS template")
end, debug.traceback)

cleanup()
if not ok then
  error(err)
end

print("agent conflict/review workflow: ok")
