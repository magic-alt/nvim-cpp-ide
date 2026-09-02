local generator = require("nvim_cpp_ide.agent.generator")
local registry = require("nvim_cpp_ide.agent.registry")

local M = {}

local function is_headless()
  return #vim.api.nvim_list_uis() == 0
end

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

local function open_terminal(argv, root)
  if is_headless() then
    return nil, "Agent terminals require an attached Neovim UI"
  end

  vim.cmd("botright 14split")
  vim.cmd("enew")
  local job = vim.fn.jobstart(argv, {
    cwd = root,
    term = true,
  })
  if job <= 0 then
    vim.cmd("close")
    return nil, ("Failed to start terminal job at %s"):format(root)
  end
  vim.cmd("startinsert")
  return job
end

local function agent_snapshot()
  local result = {}
  for _, entry in ipairs(registry.entries()) do
    table.insert(result, {
      name = entry.name,
      label = entry.label,
      argv = entry.argv,
      available = entry.available,
    })
  end
  return result
end

local function report_error(message, exit_code)
  if is_headless() then
    io.stderr:write(message .. "\n")
    if exit_code then
      vim.cmd("cquit " .. exit_code)
    end
  else
    vim.notify(message, vim.log.levels.ERROR)
  end
end

local function setup_commands(profile)
  vim.api.nvim_create_user_command("AgentProfileInfo", function()
    local project = require("nvim_cpp_ide.project.engine").info()
    local info = {
      profile = profile.name,
      project = project,
      agents = agent_snapshot(),
    }
    if is_headless() then
      print(vim.json.encode(info))
    else
      vim.notify(vim.inspect(info), vim.log.levels.INFO, { title = "Agent Profile" })
    end
  end, { desc = "Show agent profile, project contract, and CLI registry" })

  vim.api.nvim_create_user_command("AgentInit", function(opts)
    local ok, result = pcall(generator.run, { force = opts.bang })
    if not ok then
      report_error(result, is_headless() and 2 or nil)
      return
    end

    if is_headless() then
      print(vim.json.encode(result))
    else
      local agents_state = result.agents_created and "created"
        or (result.agents_updated and "regenerated" or "preserved")
      local bridge_state = result.claude_created and "created"
        or (result.claude_updated and "updated" or "already linked")
      vim.notify(
        ("AGENTS.md: %s\nCLAUDE.md: %s"):format(agents_state, bridge_state),
        vim.log.levels.INFO,
        { title = "Agent Foundation" }
      )
    end
  end, {
    bang = true,
    desc = "Create/preserve AGENTS.md and ensure the CLAUDE.md bridge; use ! to regenerate AGENTS.md",
  })

  vim.api.nvim_create_user_command("AgentList", function()
    local agents = agent_snapshot()
    if is_headless() then
      print(vim.json.encode(agents))
    else
      vim.notify(vim.inspect(agents), vim.log.levels.INFO, { title = "Agent Registry" })
    end
  end, { desc = "List registered coding-agent CLIs and availability" })

  vim.api.nvim_create_user_command("AgentTerminal", function(opts)
    local root = require("nvim_cpp_ide.project.root").get(0)
    local command = #opts.fargs > 0 and opts.fargs or vim.o.shell
    local _, err = open_terminal(command, root)
    if err then
      report_error(err)
    end
  end, {
    nargs = "*",
    desc = "Open a provider-neutral terminal at the project root",
  })

  vim.api.nvim_create_user_command("Agent", function(opts)
    local name = opts.fargs[1]
    local entry, err = registry.get(name)
    if not entry then
      report_error(err)
      return
    end
    if not entry.available then
      report_error(("Agent '%s' is registered but executable '%s' was not found in PATH"):format(name, entry.argv[1]))
      return
    end

    local argv = vim.deepcopy(entry.argv)
    for i = 2, #opts.fargs do
      table.insert(argv, opts.fargs[i])
    end

    local root = require("nvim_cpp_ide.project.root").get(0)
    local _, start_err = open_terminal(argv, root)
    if start_err then
      report_error(start_err)
    end
  end, {
    nargs = "+",
    complete = function(arg_lead, cmd_line)
      local args = cmd_line:match("^%S+%s+(.*)$") or ""
      if args:find("%s") then
        return {}
      end
      return registry.complete(arg_lead)
    end,
    desc = "Launch a registered coding-agent CLI at the project root",
  })
end

function M.setup(profile)
  setup_external_change_detection()
  setup_commands(profile)
end

return M
