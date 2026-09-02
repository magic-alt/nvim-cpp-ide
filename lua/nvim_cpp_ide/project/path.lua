local M = {}

function M.is_absolute(value)
  if type(value) ~= "string" or value == "" then
    return false
  end
  return value:sub(1, 1) == "/"
    or value:match("^%a:[/\\]") ~= nil
    or value:sub(1, 2) == "\\\\"
end

function M.resolve(root, value)
  if M.is_absolute(value) then
    return vim.fs.normalize(value)
  end
  return vim.fs.normalize(vim.fs.joinpath(root, value))
end

return M
