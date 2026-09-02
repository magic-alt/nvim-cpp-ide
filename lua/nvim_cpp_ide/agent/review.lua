local recovery = require("nvim_cpp_ide.agent.recovery")

local M = {}

local MAX_DIFF_LINES = 5000

local function is_headless()
  return #vim.api.nvim_list_uis() == 0
end

local function project_root()
  return require("nvim_cpp_ide.project.root").get(0)
end

local function normalize(value)
  return vim.fs.normalize(value):gsub("\\", "/")
end

local function under_root(root, value)
  local root_norm = normalize(root)
  local value_norm = normalize(value)
  local root_cmp = root_norm
  local value_cmp = value_norm
  if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    root_cmp = root_cmp:lower()
    value_cmp = value_cmp:lower()
  end
  return value_cmp == root_cmp or vim.startswith(value_cmp, root_cmp .. "/")
end

local function run_git(root, args)
  if vim.fn.executable("git") ~= 1 then
    return nil, "git executable was not found in PATH"
  end
  local argv = { "git", "-C", root }
  vim.list_extend(argv, args)
  local result = vim.system(argv, { text = true }):wait()
  if result.code ~= 0 then
    local message = vim.trim(result.stderr or result.stdout or "git command failed")
    return nil, message ~= "" and message or ("git exited with code %d"):format(result.code)
  end
  return result
end

local function ensure_repo(root)
  local result, err = run_git(root, { "rev-parse", "--is-inside-work-tree" })
  if not result then
    return nil, err
  end
  if vim.trim(result.stdout or "") ~= "true" then
    return nil, "Project root is not inside a Git work tree"
  end
  return true
end

local function parse_status(output)
  local parts = vim.split(output or "", "\0", { plain = true, trimempty = true })
  local records = {}
  local i = 1
  while i <= #parts do
    local entry = parts[i]
    if #entry >= 3 then
      local xy = entry:sub(1, 2)
      local path = entry:sub(4)
      local index = xy:sub(1, 1)
      local worktree = xy:sub(2, 2)
      local record = {
        status = xy,
        index = index,
        worktree = worktree,
        path = path,
        untracked = xy == "??",
        ignored = xy == "!!",
      }
      if index == "R" or index == "C" or worktree == "R" or worktree == "C" then
        record.original_path = parts[i + 1]
        i = i + 1
      end
      record.accepted = not record.untracked and index ~= " " and index ~= "?"
      record.pending = record.untracked or worktree ~= " "
      if not vim.startswith(record.path, ".nvim-agent/") and record.path ~= ".nvim-agent" then
        table.insert(records, record)
      end
    end
    i = i + 1
  end
  table.sort(records, function(a, b)
    return a.path < b.path
  end)
  return records
end

local function changes(root)
  local ok, err = ensure_repo(root)
  if not ok then
    return nil, err
  end
  local result, status_err = run_git(root, {
    "status",
    "--porcelain=v1",
    "-z",
    "--untracked-files=normal",
    "--",
    ".",
  })
  if not result then
    return nil, status_err
  end
  return parse_status(result.stdout)
end

local function resolve_path(root, target)
  local value = target
  if not value or value == "" then
    local current = vim.api.nvim_buf_get_name(0)
    if current == "" then
      return nil, "No path supplied and the current buffer has no file"
    end
    value = current
  end

  local absolute
  if require("nvim_cpp_ide.project.path").is_absolute(value) then
    absolute = vim.fs.normalize(value)
  else
    absolute = vim.fs.normalize(vim.fs.joinpath(root, value:gsub("^%./", "")))
  end
  if not under_root(root, absolute) then
    return nil, "Review path must stay inside the detected project root"
  end

  local root_norm = normalize(root)
  local abs_norm = normalize(absolute)
  local relative = abs_norm == root_norm and "." or abs_norm:sub(#root_norm + 2)
  if relative == "." or relative == "" then
    return nil, "Review action requires a file path"
  end
  if relative == ".nvim-agent" or vim.startswith(relative, ".nvim-agent/") then
    return nil, "Runtime .nvim-agent files are excluded from code review actions"
  end
  return relative, absolute
end

local function find_record(records, relative)
  for _, record in ipairs(records or {}) do
    if record.path == relative then
      return record
    end
  end
  return nil
end

local function matching_buffer(absolute)
  local wanted = normalize(absolute)
  if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    wanted = wanted:lower()
  end
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      local name = vim.api.nvim_buf_get_name(bufnr)
      if name ~= "" then
        local candidate = normalize(name)
        if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
          candidate = candidate:lower()
        end
        if candidate == wanted then
          return bufnr
        end
      end
    end
  end
  return nil
end

local function refresh_buffer(absolute)
  local bufnr = matching_buffer(absolute)
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) and not vim.bo[bufnr].modified then
    vim.api.nvim_buf_call(bufnr, function()
      vim.cmd("silent! checktime")
    end)
  end
