local M = {}

function M.setup()
  local profile = require("nvim_cpp_ide.profile").resolve()
  vim.g.nvim_cpp_ide_profile = profile.name

  require("nvim_cpp_ide.core.options").setup(profile)

  local plugins_loaded = require("nvim_cpp_ide.plugins").setup(profile)
  require("nvim_cpp_ide.core.keymaps").setup(profile)

  if profile.cpp and plugins_loaded then
    require("nvim_cpp_ide.lsp").setup()
  end

  if profile.agent then
    require("nvim_cpp_ide.agent").setup(profile)
  end

  if vim.env.NVIM_CPP_IDE_QUIET ~= "1" then
    vim.schedule(function()
      vim.notify(
        ("nvim-cpp-ide loaded (profile: %s)"):format(profile.name),
        vim.log.levels.INFO
      )
    end)
  end
end

return M
