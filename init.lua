-- nvim-cpp-ide entry point (Neovim 0.11+)
-- The configuration is intentionally modular so editor, project and agent
-- concerns can evolve independently.

if vim.fn.has("nvim-0.11") ~= 1 then
  error("nvim-cpp-ide Lua configuration requires Neovim 0.11+")
end

-- When this file is executed directly (for example in CI with `-u ./init.lua`),
-- ensure sibling `lua/` modules are discoverable through runtimepath.
local source = debug.getinfo(1, "S").source
if source:sub(1, 1) == "@" then
  local config_root = vim.fn.fnamemodify(source:sub(2), ":p:h")
  vim.opt.runtimepath:prepend(config_root)
end

require("nvim_cpp_ide").setup()
