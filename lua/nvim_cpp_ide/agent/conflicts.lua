local recovery = require("nvim_cpp_ide.agent.recovery")

local M = {}

local baselines = {}
local conflicts = {}

local function is_headless()
  return #vim.api.nvim_list_uis() == 0
end

local function relevant_buffer(bufnr)
  return vim.api.nvim_buf_is_valid(bufnr)
    and vim.api.nvim_buf_is_loaded(bufnr)
    and vim.bo[bufnr].buftype == ""
    and vim.api.nvim_buf_get_name(bufnr) ~= ""
end

local function signature(path)
  local stat = vim.uv.fs_stat(path)
  if not stat then
    return nil
  end
  local mtime = stat.mtime or {}
  return table.concat({
    tostring(stat.size or 0),
    tostring(mtime.sec or 0),
    tostring(mtime.nsec or 0),
  }, ":")
end

local function relative_path(root, value)
  local root_norm = vim.fs.normalize(root):gsub("\\", "/")
  local value_norm = vim.fs.normalize(value):gsub("\\", "/")
  local root_cmp = root_norm
  local value_cmp = value_norm
  if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    root_cmp = root_cmp:lower()
    value_cmp = value_cmp:lower()
  end
  if value_cmp == root_cmp then
    return "."
  end
  local prefix = root_cmp .. "/"
  if vim.startswith(value_cmp, prefix) then
    return value_norm:sub(#root_norm + 2)
  end
  return nil
end

local function project_root(bufnr)
  local ok, root = pcall(require("nvim_cpp_ide.project.root").get, bufnr)
  return ok and root or nil
end

local function remember(bufnr)
  if not relevant_buffer(bufnr) then
    return
  end
  local path = vim.api.nvim_buf_get_name(bufnr)
  baselines[bufnr] = {
    path = path,
    signature = signature(path),
  }
  conflicts[bufnr] = nil
end

local function conflict_record(bufnr, path, root, disk_signature, reason)
  local existing = conflicts[bufnr]
  if existing and existing.disk_signature == disk_signature and existing.reason == reason then
    return existing
  end

  local record = {
    bufnr = bufnr,
    file = relative_path(root, path) or vim.fs.basename(path),
    reason = reason,
    local_modified = vim.bo[bufnr].modified,
    changedtick = vim.api.nvim_buf_get_changedtick(bufnr),
    disk_signature = disk_signature,
    detected_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
  }
  conflicts[bufnr] = record

  if not is_headless() then
    vim.schedule(function()
      vim.notify(
        ("External change conflicts with unsaved buffer: %s\nUse :AgentConflictDiff, :AgentConflictKeep, or :AgentConflictUseDisk"):format(record.file),
        vim.log.levels.WARN,
        { title = "Agent File Conflict" }
      )
    end)
  end
  return record
end

function M.check(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not relevant_buffer(bufnr) then
    return nil
  end

  local path = vim.api.nvim_buf_get_name(bufnr)
  local root = project_root(bufnr)
  if not root or not relative_path(root, path) then
    return nil
  end

  local baseline = baselines[bufnr]
  if not baseline or baseline.path ~= path then
    remember(bufnr)
    return nil
  end

  local disk_signature = signature(path)
  if disk_signature == baseline.signature then
    return conflicts[bufnr]
  end

  if not disk_signature then
    return conflict_record(bufnr, path, root, nil, "deleted-on-disk")
  end

  if vim.bo[bufnr].modified then
    return conflict_record(bufnr, path, root, disk_signature, "changed-on-disk")
  end

  vim.api.nvim_buf_call(bufnr, function()
    vim.cmd("silent! checktime")
  end)
  baselines[bufnr] = { path = path, signature = signature(path) }
  conflicts[bufnr] = nil
  return nil
end

function M.scan()
  local found = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if relevant_buffer(bufnr) then
      local conflict = M.check(bufnr)
      if conflict then
        table.insert(found, vim.deepcopy(conflict))
      end
    end
  end
  table.sort(found, function(a, b)
    return a.file < b.file
  end)
  return found
end

local function resolve_buffer(target)
  if not target or target == "" then
    local current = vim.api.nvim_get_current_buf()
    return conflicts[current] and current or nil
  end

  local normalized = target:gsub("\\", "/"):gsub("^%./", "")
  for bufnr, record in pairs(conflicts) do
    if record.file == normalized then
      return bufnr
    end
  end
  return nil
end

function M.list()
  return M.scan()
end

function M.keep(target)
  local bufnr = resolve_buffer(target)
  if not bufnr then
    return nil, "No matching external-file conflict"
  end
  local path = vim.api.nvim_buf_get_name(bufnr)
  baselines[bufnr] = { path = path, signature = signature(path) }
  local record = conflicts[bufnr]
  conflicts[bufnr] = nil
  return {
    action = "keep-buffer",
    file = record.file,
    modified = vim.bo[bufnr].modified,
  }
end

function M.use_disk(target)
  local bufnr = resolve_buffer(target)
  if not bufnr then
    return nil, "No matching external-file conflict"
  end

  local record = conflicts[bufnr]
  local root = project_root(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  if vim.fn.filereadable(path) ~= 1 then
    return nil, ("Disk version is unavailable for %s"):format(record.file)
  end

  local backup, backup_err = recovery.backup_buffer(root, bufnr, "conflict-buffer")
  if not backup and backup_err then
    return nil, backup_err
  end

  vim.api.nvim_buf_call(bufnr, function()
    vim.cmd("silent edit!")
  end)
  remember(bufnr)

  return {
    action = "use-disk",
    file = record.file,
    recovery = backup and recovery.relative(root, backup) or nil,
  }
end

local function scratch_buffer(name, lines, filetype)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(bufnr, name)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].filetype = filetype
  vim.bo[bufnr].modifiable = false
  return bufnr
end

function M.open_diff(target)
  if is_headless() then
    return nil, "Conflict diff requires an attached Neovim UI"
  end

  local bufnr = resolve_buffer(target)
  if not bufnr then
    return nil, "No matching external-file conflict"
  end

  local record = conflicts[bufnr]
  local path = vim.api.nvim_buf_get_name(bufnr)
  if vim.fn.filereadable(path) ~= 1 then
    return nil, ("Disk version is unavailable for %s"):format(record.file)
  end

  local local_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local disk_lines = vim.fn.readfile(path, "b")
  local filetype = vim.bo[bufnr].filetype

  vim.cmd("tabnew")
  local left_win = vim.api.nvim_get_current_win()
  local left_buf = scratch_buffer("agent-conflict://buffer/" .. record.file, local_lines, filetype)
  vim.api.nvim_win_set_buf(left_win, left_buf)

  vim.cmd("vnew")
  local right_win = vim.api.nvim_get_current_win()
  local right_buf = scratch_buffer("agent-conflict://disk/" .. record.file, disk_lines, filetype)
  vim.api.nvim_win_set_buf(right_win, right_buf)

  vim.api.nvim_win_call(left_win, function()
    vim.cmd("diffthis")
  end)
  vim.api.nvim_win_call(right_win, function()
    vim.cmd("diffthis")
  end)
  vim.api.nvim_set_current_win(left_win)

  return { file = record.file, left = "buffer", right = "disk" }
end

function M.snapshot()
  local items = M.scan()
  return {
    count = #items,
    items = items,
  }
end

function M.setup()
  local group = vim.api.nvim_create_augroup("nvim_cpp_ide_agent_files", { clear = true })

  vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "BufFilePost" }, {
    group = group,
    desc = "Track on-disk baseline for agent conflict detection",
    callback = function(args)
      remember(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
    group = group,
    callback = function(args)
      baselines[args.buf] = nil
      conflicts[args.buf] = nil
    end,
  })

  vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
    group = group,
    desc = "Safely reload clean buffers or flag local-vs-disk conflicts",
    callback = function(args)
      M.check(args.buf)
    end,
  })

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if relevant_buffer(bufnr) then
      remember(bufnr)
    end
  end
end

return M
