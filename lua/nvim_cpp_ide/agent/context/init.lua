local collector = require("nvim_cpp_ide.agent.context.collector")
local render = require("nvim_cpp_ide.agent.context.render")

local M = {}

local function write_text(path, text)
  local lines = vim.split(text, "\n", { plain = true })
  local result = vim.fn.writefile(lines, path)
  if result ~= 0 then
    error(("Failed to write %s"):format(path))
  end
end

local function ensure_dir(root)
  local dir = vim.fs.joinpath(root, ".nvim-agent")
  if vim.fn.mkdir(dir, "p") == 0 and vim.fn.isdirectory(dir) ~= 1 then
    error(("Failed to create %s"):format(dir))
  end

  local ignore = vim.fs.joinpath(dir, ".gitignore")
  if vim.fn.filereadable(ignore) ~= 1 then
    write_text(ignore, "*\n")
  end
  return dir
end

local function enrich(snapshot, root)
  local conflicts_ok, conflicts = pcall(function()
    return require("nvim_cpp_ide.agent.conflicts").snapshot()
  end)
  snapshot.external_changes = conflicts_ok and conflicts or {
    count = 0,
    items = {},
    unavailable = tostring(conflicts),
  }

  local review_ok, review = pcall(function()
    return require("nvim_cpp_ide.agent.review").snapshot(root)
  end)
  snapshot.review = review_ok and review or {
    available = false,
    reason = tostring(review),
    changed_count = 0,
    pending_count = 0,
    accepted_count = 0,
    files = {},
  }
  return snapshot
end

function M.paths(root)
  local dir = vim.fs.joinpath(root, ".nvim-agent")
  return {
    dir = dir,
    json = vim.fs.joinpath(dir, "context.json"),
    markdown = vim.fs.joinpath(dir, "context.md"),
    gitignore = vim.fs.joinpath(dir, ".gitignore"),
  }
end

function M.collect(opts)
  opts = opts or {}
  local root = require("nvim_cpp_ide.project.root").get(opts.bufnr or 0)
  return enrich(collector.collect(opts), root)
end

function M.write(opts)
  opts = opts or {}
  local root = require("nvim_cpp_ide.project.root").get(opts.bufnr or 0)
  local snapshot = enrich(collector.collect(opts), root)
  ensure_dir(root)
  local paths = M.paths(root)

  write_text(paths.json, vim.json.encode(snapshot) .. "\n")
  write_text(paths.markdown, render.markdown(snapshot) .. "\n")

  return {
    root = root,
    json_path = paths.json,
    markdown_path = paths.markdown,
    json_relative = ".nvim-agent/context.json",
    markdown_relative = ".nvim-agent/context.md",
    snapshot = snapshot,
  }
end

function M.markdown(snapshot)
  return render.markdown(snapshot)
end

return M
