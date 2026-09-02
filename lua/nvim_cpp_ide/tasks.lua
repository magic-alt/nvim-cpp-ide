local M = {}

function M.setup()
  vim.g.asyncrun_open = 6

  vim.keymap.set("n", "<F7>", "<cmd>AsyncRun -save=2 make<cr>", { desc = "Make" })
  vim.keymap.set("n", "<F8>", "<cmd>AsyncRun -save=2 make run<cr>", { desc = "Make run" })
  vim.keymap.set("n", "<F6>", "<cmd>AsyncRun -save=2 make test<cr>", { desc = "Make test" })
  vim.keymap.set("n", "<F10>", "<cmd>cwindow<cr>", { desc = "Toggle quickfix" })

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
