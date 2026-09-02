local M = {}

local function setup_single_file_build()
  vim.keymap.set("n", "<F9>", function()
    local ft = vim.bo.filetype
    if ft == "c" then
      vim.cmd("AsyncRun -save=2 gcc -O2 -std=c11 % -o %<")
    elseif ft == "cpp" then
      vim.cmd("AsyncRun -save=2 g++ -O2 -std=c++17 % -o %<")
    else
      vim.notify("No single-file build rule for " .. ft, vim.log.levels.WARN)
    end
  end, { desc = "Build current file" })

  vim.keymap.set("n", "<F4>", function()
    local root = vim.fn.expand("%:r")
    local is_win = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
    local exe_path

    if is_win then
      if vim.fn.filereadable(root .. ".exe") == 1 then
        exe_path = root .. ".exe"
      elseif vim.fn.filereadable(root) == 1 then
        exe_path = root
      end
    else
      if vim.fn.filereadable(root) == 1 then
        exe_path = "./" .. root
      elseif vim.fn.filereadable(root .. ".out") == 1 then
        exe_path = "./" .. root .. ".out"
      end
    end

    if exe_path then
      vim.cmd("AsyncRun " .. vim.fn.shellescape(exe_path))
    else
      vim.notify("Binary not found. Build first (F9).", vim.log.levels.WARN)
    end
  end, { desc = "Run compiled binary" })
end

function M.setup()
  local engine = require("nvim_cpp_ide.project.engine")
  engine.setup()

  vim.keymap.set("n", "<F6>", "<cmd>ProjectTest<cr>", { desc = "Project test" })
  vim.keymap.set("n", "<F7>", "<cmd>ProjectBuild<cr>", { desc = "Project build" })
  vim.keymap.set("n", "<F8>", "<cmd>ProjectConfigure<cr>", { desc = "Project configure" })
  vim.keymap.set("n", "<F10>", "<cmd>cwindow<cr>", { desc = "Toggle quickfix" })

  vim.keymap.set("n", "<leader>pi", "<cmd>ProjectInfo<cr>", { desc = "Project info" })
  vim.keymap.set("n", "<leader>pc", "<cmd>ProjectConfigure<cr>", { desc = "Project configure" })
  vim.keymap.set("n", "<leader>pb", "<cmd>ProjectBuild<cr>", { desc = "Project build" })
  vim.keymap.set("n", "<leader>pt", "<cmd>ProjectTest<cr>", { desc = "Project test" })
  vim.keymap.set("n", "<leader>pl", "<cmd>ProjectLint<cr>", { desc = "Project lint" })
  vim.keymap.set("n", "<leader>pf", "<cmd>ProjectFormat<cr>", { desc = "Project format" })

  setup_single_file_build()

  vim.api.nvim_create_user_command("ALEFix", function()
    local ok, conform = pcall(require, "conform")
    if ok then
      conform.format({ async = false, lsp_fallback = true })
    else
      vim.lsp.buf.format({ async = false })
    end
  end, { desc = "Format current buffer (ALEFix compatibility)" })
end

return M
