local project_path = require("nvim_cpp_ide.project.path")

local M = {}

local MAX_DIAGNOSTICS = 200
local MAX_QUICKFIX = 100
local MAX_GIT_FILES = 200

local severity_names = {
  [vim.diagnostic.severity.ERROR] = "ERROR",
  [vim.diagnostic.severity.WARN] = "WARN",
  [vim.diagnostic.severity.INFO] = "INFO",
  [vim.diagnostic.severity.HINT] = "HINT",
}

local function normalized(value)
  return vim.fs.normalize(tostring(value or "")):gsub("\\", "/")
end

local function path_compare(value)
  value = normalized(value)
  if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    return value:lower()
  end
  return value
end

local function relative_path(root, value)
  if type(value) ~= "string" or value == "" then
    return nil
  end

  local root_norm = normalized(root)
  local value_norm = normalized(value)
  local root_cmp = path_compare(root_norm)
  local value_cmp = path_compare(value_norm)

  if value_cmp == root_cmp then
    return "."
  end

  local prefix = root_cmp .. "/"
  if vim.startswith(value_cmp, prefix) then
    return value_norm:sub(#root_norm + 2)
  end
  return nil
end

local function portable_path(root, value)
  if type(value) ~= "string" then
    return value
  end
  if not project_path.is_absolute(value) then
    return value
  end

  local rel = relative_path(root, value)
  if rel == "." then
    return "."
  end
  if rel then
    return "./" .. rel
  end
  return "<external>/" .. vim.fs.basename(value)
end

local function replace_plain_all(value, needle, replacement)
  if needle == "" then
    return value
  end
  local result = value
  local search_from = 1
  while true do
    local start_pos, end_pos = result:find(needle, search_from, true)
    if not start_pos then
      break
    end
    result = result:sub(1, start_pos - 1) .. replacement .. result:sub(end_pos + 1)
    search_from = start_pos + #replacement
  end
  return result
end

local function replace_root(root, value)
  if type(value) ~= "string" then
    return value
  end

  if project_path.is_absolute(value) then
    return portable_path(root, value)
  end

  local result = value
  local root_norm = normalized(root)
  local candidates = {
    tostring(root),
    root_norm,
    root_norm:gsub("/", "\\"),
  }
  local seen = {}
  for _, candidate in ipairs(candidates) do
    if candidate ~= "" and not seen[candidate] then
      seen[candidate] = true
      result = replace_plain_all(result, candidate, ".")
    end
  end
  return result
end

local function sanitize(root, value)
  local kind = type(value)
  if kind == "string" then
    return replace_root(root, value)
  end
  if kind ~= "table" then
    return value
  end

  local result = {}
  if vim.islist(value) then
    for i, item in ipairs(value) do
      result[i] = sanitize(root, item)
    end
  else
    for key, item in pairs(value) do
      result[key] = sanitize(root, item)
    end
  end
  return result
end

local function project_snapshot(root)
  local engine = require("nvim_cpp_ide.project.engine")
  local info = engine.info()
  local tasks = {}

  for _, action in ipairs(engine.actions or {}) do
    local task = info.tasks[action]
    if task and task.available then
      tasks[action] = {
        available = true,
        argv = sanitize(root, task.argv),
        cwd = portable_path(root, task.cwd),
        metadata = sanitize(root, task.metadata),
      }
    else
      tasks[action] = {
        available = false,
        reason = task and sanitize(root, task.reason) or "not resolved",
      }
    end
  end

  return {
    root = ".",
    backend = info.backend,
    config_file = info.config_file and portable_path(root, info.config_file) or nil,
    tasks = tasks,
  }
end

local function task_results(root)
  local engine = require("nvim_cpp_ide.project.engine")
  local results = type(engine.results) == "function" and engine.results() or {
    last = vim.g.nvim_cpp_ide_last_task,
    by_action = {},
  }
  return sanitize(root, results)
end

local function buffer_path(root, bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end
  local name = vim.api.nvim_buf_get_name(bufnr)
  return relative_path(root, name)
end

local function diagnostic_snapshot(root)
  local items = {}
  local counts = { ERROR = 0, WARN = 0, INFO = 0, HINT = 0 }

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      local file = buffer_path(root, bufnr)
      if file then
        for _, diagnostic in ipairs(vim.diagnostic.get(bufnr)) do
          if #items >= MAX_DIAGNOSTICS then
            break
          end
          local severity = severity_names[diagnostic.severity] or tostring(diagnostic.severity or "UNKNOWN")
          counts[severity] = (counts[severity] or 0) + 1
          table.insert(items, {
            file = file,
            line = (diagnostic.lnum or 0) + 1,
            column = (diagnostic.col or 0) + 1,
            end_line = diagnostic.end_lnum and diagnostic.end_lnum + 1 or nil,
            end_column = diagnostic.end_col and diagnostic.end_col + 1 or nil,
            severity = severity,
            message = replace_root(root, diagnostic.message),
            source = replace_root(root, diagnostic.source),
            code = sanitize(root, diagnostic.code),
          })
        end
      end
    end
    if #items >= MAX_DIAGNOSTICS then
      break
    end
  end

  table.sort(items, function(a, b)
    if a.file ~= b.file then
      return a.file < b.file
    end
    if a.line ~= b.line then
      return a.line < b.line
    end
    return a.column < b.column
  end)

  return {
    count = #items,
    truncated = #items >= MAX_DIAGNOSTICS,
    counts = counts,
    items = items,
  }
end

local symbol_node_types = {
  function_definition = true,
  function_declarator = true,
  method_definition = true,
  class_specifier = true,
  struct_specifier = true,
  namespace_definition = true,
  enum_specifier = true,
  function_item = true,
  impl_item = true,
}

local identifier_node_types = {
  identifier = true,
  field_identifier = true,
  type_identifier = true,
  namespace_identifier = true,
  operator_name = true,
}

local function first_identifier(node, bufnr, depth)
  if not node or depth > 6 then
    return nil
  end
  if identifier_node_types[node:type()] then
    local text = vim.treesitter.get_node_text(node, bufnr)
    if type(text) == "string" and text ~= "" then
      return vim.trim(text:gsub("\n.*$", "")):sub(1, 120)
    end
  end

  for child in node:iter_children() do
    if child:named() then
      local found = first_identifier(child, bufnr, depth + 1)
      if found then
        return found
      end
    end
  end
  return nil
end

local function current_symbol(bufnr)
  local ok, node = pcall(vim.treesitter.get_node, { bufnr = bufnr })
  if ok and node then
    local cursor = node
    while cursor do
      if symbol_node_types[cursor:type()] then
        local name = first_identifier(cursor, bufnr, 0)
        if name then
          return { name = name, source = "treesitter", node_type = cursor:type() }
        end
      end
      cursor = cursor:parent()
    end
  end

  local word = vim.fn.expand("<cword>")
  if word and word ~= "" then
    return { name = word, source = "cursor-word" }
  end
  return nil
end

local function current_snapshot(root)
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  return {
    file = buffer_path(root, bufnr),
    filetype = vim.bo[bufnr].filetype,
    modified = vim.bo[bufnr].modified,
    cursor = { line = cursor[1], column = cursor[2] + 1 },
    symbol = current_symbol(bufnr),
  }
end

local function run_git(root, args)
  if vim.fn.executable("git") ~= 1 then
    return nil
  end
  local argv = { "git", "-C", root }
  vim.list_extend(argv, args)
  return vim.system(argv, { text = true }):wait()
end

local function parse_status(output)
  local files = {}
  local branch_line
  for _, line in ipairs(vim.split(output or "", "\n", { plain = true, trimempty = true })) do
    if vim.startswith(line, "## ") then
      branch_line = line:sub(4)
    elseif #line >= 3 and #files < MAX_GIT_FILES then
      local status = line:sub(1, 2)
      local path = vim.trim(line:sub(4))
      if not vim.startswith(path, ".nvim-agent/") and path ~= ".nvim-agent" then
        table.insert(files, { status = status, path = path })
      end
    end
  end
  return branch_line, files
end

local function parse_numstat(output)
  local files = {}
  local added = 0
  local deleted = 0
  for _, line in ipairs(vim.split(output or "", "\n", { plain = true, trimempty = true })) do
    if #files >= MAX_GIT_FILES then
      break
    end
    local add, del, file = line:match("^([^\t]+)\t([^\t]+)\t(.+)$")
    if file and not vim.startswith(file, ".nvim-agent/") then
      local add_num = tonumber(add)
      local del_num = tonumber(del)
      if add_num then
        added = added + add_num
      end
      if del_num then
        deleted = deleted + del_num
      end
      table.insert(files, {
        path = file,
        added = add_num,
        deleted = del_num,
        binary = add == "-" or del == "-",
      })
    end
  end
  return { added = added, deleted = deleted, files = files, count = #files }
end

local function git_snapshot(root)
  local inside = run_git(root, { "rev-parse", "--is-inside-work-tree" })
  if not inside or inside.code ~= 0 or vim.trim(inside.stdout or "") ~= "true" then
    return { available = false }
  end

  local status_result = run_git(root, { "status", "--short", "--branch", "--untracked-files=normal", "--", "." })
  local branch_line, files = parse_status(status_result and status_result.stdout or "")
  local branch_result = run_git(root, { "rev-parse", "--abbrev-ref", "HEAD" })
  local head_result = run_git(root, { "rev-parse", "--short", "HEAD" })
  local unstaged = run_git(root, { "diff", "--numstat", "--relative", "--", "." })
  local staged = run_git(root, { "diff", "--cached", "--numstat", "--relative", "--", "." })

  local branch = branch_result and branch_result.code == 0 and vim.trim(branch_result.stdout or "") or nil
  if branch == "HEAD" then
    branch = nil
  end

  return {
    available = true,
    branch = branch,
    head = head_result and head_result.code == 0 and vim.trim(head_result.stdout or "") or nil,
    branch_status = branch_line,
    dirty = #files > 0,
    changed_files = files,
    changed_count = #files,
    truncated = #files >= MAX_GIT_FILES,
    unstaged = parse_numstat(unstaged and unstaged.stdout or ""),
    staged = parse_numstat(staged and staged.stdout or ""),
  }
end

local function quickfix_snapshot(root)
  local raw = vim.fn.getqflist({ title = 1, items = 1 })
  local items = {}
  for _, item in ipairs(raw.items or {}) do
    if #items >= MAX_QUICKFIX then
      break
    end
    local name = item.filename
    if (not name or name == "") and item.bufnr and item.bufnr > 0 then
      name = vim.api.nvim_buf_get_name(item.bufnr)
    end
    local file = name and relative_path(root, name) or nil
    table.insert(items, {
      file = file,
      line = item.lnum and item.lnum > 0 and item.lnum or nil,
      column = item.col and item.col > 0 and item.col or nil,
      type = item.type ~= "" and item.type or nil,
      text = replace_root(root, item.text),
      valid = item.valid == 1 or item.valid == true,
    })
  end
  return {
    title = replace_root(root, raw.title or ""),
    count = #items,
    truncated = #(raw.items or {}) > MAX_QUICKFIX,
    items = items,
  }
end

function M.collect(opts)
  opts = opts or {}
  local root = require("nvim_cpp_ide.project.root").get(opts.bufnr or 0)
  return {
    schema_version = 1,
    generated_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    runtime = {
      profile = vim.g.nvim_cpp_ide_profile or "unknown",
      neovim = vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch,
      headless = #vim.api.nvim_list_uis() == 0,
    },
    project = project_snapshot(root),
    current = current_snapshot(root),
    diagnostics = diagnostic_snapshot(root),
    git = git_snapshot(root),
    task_results = task_results(root),
    quickfix = quickfix_snapshot(root),
  }
end

M.relative_path = relative_path
M.portable_path = portable_path

return M
