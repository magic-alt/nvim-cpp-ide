local generator = require("nvim_cpp_ide.agent.generator")
local registry = require("nvim_cpp_ide.agent.registry")
local context = require("nvim_cpp_ide.agent.context")
local conflicts = require("nvim_cpp_ide.agent.conflicts")
local review = require("nvim_cpp_ide.agent.review")

local M = {}

local function is_headless()
  return #vim.api.nvim_list_uis() == 0
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
    io.stderr:write(tostring(message) .. "\n")
    if exit_code then
      vim.cmd("cquit " .. exit_code)
    end
  else
    vim.notify(tostring(message), vim.log.levels.ERROR)
  end
end

local function report_warning(message)
  if is_headless() then
    io.stderr:write(tostring(message) .. "\n")
  else
    vim.notify(tostring(message), vim.log.levels.WARN)
  end
end

local function report_result(title, result)
  if is_headless() then
    print(vim.json.encode(result))
  else
    vim.notify(vim.inspect(result), vim.log.levels.INFO, { title = title })
  end
end

local function export_context()
  local ok, result = pcall(context.write)
  if not ok then
    return nil, result
  end
  return result
end

local function target_arg(opts)
  return opts.args ~= "" and opts.args or nil
end

local function run_review_mutation(title, fn, target)
  local result, err = fn(target)
  if not result then
    report_error(err, is_headless() and 2 or nil)
    return
  end
  report_result(title, result)
end

local function run_hunk(title, fn)
  local ok, err = fn()
  if not ok then
    report_error(err, is_headless() and 2 or nil)
    return
  end
  if not is_headless() then
    vim.notify(title, vim.log.levels.INFO, { title = "Agent Review" })
  end
end

