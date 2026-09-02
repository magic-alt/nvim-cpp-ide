local M = {}

local profiles = {
  minimal = {
    name = "minimal",
    cpp = false,
    agent = false,
  },
  cpp = {
    name = "cpp",
    cpp = true,
    agent = false,
  },
  agent = {
    name = "agent",
    cpp = true,
    agent = true,
  },
}

function M.resolve()
  local requested = vim.g.nvim_cpp_ide_profile
    or vim.env.NVIM_CPP_IDE_PROFILE
    or "cpp"

  requested = tostring(requested):lower()
  local profile = profiles[requested]
  if not profile then
    local valid = table.concat(vim.tbl_keys(profiles), ", ")
    error(("Unknown nvim-cpp-ide profile '%s'. Valid profiles: %s"):format(requested, valid))
  end

  return vim.deepcopy(profile)
end

return M
