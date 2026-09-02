local M = { name = "make" }

local function exists(root, name)
  return vim.fn.filereadable(vim.fs.joinpath(root, name)) == 1
end

function M.detect(root)
  return exists(root, "Makefile") or exists(root, "makefile")
end

function M.resolve(action, ctx)
  if action == "configure" then
    return nil, "Make projects do not define a generic configure task"
  end

  local argv = { "make", "-C", ctx.root }
  if action ~= "build" then
    vim.list_extend(argv, { action })
  end

  return {
    action = action,
    backend = M.name,
    argv = argv,
    cwd = ctx.root,
    metadata = {},
  }
end

return M