local function setup_commands(profile)
  vim.api.nvim_create_user_command("AgentProfileInfo", function()
    local project = require("nvim_cpp_ide.project.engine").info()
    local root = require("nvim_cpp_ide.project.root").get(0)
    local paths = context.paths(root)
    local info = {
      profile = profile.name,
      project = project,
      agents = agent_snapshot(),
      conflicts = conflicts.snapshot(),
      review = review.snapshot(root),
      context = {
        json = ".nvim-agent/context.json",
        markdown = ".nvim-agent/context.md",
        exists = vim.fn.filereadable(paths.json) == 1 and vim.fn.filereadable(paths.markdown) == 1,
      },
    }
    report_result("Agent Profile", info)
  end, { desc = "Show agent profile, project contract, conflicts, review state, CLI registry, and context snapshot" })

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

  vim.api.nvim_create_user_command("AgentContext", function()
    local result, err = export_context()
    if not result then
      report_error(err, is_headless() and 2 or nil)
      return
    end

    local summary = {
      json = result.json_relative,
      markdown = result.markdown_relative,
      diagnostics = result.snapshot.diagnostics.count,
      git_dirty = result.snapshot.git.dirty,
      current_file = result.snapshot.current.file,
      conflicts = result.snapshot.external_changes and result.snapshot.external_changes.count or 0,
      pending_review = result.snapshot.review and result.snapshot.review.pending_count or 0,
    }
    if is_headless() then
      print(vim.json.encode(summary))
    else
      vim.notify(
        ("Updated %s\nUpdated %s"):format(result.json_relative, result.markdown_relative),
        vim.log.levels.INFO,
        { title = "Agent Context" }
      )
    end
  end, { desc = "Export Neovim runtime state to .nvim-agent/context.json and context.md" })

  vim.api.nvim_create_user_command("AgentContextOpen", function()
    if is_headless() then
      report_error("AgentContextOpen requires an attached Neovim UI", 2)
      return
    end
    local result, err = export_context()
    if not result then
      report_error(err)
      return
    end
    vim.cmd("edit " .. vim.fn.fnameescape(result.markdown_path))
  end, { desc = "Refresh and open the human-readable agent context snapshot" })

  vim.api.nvim_create_user_command("AgentContextPrint", function()
    local ok, snapshot = pcall(context.collect)
    if not ok then
      report_error(snapshot, is_headless() and 2 or nil)
      return
    end
    report_result("Agent Context", snapshot)
  end, { desc = "Print the current agent context snapshot without writing files" })

  vim.api.nvim_create_user_command("AgentConflicts", function()
    local root = require("nvim_cpp_ide.project.root").get(0)
    local snapshot = conflicts.snapshot()
    if is_headless() then
      print(vim.json.encode(snapshot))
      return
    end

    local items = {}
    for _, item in ipairs(snapshot.items) do
      table.insert(items, {
        filename = vim.fs.joinpath(root, item.file),
        lnum = 1,
        col = 1,
        text = ("[%s] %s"):format(item.reason, item.file),
      })
    end
    vim.fn.setqflist({}, " ", { title = "Agent file conflicts", items = items })
    if #items > 0 then
      vim.cmd("copen")
    else
      vim.notify("No external-file conflicts", vim.log.levels.INFO, { title = "Agent File Conflict" })
    end
  end, { desc = "List unsaved-buffer conflicts caused by external file changes" })

  vim.api.nvim_create_user_command("AgentConflictDiff", function(opts)
    local result, err = conflicts.open_diff(target_arg(opts))
    if not result then
      report_error(err, is_headless() and 2 or nil)
    end
  end, { nargs = "?", complete = "file", desc = "Compare unsaved buffer content with the external disk version" })

  vim.api.nvim_create_user_command("AgentConflictKeep", function(opts)
    run_review_mutation("Agent File Conflict", conflicts.keep, target_arg(opts))
  end, { nargs = "?", complete = "file", desc = "Keep the local unsaved buffer and acknowledge the current disk version" })

  vim.api.nvim_create_user_command("AgentConflictUseDisk", function(opts)
    run_review_mutation("Agent File Conflict", conflicts.use_disk, target_arg(opts))
  end, { nargs = "?", complete = "file", desc = "Back up the local buffer and replace it with the external disk version" })

  vim.api.nvim_create_user_command("AgentChanges", function()
    local snapshot, err = review.populate_changes()
    if not snapshot then
      report_error(err, is_headless() and 2 or nil)
      return
    end
    if is_headless() then
      print(vim.json.encode(snapshot))
    elseif snapshot.changed_count == 0 then
      vim.notify("No Git changes to review", vim.log.levels.INFO, { title = "Agent Review" })
    end
  end, { desc = "List pending and accepted Git changes for agent review" })

  vim.api.nvim_create_user_command("AgentDiff", function(opts)
    local target = target_arg(opts)
    if is_headless() then
      local text, err = review.diff_text(target, { staged = false })
      if not text then
        report_error(err, 2)
        return
      end
      io.stdout:write(text .. (vim.endswith(text, "\n") and "" or "\n"))
    else
      local result, err = review.open_diff(target, { staged = false })
      if not result then
        report_error(err)
      end
    end
  end, { nargs = "?", complete = "file", desc = "Review pending working-tree changes against the accepted index" })

  vim.api.nvim_create_user_command("AgentDiffStaged", function(opts)
    local target = target_arg(opts)
    if is_headless() then
      local text, err = review.diff_text(target, { staged = true })
      if not text then
        report_error(err, 2)
        return
      end
      io.stdout:write(text .. (vim.endswith(text, "\n") and "" or "\n"))
    else
      local result, err = review.open_diff(target, { staged = true })
      if not result then
        report_error(err)
      end
    end
  end, { nargs = "?", complete = "file", desc = "Review accepted staged changes against HEAD" })

  vim.api.nvim_create_user_command("AgentAccept", function(opts)
    run_review_mutation("Agent Review", review.accept, target_arg(opts))
  end, { nargs = "?", complete = "file", desc = "Accept a file by staging its current working-tree state" })

  vim.api.nvim_create_user_command("AgentKeep", function(opts)
    run_review_mutation("Agent Review", review.keep, target_arg(opts))
  end, { nargs = "?", complete = "file", desc = "Keep a file pending without changing its Git state" })

  vim.api.nvim_create_user_command("AgentRevert", function(opts)
    run_review_mutation("Agent Review", review.revert, target_arg(opts))
  end, { nargs = "?", complete = "file", desc = "Back up and revert pending working-tree changes to the accepted index" })

  vim.api.nvim_create_user_command("AgentUnaccept", function(opts)
    run_review_mutation("Agent Review", review.unaccept, target_arg(opts))
  end, { nargs = "?", complete = "file", desc = "Move an accepted staged file back to pending review" })

  vim.api.nvim_create_user_command("AgentNextHunk", function()
    run_hunk("Moved to next agent-change hunk", review.next_hunk)
  end, { desc = "Move to the next pending diff hunk" })

  vim.api.nvim_create_user_command("AgentPrevHunk", function()
    run_hunk("Moved to previous agent-change hunk", review.prev_hunk)
  end, { desc = "Move to the previous pending diff hunk" })

  vim.api.nvim_create_user_command("AgentAcceptHunk", function()
    run_hunk("Accepted current hunk", review.accept_hunk)
  end, { desc = "Accept the current hunk through gitsigns staging" })

  vim.api.nvim_create_user_command("AgentKeepHunk", function()
    run_hunk("Kept current hunk pending", review.keep_hunk)
  end, { desc = "Keep the current hunk pending and move to the next hunk" })

  vim.api.nvim_create_user_command("AgentRevertHunk", function()
    run_hunk("Reverted current hunk", review.revert_hunk)
  end, { desc = "Revert the current pending hunk through gitsigns" })

  vim.api.nvim_create_user_command("AgentList", function()
    report_result("Agent Registry", agent_snapshot())
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

    local context_result, context_err = export_context()
    if not context_result then
      report_warning("Agent context export failed; launching CLI without refreshed snapshot: " .. tostring(context_err))
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
    desc = "Refresh context and launch a registered coding-agent CLI at the project root",
  })
end

local function setup_keymaps()
  local map = function(lhs, command, desc)
    vim.keymap.set("n", lhs, "<cmd>" .. command .. "<cr>", { desc = desc, silent = true })
  end
  map("<leader>ac", "AgentChanges", "Agent changes")
  map("<leader>ad", "AgentDiff", "Agent pending diff")
  map("<leader>aD", "AgentDiffStaged", "Agent accepted diff")
  map("<leader>ax", "AgentConflicts", "Agent file conflicts")
  map("]a", "AgentNextHunk", "Agent next hunk")
  map("[a", "AgentPrevHunk", "Agent previous hunk")
  map("<leader>aa", "AgentAcceptHunk", "Agent accept hunk")
  map("<leader>ak", "AgentKeepHunk", "Agent keep hunk")
  map("<leader>ar", "AgentRevertHunk", "Agent revert hunk")
end

function M.setup(profile)
  conflicts.setup()
  setup_commands(profile)
  setup_keymaps()
end

return M
