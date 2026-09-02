local M = {}

function M.setup(profile)
  vim.g.mapleader = " "
  vim.g.maplocalleader = " "

  vim.opt.number = true
  vim.opt.relativenumber = true
  vim.opt.cursorline = true
  vim.opt.termguicolors = true
  vim.opt.updatetime = 250
  vim.opt.signcolumn = "yes"
  vim.opt.hidden = true
  vim.opt.mouse = "a"
  vim.opt.splitright = true
  vim.opt.splitbelow = true
  vim.opt.clipboard = "unnamedplus"

  vim.opt.expandtab = true
  vim.opt.shiftwidth = 2
  vim.opt.tabstop = 2
  vim.opt.softtabstop = 2
  vim.opt.smartindent = true
  vim.opt.ignorecase = true
  vim.opt.smartcase = true
  vim.opt.incsearch = true
  vim.opt.hlsearch = true

  vim.opt.path:append("**")
  vim.opt.wildmenu = true

  if profile.agent then
    vim.opt.autoread = true
  end
end

return M
