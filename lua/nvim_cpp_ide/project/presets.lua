local path = require("nvim_cpp_ide.project.path")

local M = {}

local non_inherited_fields = {
  name = true,
  hidden = true,
  inherits = true,
  description = true,
  displayName = true,
}

local function read_json(filename)
  if vim.fn.filereadable(filename) ~= 1 then
    return nil
  end

  local raw = table.concat(vim.fn.readfile(filename), "\n")
  local ok, decoded = pcall(vim.json.decode, raw)
  if not ok or type(decoded) ~= "table" then
    error(("Invalid CMake preset file %s: %s"):format(filename, ok and "expected a JSON object" or decoded))
  end
  return decoded
end

local function merge_named(dst, src)
  if type(src) ~= "table" then
    return
  end

  local index = {}
  for i, item in ipairs(dst) do
    if type(item) == "table" and item.name then
      index[item.name] = i
    end
  end

  for _, item in ipairs(src) do
    if type(item) == "table" and item.name then
      if index[item.name] then
        dst[index[item.name]] = item
      else
        table.insert(dst, item)
        index[item.name] = #dst
      end
    end
  end
end

local function expand_include(value, root, file_dir)
  value = value:gsub("%${sourceDir}", vim.fs.normalize(root))
  value = value:gsub("%${fileDir}", vim.fs.normalize(file_dir))
  value = value:gsub("%$env%{([%w_]+)%}", function(key)
    return vim.env[key] or ""
  end)
  value = value:gsub("%$penv%{([%w_]+)%}", function(key)
    return vim.env[key] or ""
  end)
  return path.resolve(file_dir, value)
end

local function load_file(filename, root, data, seen)
  filename = vim.fs.normalize(filename)
  if seen[filename] then
    return
  end
  seen[filename] = true

  local decoded = read_json(filename)
  if not decoded then
    return
  end

  local includes = decoded.include
  if type(includes) == "string" then
    includes = { includes }
  end
  if type(includes) == "table" then
    local file_dir = vim.fs.dirname(filename)
    for _, include in ipairs(includes) do
      if type(include) == "string" then
        load_file(expand_include(include, root, file_dir), root, data, seen)
      end
    end
  end

  merge_named(data.configurePresets, decoded.configurePresets)
  merge_named(data.buildPresets, decoded.buildPresets)
  merge_named(data.testPresets, decoded.testPresets)
end

local function inheritable(preset)
  local result = {}
  for key, value in pairs(preset) do
    if not non_inherited_fields[key] then
      result[key] = vim.deepcopy(value)
    end
  end
  return result
end

local function normalize_parents(value)
  if type(value) == "string" then
    return { value }
  end
  if type(value) == "table" then
    return value
  end
  return {}
end

local function resolve_inheritance(list, kind)
  local raw = {}
  for _, preset in ipairs(list) do
    if type(preset) == "table" and preset.name then
      raw[preset.name] = preset
    end
  end

  local cache = {}
  local visiting = {}

  local function resolve_one(name)
    if cache[name] then
      return cache[name]
    end
    if visiting[name] then
      error(("CMake %s preset inheritance cycle at '%s'"):format(kind, name))
    end

    local preset = raw[name]
    if not preset then
      error(("CMake %s preset inherits unknown preset '%s'"):format(kind, name))
    end

    visiting[name] = true
    local result = {}
    local parents = normalize_parents(preset.inherits)

    -- CMake gives earlier parents precedence when multiple parents conflict.
    for i = #parents, 1, -1 do
      local parent = resolve_one(parents[i])
      result = vim.tbl_deep_extend("force", result, inheritable(parent))
    end

    result = vim.tbl_deep_extend("force", result, vim.deepcopy(preset))
    visiting[name] = nil
    cache[name] = result
    return result
  end

  local resolved = {}
  for _, preset in ipairs(list) do
    if type(preset) == "table" and preset.name then
      table.insert(resolved, resolve_one(preset.name))
    end
  end
  return resolved
end

function M.load(root)
  local data = {
    configurePresets = {},
    buildPresets = {},
    testPresets = {},
  }
  local seen = {}

  for _, name in ipairs({ "CMakePresets.json", "CMakeUserPresets.json" }) do
    load_file(vim.fs.joinpath(root, name), root, data, seen)
  end

  data.configurePresets = resolve_inheritance(data.configurePresets, "configure")
  data.buildPresets = resolve_inheritance(data.buildPresets, "build")
  data.testPresets = resolve_inheritance(data.testPresets, "test")
  return data
end

local function by_name(list, name)
  if not name or name == "" then
    return nil
  end
  for _, preset in ipairs(list) do
    if preset.name == name then
      return preset
    end
  end
  return nil
end

local function first_visible(list, predicate)
  for _, preset in ipairs(list) do
    if not preset.hidden and (not predicate or predicate(preset)) then
      return preset
    end
  end
  return nil
end

local function choose(list, explicit, predicate, kind)
  if explicit and explicit ~= "" then
    local preset = by_name(list, explicit)
    if not preset then
      error(("Unknown CMake %s preset '%s'"):format(kind, explicit))
    end
    if preset.hidden then
      error(("CMake %s preset '%s' is hidden and cannot be selected directly"):format(kind, explicit))
    end
    return preset
  end
  return first_visible(list, predicate)
end

local function expand_binary_dir(value, root, preset)
  if not value or value == "" then
    return vim.fs.joinpath(root, "build", preset.name)
  end

  local source_dir = vim.fs.normalize(root)
  local source_parent = vim.fs.dirname(source_dir)
  local source_name = vim.fs.basename(source_dir)

  value = value:gsub("%${sourceDir}", source_dir)
  value = value:gsub("%${sourceParentDir}", source_parent)
  value = value:gsub("%${sourceDirName}", source_name)
  value = value:gsub("%${presetName}", preset.name or "")
  value = value:gsub("%$env%{([%w_]+)%}", function(key)
    return vim.env[key] or ""
  end)
  value = value:gsub("%$penv%{([%w_]+)%}", function(key)
    return vim.env[key] or ""
  end)

  return path.resolve(root, value)
end

function M.resolve(root, project_config)
  local data = M.load(root)
  if #data.configurePresets == 0 then
    return nil
  end

  local cfg = project_config.cmake or {}
  local configure_name = cfg.configure_preset or vim.env.NVIM_CPP_IDE_CMAKE_PRESET
  local configure = choose(data.configurePresets, configure_name, nil, "configure")
  if not configure then
    return nil
  end

  local build_name = cfg.build_preset or vim.env.NVIM_CPP_IDE_CMAKE_BUILD_PRESET
  local build = choose(data.buildPresets, build_name, function(preset)
    return preset.configurePreset == configure.name or preset.name == configure.name
  end, "build")

  local test_name = cfg.test_preset or vim.env.NVIM_CPP_IDE_CMAKE_TEST_PRESET
  local test = choose(data.testPresets, test_name, function(preset)
    return preset.configurePreset == configure.name or preset.name == configure.name
  end, "test")

  return {
    configure = configure,
    build = build,
    test = test,
    binary_dir = expand_binary_dir(configure.binaryDir, root, configure),
  }
end

return M
