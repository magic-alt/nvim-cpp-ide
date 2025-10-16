-- init.lua — 最小替换：从 Vim 插件过渡到 Neovim/Lua 生态
-- 目标：保持常用按键/用法不变或提供兼容封装，减少软冲突
-- 替换：YCM/ALE/NERDTree/airline → LSP+nvim-cmp+conform、nvim-tree、lualine
-- 保留：AsyncRun、Telescope、gitsigns；新增：nvim-treesitter、which-key (Lua)

------------------------------------------------------------
-- 0) 基础选项（保持你现有习惯，可按需合并）
------------------------------------------------------------
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- 基本设置（从 config.vim 迁移）
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

-- 缩进和搜索
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.smartindent = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.hlsearch = true

-- 路径设置
vim.opt.path:append("**")
vim.opt.wildmenu = true

------------------------------------------------------------
-- 1) 引导 lazy.nvim（推荐 Neovim 0.9+）
------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  print("Installing lazy.nvim plugin manager...")
  print("This may take a minute on first launch...")
  local output = vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath
  })
  
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_err_writeln("Failed to clone lazy.nvim!")
    vim.api.nvim_err_writeln("Please check your Git installation and internet connection.")
    vim.api.nvim_err_writeln("Error output: " .. output)
    return
  end
  
  print("lazy.nvim installed successfully!")
  print("Neovim will now install plugins. Please wait...")
end
vim.opt.rtp:prepend(lazypath)

------------------------------------------------------------
-- 2) 插件声明（最小替换集合）
------------------------------------------------------------
local lazy_ok, lazy = pcall(require, "lazy")
if not lazy_ok then
  vim.api.nvim_err_writeln("Failed to load lazy.nvim!")
  vim.api.nvim_err_writeln("Please restart Neovim or run: :lua vim.fn.delete(vim.fn.stdpath('data') .. '/lazy', 'rf')")
  return
end

lazy.setup({
  -- 配色方案（保持 molokai 风格）
  {
    "tomasr/molokai",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd([[colorscheme molokai]])
    end,
  },

  -- 文件树（替换 NERDTree）
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<C-n>", "<cmd>NvimTreeToggle<cr>", desc = "Toggle file tree (NERDTree 习惯)" },
      { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Toggle file tree" },
      { "<leader>f", "<cmd>NvimTreeFindFile<cr>", desc = "Find current file in tree" },
    },
    config = function()
      -- 禁用 netrw（避免冲突）
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1

      require("nvim-tree").setup({
        view = { width = 32 },
        renderer = { 
          group_empty = true,
          icons = {
            show = {
              file = true,
              folder = true,
              folder_arrow = true,
              git = true,
            },
          },
        },
        filters = { dotfiles = false },
        git = { enable = true, ignore = false },
      })
      
      -- 兼容：提供 :NERDTreeToggle 命令别名
      vim.api.nvim_create_user_command("NERDTreeToggle", function()
        vim.cmd("NvimTreeToggle")
      end, {})
      vim.api.nvim_create_user_command("NERDTreeFind", function()
        vim.cmd("NvimTreeFindFile")
      end, {})
    end,
  },

  -- 状态栏（替换 vim-airline）
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({ 
        options = { 
          theme = "auto",
          component_separators = { left = '|', right = '|'},
          section_separators = { left = '', right = ''},
        },
        sections = {
          lualine_a = {'mode'},
          lualine_b = {'branch', 'diff', 'diagnostics'},
          lualine_c = {'filename'},
          lualine_x = {'encoding', 'fileformat', 'filetype'},
          lualine_y = {'progress'},
          lualine_z = {'location'}
        },
      })
    end,
  },

  -- which-key（Lua 版）
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      require("which-key").setup({
        plugins = { spelling = true },
      })
    end,
  },

  -- Git 增强（保留）
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      current_line_blame = true,
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        local map = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end
        map("n", "]g", gs.next_hunk, "[g]it next hunk")
        map("n", "[g", gs.prev_hunk, "[g]it prev hunk")
        map("n", "<leader>hs", gs.stage_hunk, "[h]unk [s]tage")
        map("n", "<leader>hr", gs.reset_hunk, "[h]unk [r]eset")
        map("n", "<leader>hp", gs.preview_hunk, "[h]unk [p]review")
      end,
    },
  },

  -- Telescope（保留）
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ff", function() require("telescope.builtin").find_files() end, desc = "Find files" },
      { "<leader>fg", function() require("telescope.builtin").live_grep() end,  desc = "Live grep" },
      { "<leader>fb", function() require("telescope.builtin").buffers() end,    desc = "Buffers" },
      { "<leader>fh", function() require("telescope.builtin").help_tags() end,  desc = "Help" },
      { "<leader>fo", function() require("telescope.builtin").oldfiles() end,   desc = "Recent files" },
    },
    config = function()
      require("telescope").setup({
        defaults = {
          mappings = {
            i = {
              ["<C-u>"] = false,
              ["<C-d>"] = false,
            },
          },
        },
      })
    end,
  },

  -- Treesitter（替代 vim-cpp-modern 的主力高亮）
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    opts = {
      ensure_installed = { "c", "cpp", "lua", "vim", "vimdoc", "query", "python", "bash" },
      auto_install = true,
      highlight = { 
        enable = true,
        additional_vim_regex_highlighting = false,
      },
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

  -- LSP 基座（替换 YCM/ALE 的补全/诊断职责）
  { "neovim/nvim-lspconfig" },
  { 
    "williamboman/mason.nvim", 
    build = ":MasonUpdate",
    config = function()
      require("mason").setup({
        ui = {
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗"
          }
        }
      })
    end,
  },
  { 
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({ 
        ensure_installed = { "clangd", "lua_ls" },
        automatic_installation = true,
      })
    end,
  },

  -- nvim-cmp 补全栈
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
  },

  -- 格式化（替代 ALE 的大部分 fixers）
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
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
        c   = { "clang_format" },
        cpp = { "clang_format" },
        lua = { "stylua" },
        python = { "black" },
      },
      format_on_save = nil, -- 禁用自动保存格式化，手动触发
    },
  },

  -- AsyncRun（保留原有工作流）
  { "skywind3000/asyncrun.vim" },

  -- 注释插件（替代 vim-commentary）
  {
    "numToStr/Comment.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("Comment").setup()
    end,
  },
}, {
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

------------------------------------------------------------
-- 3) LSP / 补全 / 诊断：尽量贴近原有快捷键
------------------------------------------------------------

