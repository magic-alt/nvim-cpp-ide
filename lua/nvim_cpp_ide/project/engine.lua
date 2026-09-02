local root = require("nvim_cpp_ide.project.root")
local project_config = require("nvim_cpp_ide.project.config")
local path = require("nvim_cpp_ide.project.path")

local M = {}

local actions = { "configure", "build", "test", "lint", "format" }
local action_set = {}
for _, action in ipairs(actions) do
  action_set[action] = true
end

local backends = {
  require("nvim_cpp_ide.project.backends.cmake"),
  require("nvim_cpp_ide.project.backends.ninja"),
  require("nvim_cpp_ide.project.backends.make"),
}

local function backend_by_name(name)
  for _, backend in ipairs(backends) do
    if backend.name == name then
      return backend
    end
  end
  return nil
end

local function detect_backend(ctx)
  local requested = ctx.config.backend or vim.env.NVIM_CPP_IDE_BACKEND
  if requested and requested ~= "" then
    local backend = backend_by_name(tostring(requested):lower())
    if not backend then
      error(("Unknown project backend '%s'. Valid backends: cmake, ninja, make"):format(requested))
    end
    return backend
  end

  for _, backend in ipairs(backends) do
    if backend.detect(ctx.root) then
      return backend
    end
  end

  return nil
end

local function context(bufnr)
  local project_root = root.get(bufnr)
  local config = project_config.load(project_root)
  local ctx = {
    root = project_root,
    config = config,
  }
  ctx.backend = detect_backend(ctx)
  return ctx
end

local function normalize_override(action, ctx)
  local tasks = ctx.config.tasks
  if type(tasks) ~= "table" then
    return nil
  end

  local override = tasks[action]
  if override == nil then
    return nil
  end

  local argv
  local cwd = ctx.root
  if vim.islist(override) then
    argv = override
  elseif type(override) == "table" and vim.islist(override.argv) then
    argv = override.argv
    if type(override.cwd) == "string" and override.cwd ~= "" then
      cwd = path.resolve(ctx.root, override.cwd)
    end
  else
    error(("Task override '%s' in %s must be a JSON argv array or an object with an argv array")
      :format(action, project_config.path(ctx.root)))
  end

  if #argv == 0 then
    error(("Task override '%s' must not be empty"):format(action))
  end

  local normalized = {}
  for i, value in ipairs(argv) do
    if type(value) ~= "string" and type(value) ~= "number" then
      error(("Task override '%s' argv[%d] must be a string or number"):format(action, i))
    end
    normalized[i] = tostring(value)
  end

  return {
    action = action,
    backend = ctx.backend and ctx.backend.name or "custom",
    argv = normalized,
    cwd = cwd,
    metadata = { override = true },
  }
end

local function resolve_with_context(action, ctx)
  action = tostring(action or ""):lower()
  if not action_set[action] then
    return nil, ("Unknown project task '%s'. Valid tasks: %s"):format(action, table.concat(actions, ", "))
  end

  local override = normalize_override(action, ctx)
  if override then
    return override
  end

  if not ctx.backend then
    return nil, ("No supported project backend found at %s (expected CMakePresets.json, CMakeLists.txt, build.ninja, or Makefile)")
      :format(ctx.root)
  end

  return ctx.backend.resolve(action, ctx)
end

function M.resolve(action, opts)
  opts = opts or {}
  return resolve_with_context(action, context(opts.bufnr))
end

local function task_record(task, result)
  return {
    action = task.action,
    backend = task.backend,
    cwd = task.cwd,
    argv = task.argv,
    code = result.code,
    signal = result.signal,
  }
end

local function combined_lines(result)
  local text = table.concat({ result.stdout or "", result.stderr or "" }, "\n")
  return vim.split(text, "\n", { plain = true, trimempty = true })
end

local function is_headless()
  return #vim.api.nvim_list_uis() == 0
end

local function command_string(argv)
  local escaped = {}
  for i, value in ipairs(argv) do
    escaped[i] = vim.fn.shellescape(value)
  end
  return table.concat(escaped, " ")