end

local function refresh_context()
  pcall(function()
    require("nvim_cpp_ide.agent.context").write()
  end)
  pcall(function()
    local gs = require("gitsigns")
    if gs.refresh then
      gs.refresh()
    end
  end)
end

function M.snapshot(root)
  root = root or project_root()
  local records, err = changes(root)
  if not records then
    return {
      available = false,
      reason = err,
      changed_count = 0,
      pending_count = 0,
      accepted_count = 0,
      files = {},
    }
  end

  local pending = 0
  local accepted = 0
  for _, record in ipairs(records) do
    if record.pending then
      pending = pending + 1
    end
    if record.accepted then
      accepted = accepted + 1
    end
  end
  return {
    available = true,
    changed_count = #records,
    pending_count = pending,
    accepted_count = accepted,
    files = records,
  }
end

function M.accept(target)
  local root = project_root()
  local relative, absolute_or_err = resolve_path(root, target)
  if not relative then
    return nil, absolute_or_err
  end
  local records, err = changes(root)
  if not records then
    return nil, err
  end
  local record = find_record(records, relative)
  if not record then
    return nil, ("No Git change found for %s"):format(relative)
  end

  local result, add_err = run_git(root, { "add", "--", relative })
  if not result then
    return nil, add_err
  end
  refresh_context()
  return { action = "accept", file = relative, staged = true }
end

function M.keep(target)
  local root = project_root()
  local relative, err = resolve_path(root, target)
  if not relative then
    return nil, err
  end
  local records, changes_err = changes(root)
  if not records then
    return nil, changes_err
  end
  local record = find_record(records, relative)
  if not record then
    return nil, ("No Git change found for %s"):format(relative)
  end
  refresh_context()
  return {
    action = "keep",
    file = relative,
    pending = record.pending,
    accepted = record.accepted,
  }
end

function M.revert(target)
  local root = project_root()
  local relative, absolute_or_err = resolve_path(root, target)
  if not relative then
    return nil, absolute_or_err
  end
  local absolute = absolute_or_err
  local bufnr = matching_buffer(absolute)
  if bufnr and vim.bo[bufnr].modified then
    return nil, ("Refusing to revert %s while its buffer has unsaved edits; resolve/save the buffer first"):format(relative)
  end

  local records, err = changes(root)
  if not records then
    return nil, err
  end
  local record = find_record(records, relative)
  if not record then
    return nil, ("No Git change found for %s"):format(relative)
  end

  local backup, backup_err = recovery.backup_file(root, relative, "review-revert")
  if backup_err then
    return nil, backup_err
  end

  if record.untracked then
    if vim.fn.isdirectory(absolute) == 1 then
      return nil, ("Refusing to recursively delete untracked directory %s; remove it manually after review"):format(relative)
    end
    if vim.fn.delete(absolute) ~= 0 then
      return nil, ("Failed to remove untracked file %s"):format(relative)
    end
  else
    local result, restore_err = run_git(root, { "restore", "--worktree", "--", relative })
    if not result then
      return nil, restore_err
    end
  end

  refresh_buffer(absolute)
  refresh_context()
  return {
    action = "revert",
    file = relative,
    recovery = backup and recovery.relative(root, backup) or nil,
    baseline = "index",
  }
end

function M.unaccept(target)
  local root = project_root()
  local relative, err = resolve_path(root, target)
  if not relative then
    return nil, err
  end
  local result, restore_err = run_git(root, { "restore", "--staged", "--", relative })
  if not result then
    return nil, restore_err
  end
  refresh_context()
  return { action = "unaccept", file = relative, staged = false }
end

