local M = {}

function M.setup(profile)
  vim.keymap.set("n", "<leader>tn", "<cmd>tabnew<cr>", { desc = "New tab", silent = true })
  vim.keymap.set("n", "<leader>tc", "<cmd>tabclose<cr>", { desc = "Close tab", silent = true })
  vim.keymap.set("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit", silent = true })

  vim.keymap.set("i", "fj", "<Esc>", { desc = "Exit insert mode" })
  vim.keymap.set("i", "vv", "<Esc>", { desc = "Exit insert mode" })
  vim.keymap.set("n", "<C-A>", "ggVG", { desc = "Select all" })
  vim.keymap.set("n", "<leader>k", "<cmd>g/^$/d<cr>", { desc = "Delete blank lines" })

  vim.keymap.set("n", "<leader>cc", function()
    return vim.v.count == 0
        and "<Plug>(comment_toggle_linewise_current)"
      or "<Plug>(comment_toggle_linewise_count)"
  end, { expr = true, desc = "Toggle comment" })
  vim.keymap.set("v", "<leader>cc", "<Plug>(comment_toggle_linewise_visual)", { desc = "Toggle comment" })

  if profile.cpp then
    require("nvim_cpp_ide.tasks").setup()
  end

  vim.api.nvim_create_autocmd("TextYankPost", {
    desc = "Highlight yanked text",
    group = vim.api.nvim_create_augroup("nvim_cpp_ide_highlight_yank", { clear = true }),
    callback = function()
      vim.highlight.on_yank()
    end,
  })
end

return M
