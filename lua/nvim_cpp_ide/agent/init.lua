local M = {}

local function setup_external_change_detection()
  local group = vim.api.nvim_create_augroup("nvim_cpp_ide_agent_files", { clear = true })
  vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
    group = group,
    desc = "Notice files changed by external coding agents",
    callback = function(args)
      if vim.bo[args.buf].buftype == "" and not vim.bo[args.buf].modified then
        vim.cmd("silent! checktime")
      end
    end,
  })
end

local function setup_commands(profile)
  vim.api.nvim_create_user_command("AgentProfileInfo", function()
    local root = require("nvim_cpp_ide.project.root").get(0)
    vim.notify(("profile=%s\nproject=%s"):format(profile.name, root), vim.log.levels.INFO)
  end, { desc = "Show agent profile and project root" })

  vim.api.nvim_create_user_command("AgentTerminal", function(opts)
    local root = require("nvim_cpp_ide.project.root").get(0)
    local command = opts.args ~= "" and opts.args or vim.o.shell

    vim.cmd("botright 14split")
    vim.cmd("enew")
    vim.fn.jobstart(command, {
      cwd = root,
      term = true,
    })
    vim.cmd("startinsert")
  end, {
    nargs = "*",
    desc = "Open a provider-neutral terminal at the project root",
  })
end

function M.setup(profile)
  setup_external_change_detection()
  setup_commands(profile)
end

return M
