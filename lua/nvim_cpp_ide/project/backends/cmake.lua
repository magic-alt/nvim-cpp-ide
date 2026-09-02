local presets = require("nvim_cpp_ide.project.presets")
local path = require("nvim_cpp_ide.project.path")

local M = { name = "cmake" }

local function exists(root, name)
  return vim.fn.filereadable(vim.fs.joinpath(root, name)) == 1
end

local function configured_build_dir(root, config)
  local cfg = config.cmake or {}
  local value = cfg.build_dir or vim.env.NVIM_CPP_IDE_BUILD_DIR or "build"
  return path.resolve(root, value)
end

local function state(ctx)
  local preset_state = presets.resolve(ctx.root, ctx.config)
  if preset_state then
    return {
      presets = preset_state,
      build_dir = preset_state.binary_dir,
    }
  end
  return {
    presets = nil,
    build_dir = configured_build_dir(ctx.root, ctx.config),
  }
end

local function build_command(s)
  if s.presets and s.presets.build then
    return { "cmake", "--build", "--preset", s.presets.build.name }
  end
  return { "cmake", "--build", s.build_dir }
end

function M.detect(root)
  return exists(root, "CMakePresets.json")
    or exists(root, "CMakeUserPresets.json")
    or exists(root, "CMakeLists.txt")
end

function M.resolve(action, ctx)
  local s = state(ctx)
  local argv

  if action == "configure" then
    if s.presets then
      argv = { "cmake", "--preset", s.presets.configure.name }
    else
      argv = { "cmake", "-S", ctx.root, "-B", s.build_dir }
      local generator = (ctx.config.cmake or {}).generator or vim.env.NVIM_CPP_IDE_CMAKE_GENERATOR
      if generator and generator ~= "" then
        vim.list_extend(argv, { "-G", generator })
      end
    end
  elseif action == "build" then
    argv = build_command(s)
  elseif action == "test" then
    if s.presets and s.presets.test then
      argv = { "ctest", "--preset", s.presets.test.name, "--output-on-failure" }
    else
      argv = { "ctest", "--test-dir", s.build_dir, "--output-on-failure" }
    end
  elseif action == "lint" or action == "format" then
    argv = build_command(s)
    vim.list_extend(argv, { "--target", action })
  else
    return nil, ("CMake backend does not support task '%s'"):format(action)
  end

  return {
    action = action,
    backend = M.name,
    argv = argv,
    cwd = ctx.root,
    metadata = {
      build_dir = s.build_dir,
      configure_preset = s.presets and s.presets.configure.name or nil,
      build_preset = s.presets and s.presets.build and s.presets.build.name or nil,
      test_preset = s.presets and s.presets.test and s.presets.test.name or nil,
    },
  }
end

return M
