local M = {}

local filename = ".nvim-cpp-ide.json"

function M.path(root)
  return vim.fs.joinpath(root, filename)
end

function M.load(root)
  local path = M.path(root)
  if vim.fn.filereadable(path) ~= 1 then
    return {}
  end

  local raw = table.concat(vim.fn.readfile(path), "\n")
  local ok, decoded = pcall(vim.json.decode, raw)
  if not ok or type(decoded) ~= "table" then
    error(("Invalid %s: %s"):format(path, ok and "expected a JSON object" or decoded))
  end

  return decoded
end

return M