-- nvim-cmp 基本配置（<C-Space> 手动补全，回车确认）
local cmp = require("cmp")
local luasnip = require("luasnip")
require("luasnip.loaders.from_vscode").lazy_load()

cmp.setup({
  snippet = {
    expand = function(args) 
      luasnip.lsp_expand(args.body) 
    end,
  },
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-e>"] = cmp.mapping.abort(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then 
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then 
        luasnip.expand_or_jump()
      else 
        fallback() 
      end
    end, { "i", "s" }),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then 
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then 
        luasnip.jump(-1)
      else 
        fallback() 
      end
    end, { "i", "s" }),
    ["<Down>"] = cmp.mapping.select_next_item(),
    ["<Up>"] = cmp.mapping.select_prev_item(),
  }),
  sources = cmp.config.sources({
    { name = "nvim_lsp", priority = 1000 },
    { name = "luasnip", priority = 750 },
    { name = "path", priority = 500 },
    { name = "buffer", priority = 250 },
  }),
  formatting = {
    format = function(entry, vim_item)
      vim_item.menu = ({
        nvim_lsp = "[LSP]",
        luasnip = "[Snip]",
        buffer = "[Buf]",
        path = "[Path]",
      })[entry.source.name]
      return vim_item
    end,
  },
})

-- LSP 服务器配置
local lspconfig = require("lspconfig")
local capabilities = require("cmp_nvim_lsp").default_capabilities()

-- 统一 on_attach：绑定常用按键（接近 ALE/YCM 习惯）
local on_attach = function(client, bufnr)
  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
  end
  
  -- LSP 功能键位
  map("n", "gd", vim.lsp.buf.definition, "Go to definition")
  map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
  map("n", "gr", vim.lsp.buf.references, "References")
  map("n", "gi", vim.lsp.buf.implementation, "Implementation")
  map("n", "gt", vim.lsp.buf.type_definition, "Type definition")
  map("n", "K", vim.lsp.buf.hover, "Hover documentation")
  map("n", "<C-k>", vim.lsp.buf.signature_help, "Signature help")
  map("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
  map({"n","v"}, "<leader>ca", vim.lsp.buf.code_action, "Code action")
  map({"n","v"}, "<leader>lf", function() 
    vim.lsp.buf.format({ async = false }) 
  end, "Format (like ALEFix)")
  
  -- 诊断导航：模拟 ALE 的 [e / ]e
  map("n", "[e", vim.diagnostic.goto_prev, "Prev diagnostic")
  map("n", "]e", vim.diagnostic.goto_next, "Next diagnostic")
  map("n", "[d", vim.diagnostic.goto_prev, "Prev diagnostic")
  map("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
  map("n", "<leader>e", vim.diagnostic.open_float, "Line diagnostics")
  map("n", "<leader>q", vim.diagnostic.setloclist, "Quickfix diagnostics")
end

-- 配置 clangd（C/C++）
lspconfig.clangd.setup({ 
  capabilities = capabilities, 
  on_attach = on_attach,
  cmd = {
    "clangd",
    "--background-index",
    "--clang-tidy",
    "--header-insertion=iwyu",
    "--completion-style=detailed",
    "--function-arg-placeholders",
  },
  filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
})

-- 配置 lua_ls（Lua）
lspconfig.lua_ls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
  settings = { 
    Lua = { 
      diagnostics = { 
        globals = { "vim" } 
      },
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
        checkThirdParty = false,
      },
      telemetry = { enable = false },
    } 
  },
})

