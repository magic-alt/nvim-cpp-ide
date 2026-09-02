local M = { name = "ninja" }

local function exists(root, name)
  return vim.fn.filereadable(vim.fs.joinpath(root, name)) == 1
end

function M.detect(root)
  return exists(root, "build.ninja")
end

function M.resolve(action, ctx)
  if action == "configure" then
    return nil, "Standalone Ninja projects do not define a configure task"
  end

  local argv = { "ninja", "-C", ctx.root }
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
