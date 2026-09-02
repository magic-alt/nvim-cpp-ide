local M = {}

local ignored_dirs = {
  [".git"] = true,
  [".cache"] = true,
  [".venv"] = true,
  ["node_modules"] = true,
  ["build"] = true,
  ["dist"] = true,
  ["out"] = true,
}

local marker_files = {
  "README.md",
  "ARCHITECTURE.md",
  "CONTRIBUTING.md",
  "CMakeLists.txt",
  "CMakePresets.json",
  "CMakeUserPresets.json",
  "Makefile",
  "makefile",
  "build.ninja",
  ".nvim-cpp-ide.json",
}

local function top_level_dirs(root)
  local dirs = {}
  local ok, iterator = pcall(vim.fs.dir, root)
  if not ok or not iterator then
    return dirs
  end

  for name, kind in iterator do
    if kind == "directory"
      and not ignored_dirs[name]
      and not vim.startswith(name, ".")
      and not vim.startswith(name, "cmake-build-")
    then
      table.insert(dirs, name)
    end
  end
  table.sort(dirs)
  if #dirs > 16 then
    local trimmed = {}
    for i = 1, 16 do
      trimmed[i] = dirs[i]
    end
    return trimmed
  end
  return dirs
end

local function visible_markers(root)
  local files = {}
  for _, name in ipairs(marker_files) do
    if vim.fn.filereadable(vim.fs.joinpath(root, name)) == 1 then
      table.insert(files, name)
    end
  end
  return files
end

function M.inspect(opts)
  opts = opts or {}
  local engine = require("nvim_cpp_ide.project.engine")
  local info = engine.info({ bufnr = opts.bufnr })

  return {
    root = info.root,
    name = vim.fs.basename(info.root),
    backend = info.backend,
    config_file = info.config_file,
    tasks = info.tasks,
    task_order = engine.actions,
    directories = top_level_dirs(info.root),
    markers = visible_markers(info.root),
  }
end

return M