end

local function run_sync(task, opts)
  local result = vim.system(task.argv, {
    cwd = task.cwd,
    text = true,
  }):wait()

  vim.g.nvim_cpp_ide_last_task = task_record(task, result)

  if result.stdout and result.stdout ~= "" then
    io.stdout:write(result.stdout)
  end
  if result.stderr and result.stderr ~= "" then
    io.stderr:write(result.stderr)
  end

  if result.code ~= 0 and opts.fail_exit ~= false then
    vim.cmd("cquit " .. math.min(math.max(result.code, 1), 255))
  end

  return result
end

local function run_async(task)
  vim.notify(
    ("[%s] %s\n%s"):format(task.backend, task.action, command_string(task.argv)),
    vim.log.levels.INFO
  )

  return vim.system(task.argv, {
    cwd = task.cwd,
    text = true,
  }, function(result)
    vim.schedule(function()
      vim.g.nvim_cpp_ide_last_task = task_record(task, result)
      local lines = combined_lines(result)
      vim.fn.setqflist({}, " ", {
        title = ("Project %s (%s)"):format(task.action, task.backend),
        lines = lines,
      })

      if result.code == 0 then
        vim.notify(("Project %s completed successfully"):format(task.action), vim.log.levels.INFO)
      else
        vim.notify(("Project %s failed (exit %d)"):format(task.action, result.code), vim.log.levels.ERROR)
        if #lines > 0 then
          vim.cmd("copen")
        end
      end
    end)
  end)
end

function M.run(action, opts)
  opts = opts or {}
  local task, err = M.resolve(action, opts)
  if not task then
    if is_headless() or opts.sync then
      io.stderr:write(err .. "\n")
      if opts.fail_exit ~= false then
        vim.cmd("cquit 2")
      end
      return nil, err
    end
    vim.notify(err, vim.log.levels.ERROR)
    return nil, err
  end

  if is_headless() or opts.sync then
    return run_sync(task, opts)
  end
  return run_async(task)
end

function M.info(opts)
  opts = opts or {}
  local ctx = context(opts.bufnr)
  local result = {
    root = ctx.root,
    backend = ctx.backend and ctx.backend.name or nil,
    config_file = vim.fn.filereadable(project_config.path(ctx.root)) == 1 and project_config.path(ctx.root) or nil,
    tasks = {},
  }

  for _, action in ipairs(actions) do
    local ok, task, err = pcall(function()
      local resolved, resolve_err = resolve_with_context(action, ctx)
      return resolved, resolve_err
    end)
    if ok and task then
      result.tasks[action] = {
        available = true,
        argv = task.argv,
        cwd = task.cwd,
        metadata = task.metadata,
      }
    else
      result.tasks[action] = {
        available = false,
        reason = ok and err or task,
      }
    end
  end

  return result
end

local function show_info()
  local info = M.info()
  if is_headless() then
    print(vim.json.encode(info))
  else
    vim.notify(vim.inspect(info), vim.log.levels.INFO, { title = "Project Task Engine" })
  end
end

local function completion(arg_lead)
  local matches = {}
  for _, action in ipairs(actions) do
    if vim.startswith(action, arg_lead) then
      table.insert(matches, action)
    end
  end
  return matches
end

function M.setup()
  if vim.g.nvim_cpp_ide_project_task_engine == 1 then
    return
  end
  vim.g.nvim_cpp_ide_project_task_engine = 1

  vim.api.nvim_create_user_command("ProjectInfo", show_info, {
    desc = "Show detected project backend and resolved tasks",
  })

  vim.api.nvim_create_user_command("ProjectTask", function(args)
    M.run(args.args)
  end, {
    nargs = 1,
    complete = completion,
    desc = "Run a unified project task",
  })

  for _, action in ipairs(actions) do
    local command = "Project" .. action:sub(1, 1):upper() .. action:sub(2)
    vim.api.nvim_create_user_command(command, function()
      M.run(action)
    end, {
      desc = ("Run project %s task"):format(action),
    })
  end
end

M.actions = actions

return M
