local M = {}

local markers = {
  ".git",
  "CMakePresets.json",
  "CMakeLists.txt",
  "Makefile",
  "meson.build",
  "platformio.ini",
  "west.yml",
}

function M.get(bufnr)
  bufnr = bufnr or 0
  local name = vim.api.nvim_buf_get_name(bufnr)
  local start = name ~= "" and vim.fs.dirname(name) or vim.uv.cwd()
  return vim.fs.root(start, markers) or vim.uv.cwd()
end

return M
