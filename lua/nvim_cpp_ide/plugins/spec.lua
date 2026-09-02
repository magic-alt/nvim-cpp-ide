local M = {}

local function base_plugins()
  return {
    {
      "tomasr/molokai",
      lazy = false,
      priority = 1000,
      config = function()
        vim.cmd.colorscheme("molokai")
      end,
    },
    {
      "nvim-tree/nvim-tree.lua",
      dependencies = { "nvim-tree/nvim-web-devicons" },
      keys = {
        { "<C-n>", "<cmd>NvimTreeToggle<cr>", desc = "Toggle file tree" },
        { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Toggle file tree" },
        { "<leader>f", "<cmd>NvimTreeFindFile<cr>", desc = "Find current file" },
      },
      config = function()
        vim.g.loaded_netrw = 1
        vim.g.loaded_netrwPlugin = 1
        require("nvim-tree").setup({
          view = { width = 32 },
          renderer = { group_empty = true },
          filters = { dotfiles = false },
          git = { enable = true, ignore = false },
        })
        vim.api.nvim_create_user_command("NERDTreeToggle", "NvimTreeToggle", {})
        vim.api.nvim_create_user_command("NERDTreeFind", "NvimTreeFindFile", {})
      end,
    },
    {
      "nvim-lualine/lualine.nvim",
      dependencies = { "nvim-tree/nvim-web-devicons" },
      opts = { options = { theme = "auto" } },
    },
    {
      "folke/which-key.nvim",
      event = "VeryLazy",
      opts = {},
    },
    {
      "lewis6991/gitsigns.nvim",
      event = { "BufReadPre", "BufNewFile" },
      opts = {
        current_line_blame = true,
        on_attach = function(bufnr)
          local gs = require("gitsigns")
          local function bmap(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
          end
          bmap("n", "]g", gs.next_hunk, "Git next hunk")
          bmap("n", "[g", gs.prev_hunk, "Git previous hunk")
          bmap("n", "<leader>hs", gs.stage_hunk, "Stage hunk")
          bmap("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
          bmap("n", "<leader>hp", gs.preview_hunk, "Preview hunk")
        end,
      },
    },
    {
      "nvim-telescope/telescope.nvim",
      branch = "0.1.x",
      dependencies = { "nvim-lua/plenary.nvim" },
      keys = {
        { "<leader>ff", function() require("telescope.builtin").find_files() end, desc = "Find files" },
        { "<leader>fg", function() require("telescope.builtin").live_grep() end, desc = "Live grep" },
        { "<leader>fb", function() require("telescope.builtin").buffers() end, desc = "Buffers" },
        { "<leader>fh", function() require("telescope.builtin").help_tags() end, desc = "Help" },
        { "<leader>fo", function() require("telescope.builtin").oldfiles() end, desc = "Recent files" },
      },
      opts = {
        defaults = {
          mappings = { i = { ["<C-u>"] = false, ["<C-d>"] = false } },
        },
      },
    },
    {
      "nvim-treesitter/nvim-treesitter",
      branch = "master",
      build = ":TSUpdate",
      event = { "BufReadPost", "BufNewFile" },
      dependencies = {
        { "nvim-treesitter/nvim-treesitter-textobjects", branch = "master" },
      },
      opts = {
        ensure_installed = { "c", "cpp", "lua", "vim", "vimdoc", "query", "python", "bash" },
        auto_install = true,
        highlight = { enable = true, additional_vim_regex_highlighting = false },
        indent = { enable = true },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<C-space>",
            node_incremental = "<C-space>",
            scope_incremental = false,
            node_decremental = "<bs>",
          },
        },
      },
      config = function(_, opts)
        require("nvim-treesitter.configs").setup(opts)
      end,
    },
    {
      "numToStr/Comment.nvim",
      event = { "BufReadPre", "BufNewFile" },
      opts = {},
    },
  }
end

local function cpp_plugins()
  return {
    {
      "williamboman/mason.nvim",
      build = ":MasonUpdate",
      opts = {
        ui = {
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
          },
        },
      },
    },
    {
      "hrsh7th/nvim-cmp",
      event = "InsertEnter",
      dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "L3MON4D3/LuaSnip",
        "saadparwaiz1/cmp_luasnip",
        "rafamadriz/friendly-snippets",
      },
      config = function()
        require("nvim_cpp_ide.lsp").setup_completion()
      end,
    },
    {
      "stevearc/conform.nvim",
      event = "BufWritePre",
      keys = {
        {
          "<leader>lf",
          function()
            require("conform").format({ async = true, lsp_fallback = true })
          end,
          mode = { "n", "v" },
          desc = "Format buffer",
        },
      },
      opts = {
        formatters_by_ft = {
          c = { "clang_format" },
          cpp = { "clang_format" },
          lua = { "stylua" },
          python = { "black" },
        },
        format_on_save = nil,
      },
    },
    { "skywind3000/asyncrun.vim", lazy = false },
  }
end

function M.build(profile)
  local spec = base_plugins()
  if profile.cpp then
    vim.list_extend(spec, cpp_plugins())
  end
  return spec
end

return M
