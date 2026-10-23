vim.loader.enable()

-- Leader keys
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = true

-- Editor options
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.cursorline = true
vim.opt.wrap = false
vim.opt.scrolloff = 6
vim.opt.updatetime = 250
vim.opt.undofile = true
vim.opt.confirm = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Four-space indentation by default
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.smartindent = true

-- Clear search highlighting
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Keybinds to make split navigation easier.
-- Use CTRL+<hjkl> to switch between windows
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- Diagnostics
vim.diagnostic.config({
  update_in_insert = false,
  severity_sort = true,
  float = { border = "rounded", source = "if_many" },
  virtual_text = true,
  virtual_lines = false,
  jump = {
    on_jump = function(_, bufnr)
      vim.diagnostic.open_float({
        bufnr = bufnr,
        scope = "cursor",
        focus = false,
      })
    end,
  },
})

vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, {
  desc = "Open diagnostic quickfix list",
})
vim.keymap.set('n', '<leader>f', function()
  vim.lsp.buf.format({ async = true })
end, { desc = 'Auto format file' })

-- Highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight yanked text",
  group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Sync clipboard between OS and Neovim
vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
  local result = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })

  if vim.v.shell_error ~= 0 then
    error("Failed to install lazy.nvim:\n" .. result)
  end
end

vim.opt.rtp:prepend(lazypath)

-- Plugins
require("lazy").setup({
  -- Tokyo Night
  {
    "folke/tokyonight.nvim",
    priority = 1000,
    opts = {
      style = "night",
      transparent = false,
    },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme("tokyonight")
    end,
  },

  -- LSP
  {
    "neovim/nvim-lspconfig",
    config = function()
      vim.lsp.config("clangd", {})
      vim.lsp.enable("clangd")
    end,
  },

  -- Completion
  {
    "saghen/blink.cmp",
    version = "1.*",
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
    opts = {
      keymap = {
        preset = "default",
      },
      completion = {
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 300,
        },
      },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
    },
  },

  -- Automatic brackets and quotes
  {
    "echasnovski/mini.pairs",
    version = false,
    opts = {},
  },

  -- Detect indentation in existing files
  {
    "NMAC427/guess-indent.nvim",
    opts = {},
  },

  -- Debugging for C/C++
  {
    "mfussenegger/nvim-dap",
    config = function()
      local dap = require("dap")

      dap.adapters.gdb = {
        type = "executable",
        command = "gdb",
        args = { "--interpreter=dap", "--eval-command", "set print pretty on" },
      }

      dap.configurations.cpp = {
        {
          name = "Launch (ask for executable)",
          type = "gdb",
          request = "launch",
          program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopAtBeginningOfMainSubprogram = false,
          setupCommands = {
            {
              text = "-enable-pretty-printing",
              description = "enable pretty printing",
              ignoreFailures = false,
            },
          },
          console = 'integratedTerminal',
        },
      }
      dap.configurations.c = dap.configurations.cpp
    end,
  },

  -- Debugging UI
  {
    "rcarriga/nvim-dap-ui",
    dependencies = {
      "mfussenegger/nvim-dap",
      "nvim-neotest/nvim-nio", -- Required dependency
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      -- Initialize the UI
      dapui.setup()

      -- Automatically open the panel when debugging starts, close when it ends
      dap.listeners.before.attach.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        dapui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        dapui.close()
      end

      -- Your original debug keymaps (can be moved here or kept outside)
      vim.keymap.set("n", "<F5>", dap.continue, { desc = "Start/Continue debugger" })
      vim.keymap.set("n", "<F6>", dap.terminate, { desc = "Terminate debugger" })
      vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint, { desc = "Toggle breakpoint" })

      -- Additional stepping keymaps
      vim.keymap.set("n", "<F10>", dap.step_over, { desc = "Step over" })
      vim.keymap.set("n", "<F11>", dap.step_into, { desc = "Step into" })
      vim.keymap.set("n", "<F12>", dap.step_out, { desc = "Step out" })

      -- Toggle DAP UI
      vim.keymap.set("n", "<F7>", function()
        require("dapui").toggle()
      end, { desc = "Toggle DAP UI" })
    end,
  },
})

-- LSP keymaps
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(event)
    local opts = { buffer = event.buf, silent = true }

    vim.keymap.set("n", "gd", vim.lsp.buf.definition,
      vim.tbl_extend("force", opts, { desc = "Go to definition" }))

    vim.keymap.set("n", "gr", vim.lsp.buf.references,
      vim.tbl_extend("force", opts, { desc = "Find references" }))

    vim.keymap.set("n", "gD", vim.lsp.buf.declaration,
      vim.tbl_extend("force", opts, { desc = "Go to declaration" }))

    vim.keymap.set("n", "K", vim.lsp.buf.hover,
      vim.tbl_extend("force", opts, { desc = "Hover documentation" }))

    vim.keymap.set("n", "grn", vim.lsp.buf.rename,
      vim.tbl_extend("force", opts, { desc = "Rename symbol" }))

    vim.keymap.set("n", "gra", vim.lsp.buf.code_action,
      vim.tbl_extend("force", opts, { desc = "Code action / quick fix" }))
  end,
})
