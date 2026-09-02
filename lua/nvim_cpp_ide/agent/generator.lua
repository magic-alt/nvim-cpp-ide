local discovery = require("nvim_cpp_ide.agent.discovery")
local template = require("nvim_cpp_ide.agent.template")

local M = {}

local function read_lines(path)
  if vim.fn.filereadable(path) ~= 1 then
    return {}
  end
  return vim.fn.readfile(path)
end

local function has_agents_bridge(lines)
  for _, line in ipairs(lines) do
    if vim.trim(line) == "@AGENTS.md" then
      return true
    end
  end
  return false
end

local function write_text(path, text)
  local lines = vim.split(text, "\n", { plain = true })
  local result = vim.fn.writefile(lines, path)
  if result ~= 0 then
    error(("Failed to write %s"):format(path))
  end
end

local function ensure_claude_bridge(root)
  local path = vim.fs.joinpath(root, "CLAUDE.md")
  if vim.fn.filereadable(path) ~= 1 then
    write_text(path, template.claude_bridge())
    return { path = path, created = true, updated = false }
  end

  local lines = read_lines(path)
  if has_agents_bridge(lines) then
    return { path = path, created = false, updated = false }
  end

  if #lines > 0 and lines[#lines] ~= "" then
    table.insert(lines, "")
  end
  table.insert(lines, "@AGENTS.md")
  local result = vim.fn.writefile(lines, path)
  if result ~= 0 then
    error(("Failed to update %s"):format(path))
  end
  return { path = path, created = false, updated = true }
end

function M.run(opts)
  opts = opts or {}
  local ctx = discovery.inspect({ bufnr = opts.bufnr })
  local agents_path = vim.fs.joinpath(ctx.root, "AGENTS.md")
  local agents_exists = vim.fn.filereadable(agents_path) == 1
  local agents_created = false
  local agents_updated = false
  local agents_preserved = false

  if not agents_exists then
    write_text(agents_path, template.render(ctx))
    agents_created = true
  elseif opts.force then
    write_text(agents_path, template.render(ctx))
    agents_updated = true
  else
    agents_preserved = true
  end

  local claude = ensure_claude_bridge(ctx.root)

  return {
    root = ctx.root,
    agents_path = agents_path,
    agents_created = agents_created,
    agents_updated = agents_updated,
    agents_preserved = agents_preserved,
    claude_path = claude.path,
    claude_created = claude.created,
    claude_updated = claude.updated,
    backend = ctx.backend,
  }
end

return M