-- 诊断符号配置（类似 ALE 的错误标记）
vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  update_in_insert = false,
  underline = true,
  severity_sort = true,
  float = {
    border = "rounded",
    source = "always",
    header = "",
    prefix = "",
  },
})

local signs = { Error = "✘", Warn = "▲", Hint = "⚑", Info = "»" }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

------------------------------------------------------------
-- 4) 其他兼容与小功能
------------------------------------------------------------

-- AsyncRun 快捷键配置（保持原有习惯）
vim.g.asyncrun_open = 6

vim.keymap.set("n", "<F7>", ":AsyncRun -save=2 make<CR>", { desc = "Make" })
vim.keymap.set("n", "<F8>", ":AsyncRun -save=2 make run<CR>", { desc = "Make run" })
vim.keymap.set("n", "<F6>", ":AsyncRun -save=2 make test<CR>", { desc = "Make test" })
vim.keymap.set("n", "<F10>", ":cwindow<CR>", { desc = "Toggle quickfix" })

-- F9: 单文件编译
vim.keymap.set("n", "<F9>", function()
  local ft = vim.bo.filetype
  if ft == "c" then
    vim.cmd("AsyncRun -save=2 gcc -O2 -std=c11 % -o %<")
  elseif ft == "cpp" then
    vim.cmd("AsyncRun -save=2 g++ -O2 -std=c++17 % -o %<")
  else
    print("No single-file build rule for " .. ft)
  end
end, { desc = "Build current file" })

-- F4: 运行当前二进制
vim.keymap.set("n", "<F4>", function()
  local binary = vim.fn.expand("%:r")
  if vim.fn.filereadable(binary) == 1 then
    vim.cmd("AsyncRun " .. binary)
  else
    print("Binary not found. Build first (F9).")
  end
end, { desc = "Run current binary" })

-- 兼容命令：用 conform.nvim 模拟 :ALEFix
vim.api.nvim_create_user_command("ALEFix", function()
  require("conform").format({ async = false, lsp_fallback = true })
end, { desc = "Format current buffer (ALEFix compatibility)" })

-- Tab/Window 管理（保持原有键位）
vim.keymap.set("n", "<leader>tn", ":tabnew<CR>", { desc = "New tab" })
vim.keymap.set("n", "<leader>tc", ":tabclose<CR>", { desc = "Close tab" })
vim.keymap.set("n", "<leader>q", ":q<CR>", { desc = "Quit" })

-- 快速编辑助手（保持原有习惯）
vim.keymap.set("i", "fj", "<Esc>", { desc = "Exit insert mode" })
vim.keymap.set("i", "vv", "<Esc>", { desc = "Exit insert mode" })
vim.keymap.set("n", "<C-A>", "ggVG", { desc = "Select all" })
vim.keymap.set("n", "<leader>k", ":g/^$/d<CR>", { desc = "Delete blank lines" })

-- 注释键位（兼容 vim-commentary 习惯）
vim.keymap.set("n", "<leader>cc", function()
  return vim.v.count == 0 and "<Plug>(comment_toggle_linewise_current)" or "<Plug>(comment_toggle_linewise_count)"
end, { expr = true, desc = "Toggle comment" })
vim.keymap.set("v", "<leader>cc", "<Plug>(comment_toggle_linewise_visual)", { desc = "Toggle comment" })

-- MagicInstall 命令（Lua 版本）
vim.api.nvim_create_user_command("MagicInstall", function()
  local src = vim.fn.expand("%:p")
  if vim.fn.filereadable(src) == 0 then
    vim.api.nvim_err_writeln("Open this file from repo root: init.lua")
    return
  end

  local targets = {
    vim.fn.expand("~/.config/nvim/init.lua"),
    vim.fn.expand("~/.vim/init.lua"),
  }

  for _, target in ipairs(targets) do
    local dir = vim.fn.fnamemodify(target, ":h")
    vim.fn.mkdir(dir, "p")
    
    local content = vim.fn.readfile(src)
    if vim.fn.writefile(content, target) == 0 then
      print("Wrote: " .. target)
    else
      vim.api.nvim_err_writeln("Failed to write: " .. target)
    end
  end
  
  print("MagicInstall complete. Restart Neovim.")
end, { desc = "Install config to common locations" })

-- 高亮复制的文本
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking text",
  group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- 最后提示
vim.notify("Neovim C/C++ IDE config loaded! Press <Space> to see leader key bindings.", vim.log.levels.INFO)
