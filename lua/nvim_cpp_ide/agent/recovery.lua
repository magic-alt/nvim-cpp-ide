local M = {}

local function ensure_runtime_dir(root)
  local dir = vim.fs.joinpath(root, ".nvim-agent")
  vim.fn.mkdir(dir, "p")
  local ignore = vim.fs.joinpath(dir, ".gitignore")
  if vim.fn.filereadable(ignore) ~= 1 then
    vim.fn.writefile({ "*" }, ignore)
  end
  return dir
end

local function stamp()
  return (os.date("!%Y%m%dT%H%M%SZ") .. "-" .. tostring(vim.uv.hrtime())):gsub("[^%w%-]", "-")
end

local function safe_relative(relative)
  relative = tostring(relative or "buffer")
  relative = relative:gsub("\\", "/")
  relative = relative:gsub("^%./", "")
  relative = relative:gsub("^/+", "")
  relative = relative:gsub("%.%./", "")
  if relative == "" or relative == "." then
    relative = "buffer"
  end
  return relative
end

local function recovery_root(root, label)
  local runtime = ensure_runtime_dir(root)
  local dir = vim.fs.joinpath(runtime, "recovery", stamp() .. "-" .. (label or "change"))
  vim.fn.mkdir(dir, "p")
  return dir
end

local function relative_path(root, absolute)
  local root_norm = vim.fs.normalize(root):gsub("\\", "/")
  local value_norm = vim.fs.normalize(absolute):gsub("\\", "/")
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
  return vim.fs.basename(absolute)
end

local function write_lines(path, lines)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  local ok = vim.fn.writefile(lines, path, "b")
  if ok ~= 0 then
    return nil, "Failed to write recovery file: " .. path
  end
  return path
end

function M.backup_buffer(root, bufnr, label)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return nil, "Cannot back up an invalid buffer"
  end

  local source = vim.api.nvim_buf_get_name(bufnr)
  local relative = source ~= "" and relative_path(root, source) or "unnamed-buffer"
  local dir = recovery_root(root, label or "buffer")
  local target = vim.fs.joinpath(dir, safe_relative(relative) .. ".buffer")
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  return write_lines(target, lines)
end

function M.backup_file(root, relative, label)
  relative = safe_relative(relative)
  local source = vim.fs.joinpath(root, relative)
  if vim.fn.filereadable(source) ~= 1 then
    return nil
  end

  local dir = recovery_root(root, label or "file")
  local target = vim.fs.joinpath(dir, relative)
  local lines = vim.fn.readfile(source, "b")
  return write_lines(target, lines)
end

function M.relative(root, absolute)
  local runtime = vim.fs.joinpath(root, ".nvim-agent")
  local root_norm = vim.fs.normalize(root):gsub("\\", "/")
  local value_norm = vim.fs.normalize(absolute):gsub("\\", "/")
  if vim.startswith(value_norm, root_norm .. "/") then
    return "./" .. value_norm:sub(#root_norm + 2)
  end
  if vim.startswith(value_norm, vim.fs.normalize(runtime):gsub("\\", "/") .. "/") then
    return "./.nvim-agent/" .. vim.fs.basename(value_norm)
  end
  return value_norm
end

return M
