return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "antoinemadec/FixCursorHold.nvim",
    "nvim-treesitter/nvim-treesitter",
    "olimorris/neotest-rspec",
  },
  config = function()
    local neotest = require("neotest")
    neotest.setup({
      log_level = vim.log.levels.DEBUG,
      adapters = {
        require("neotest-rspec"),
      },
      discovery = {
        enabled = true,
        concurrent = 1,
      },
      diagnostic = {
        enabled = true,
        severity = vim.diagnostic.severity.ERROR,
      },
      floating = {
        border = "rounded",
        max_height = 0.6,
        max_width = 0.6,
        options = {},
      },
      output = {
        enabled = true,
        open_on_run = "short",
      },
      run = {
        enabled = true,
      },
      status = {
        enabled = true,
        virtual_text = true,
        signs = true,
      },
      summary = {
        enabled = true,
        animated = true,
        follow = true,
        expand_errors = true,
        mappings = {
          attach = "a",
          clear_marked = "M",
          clear_target = "T",
          debug = "d",
          debug_marked = "D",
          expand = { "<CR>", "<2-LeftMouse>" },
          expand_all = "e",
          jumpto = "i",
          mark = "m",
          next_failed = "J",
          output = "o",
          prev_failed = "K",
          run = "r",
          run_marked = "R",
          short = "O",
          stop = "u",
          target = "t",
          watch = "w",
        },
      },
    })
  end,
  keys = {
    {
      "<leader>tt",
      function()
        require("neotest").run.run(vim.fn.expand("%"))
        vim.defer_fn(function()
          require("neotest").summary.open()
        end, 100)
      end,
      desc = "Run File",
    },
    {
      "<leader>tT",
      function()
        require("neotest").run.run(vim.uv.cwd())
        require("neotest").summary.open()
      end,
      desc = "Run All Test Files",
    },
    {
      "<leader>tr",
      function()
        require("neotest").run.run()
        vim.defer_fn(function()
          require("neotest").summary.open()
        end, 100)
      end,
      desc = "Run Nearest",
    },
    {
      "<leader>tl",
      function()
        require("neotest").run.run_last()
      end,
      desc = "Run Last",
    },
    {
      "<leader>ts",
      function()
        require("neotest").summary.toggle()
      end,
      desc = "Toggle Summary",
    },
    {
      "<leader>to",
      function()
        require("neotest").output.open({ enter = true, auto_close = true })
      end,
      desc = "Show Output",
    },
    {
      "<leader>tO",
      function()
        require("neotest").output_panel.toggle()
      end,
      desc = "Toggle Output Panel",
    },
    {
      "<leader>tS",
      function()
        require("neotest").run.stop()
      end,
      desc = "Stop",
    },
    {
      "<leader>tw",
      function()
        require("neotest").watch.toggle(vim.fn.expand("%"))
      end,
      desc = "Toggle Watch",
    },
  },
}
