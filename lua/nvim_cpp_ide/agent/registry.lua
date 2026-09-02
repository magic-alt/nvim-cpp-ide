local M = {}

local defaults = {
  codex = {
    label = "Codex",
    argv = { "codex" },
  },
  claude = {
    label = "Claude Code",
    argv = { "claude" },
  },
  gemini = {
    label = "Gemini CLI",
    argv = { "gemini" },
  },
}

local function normalize_argv(name, value)
  if type(value) == "string" then
    return { value }
  end

  if vim.islist(value) then
    local argv = {}
    for i, item in ipairs(value) do
      if type(item) ~= "string" and type(item) ~= "number" then
        error(("Agent '%s' argv[%d] must be a string or number"):format(name, i))
      end
      argv[i] = tostring(item)
    end
    return argv
  end

  return nil
end

local function normalize_entry(name, value)
  if value == false then
    return nil
  end

  local entry = {}
  if type(value) == "string" or vim.islist(value) then
    entry.argv = normalize_argv(name, value)
  elseif type(value) == "table" then
    entry.label = value.label
    entry.argv = normalize_argv(name, value.argv or value.command)
  else
    error(("Agent '%s' must be a command string, argv array, config table, or false"):format(name))
  end

  if not entry.argv or #entry.argv == 0 then
    error(("Agent '%s' must define a non-empty argv array"):format(name))
  end

  entry.name = name
  entry.label = entry.label or name
  entry.available = vim.fn.executable(entry.argv[1]) == 1
  return entry
end

local function merged_config()
  local merged = vim.deepcopy(defaults)
  local custom = vim.g.nvim_cpp_ide_agents
  if custom == nil then
    return merged
  end
  if type(custom) ~= "table" then
    error("vim.g.nvim_cpp_ide_agents must be a table")
  end

  for name, value in pairs(custom) do
    if value == false then
      merged[name] = false
    elseif type(value) == "table" and not vim.islist(value) and type(merged[name]) == "table" then
      merged[name] = vim.tbl_deep_extend("force", merged[name], value)
    else
      merged[name] = value
    end
  end
  return merged
end

function M.entries()
  local entries = {}
  for name, value in pairs(merged_config()) do
    local entry = normalize_entry(name, value)
    if entry then
      table.insert(entries, entry)
    end
  end
  table.sort(entries, function(a, b)
    return a.name < b.name
  end)
  return entries
end

function M.get(name)
  name = tostring(name or ""):lower()
  for _, entry in ipairs(M.entries()) do
    if entry.name == name then
      return entry
    end
  end
  return nil, ("Unknown agent '%s'. Available registry names: %s"):format(name, table.concat(M.names(), ", "))
end

function M.names()
  local names = {}
  for _, entry in ipairs(M.entries()) do
    table.insert(names, entry.name)
  end
  return names
end

function M.complete(arg_lead)
  local matches = {}
  for _, name in ipairs(M.names()) do
    if vim.startswith(name, arg_lead) then
      table.insert(matches, name)
    end
  end
  return matches
end

return M
