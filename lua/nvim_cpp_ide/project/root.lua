local M = {}

local markers = {
  ".nvim-cpp-ide.json",
  "CMakeUserPresets.json",
  "CMakePresets.json",
  "CMakeLists.txt",
  "build.ninja",
  "Makefile",
  "meson.build",
  "platformio.ini",
  "west.yml",
  ".git",
}

local function start_dir(bufnr)
  bufnr = bufnr or 0
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name ~= "" then
    return vim.fs.dirname(vim.fs.normalize(name))
  end
  return vim.uv.cwd()
end

function M.get(bufnr)
  local start = start_dir(bufnr)
  return vim.fs.root(start, markers) or vim.uv.cwd()
end

function M.markers()
  return vim.deepcopy(markers)
end

return M
