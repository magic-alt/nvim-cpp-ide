local M = {}

local function bootstrap_lazy()
  local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
  if not vim.uv.fs_stat(lazypath) then
    local output = vim.fn.system({
      "git",
      "clone",
      "--filter=blob:none",
      "https://github.com/folke/lazy.nvim.git",
      "--branch=stable",
      lazypath,
    })

    if vim.v.shell_error ~= 0 then
      error("Failed to clone lazy.nvim:\n" .. output)
    end
  end

  vim.opt.runtimepath:prepend(lazypath)
end

function M.setup(profile)
  local spec = require("nvim_cpp_ide.plugins.spec").build(profile)

  if vim.env.NVIM_CPP_IDE_SKIP_PLUGINS == "1" then
    return false
  end

  bootstrap_lazy()
  local ok, lazy = pcall(require, "lazy")
  if not ok then
    error("Failed to load lazy.nvim")
  end

  lazy.setup(spec, {
    ui = { border = "rounded" },
    performance = {
      rtp = {
        disabled_plugins = {
          "gzip",
          "tarPlugin",
          "tohtml",
          "tutor",
          "zipPlugin",
        },
      },
    },
  })

  return true
end

return M