local function pseudo_untracked_diff(relative, absolute)
  if vim.fn.filereadable(absolute) ~= 1 then
    return ""
  end
  local source = vim.fn.readfile(absolute, "b")
  local lines = {
    "diff --git a/" .. relative .. " b/" .. relative,
    "new file mode 100644",
    "--- /dev/null",
    "+++ b/" .. relative,
    ("@@ -0,0 +1,%d @@"):format(#source),
  }
  for i, line in ipairs(source) do
    if #lines >= MAX_DIFF_LINES then
      table.insert(lines, "+... diff truncated by nvim-cpp-ide ...")
      break
    end
    lines[#lines + 1] = "+" .. line
  end
  return table.concat(lines, "\n") .. "\n"
end

function M.diff_text(target, opts)
  opts = opts or {}
  local root = project_root()
  local relative
  local absolute
  if target and target ~= "" then
    local resolved, resolved_or_err = resolve_path(root, target)
    if not resolved then
      return nil, resolved_or_err
    end
    relative = resolved
    absolute = resolved_or_err
  end

  local args = { "diff", "--no-ext-diff", "--no-color", "--relative", "--unified=3" }
  if opts.staged then
    table.insert(args, "--cached")
  end
  table.insert(args, "--")
  if relative then
    table.insert(args, relative)
  else
    table.insert(args, ".")
  end

  local result, err = run_git(root, args)
  if not result then
    return nil, err
  end
  local text = result.stdout or ""

  if not opts.staged then
    local records = changes(root) or {}
    if relative then
      local record = find_record(records, relative)
      if record and record.untracked and text == "" then
        text = pseudo_untracked_diff(relative, absolute)
      end
    else
      for _, record in ipairs(records) do
        if record.untracked then
          local extra = pseudo_untracked_diff(record.path, vim.fs.joinpath(root, record.path))
          if extra ~= "" then
            text = text .. (text ~= "" and "\n" or "") .. extra
          end
        end
      end
    end
  end

  if text == "" then
    return "No matching Git diff."
  end
  local lines = vim.split(text, "\n", { plain = true })
  if #lines > MAX_DIFF_LINES then
    lines = vim.list_slice(lines, 1, MAX_DIFF_LINES)
    lines[#lines + 1] = "... diff truncated by nvim-cpp-ide ..."
    return table.concat(lines, "\n")
  end
  return text
end

function M.open_diff(target, opts)
  if is_headless() then
    return nil, "AgentDiff requires an attached Neovim UI"
  end
  local text, err = M.diff_text(target, opts)
  if not text then
    return nil, err
  end

  vim.cmd("botright new")
  local bufnr = vim.api.nvim_get_current_buf()
  local label = opts and opts.staged and "accepted" or "pending"
  pcall(vim.api.nvim_buf_set_name, bufnr, "agent-diff://" .. label .. "/" .. (target or "project"))
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].filetype = "diff"
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(text, "\n", { plain = true }))
  vim.bo[bufnr].modifiable = false
  vim.cmd("normal! gg")
  return { target = target or ".", staged = opts and opts.staged or false }
end

function M.populate_changes()
  local root = project_root()
  local snapshot = M.snapshot(root)
  if not snapshot.available then
    return nil, snapshot.reason
  end

  local items = {}
  for _, record in ipairs(snapshot.files) do
    local state
    if record.pending and record.accepted then
      state = "accepted+pending"
    elseif record.pending then
      state = "pending"
    elseif record.accepted then
      state = "accepted"
    else
      state = "changed"
    end
    table.insert(items, {
      filename = vim.fs.joinpath(root, record.path),
      lnum = 1,
      col = 1,
      text = ("[%s] %s %s"):format(state, record.status, record.path),
    })
  end
  vim.fn.setqflist({}, " ", { title = "Agent changes", items = items })
  if not is_headless() and #items > 0 then
    vim.cmd("copen")
  end
  return snapshot
end

local function gitsigns()
  local ok, gs = pcall(require, "gitsigns")
  if not ok then
    return nil, "gitsigns.nvim is not loaded; file-level AgentAccept/AgentRevert still work"
  end
  return gs
end

function M.next_hunk()
  if vim.bo.filetype == "diff" then
    if vim.fn.search("^@@", "W") == 0 then
      return nil, "No next diff hunk"
    end
    return true
  end
  local gs, err = gitsigns()
  if not gs then
    return nil, err
  end
  if gs.nav_hunk then
    gs.nav_hunk("next")
  elseif gs.next_hunk then
    gs.next_hunk()
  else
    return nil, "Installed gitsigns version has no hunk navigation API"
  end
  return true
end

function M.prev_hunk()
  if vim.bo.filetype == "diff" then
    if vim.fn.search("^@@", "bW") == 0 then
      return nil, "No previous diff hunk"
    end
    return true
  end
  local gs, err = gitsigns()
  if not gs then
    return nil, err
  end
  if gs.nav_hunk then
    gs.nav_hunk("prev")
  elseif gs.prev_hunk then
    gs.prev_hunk()
  else
    return nil, "Installed gitsigns version has no hunk navigation API"
  end
  return true
end

function M.accept_hunk()
  local gs, err = gitsigns()
  if not gs then
    return nil, err
  end
  if not gs.stage_hunk then
    return nil, "Installed gitsigns version has no stage_hunk API"
  end
  gs.stage_hunk()
  vim.schedule(refresh_context)
  return true
end

function M.revert_hunk()
  local gs, err = gitsigns()
  if not gs then
    return nil, err
  end
  if not gs.reset_hunk then
    return nil, "Installed gitsigns version has no reset_hunk API"
  end
  gs.reset_hunk()
  vim.schedule(refresh_context)
  return true
end

function M.keep_hunk()
  return M.next_hunk()
end

M.resolve_path = resolve_path
M.changes = changes

return M
