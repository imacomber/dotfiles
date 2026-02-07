return {
  "akinsho/toggleterm.nvim",
  version = "*",
  opts = {
    size = 60,
    direction = "vertical",
    shade_terminals = false,
    auto_scroll = true,
    persist_mode = true,
    float_opts = {
      border = "curved",
      width = 150,
      height = 40,
    },
  },
  config = function(_, opts)
    require("toggleterm").setup(opts)

    -- Create two separate floating terminal instances
    local Terminal = require("toggleterm.terminal").Terminal

    local terminal_ps = Terminal:new({
      direction = "float",
      hidden = true,
      dir = "git_dir", -- Opens in git root, or cwd if not in a git repo
      env = {
        TERM = "xterm-256color",
      },
      on_open = function(term)
        vim.cmd("startinsert!")
        -- Normal mode: press 'q' to close
        vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
        -- Terminal mode: press Ctrl-\ twice to close
        vim.api.nvim_buf_set_keymap(
          term.bufnr,
          "t",
          "<C-\\><C-\\>",
          "<cmd>close<CR>",
          { noremap = true, silent = true }
        )
      end,
    })

    local terminal_pd = Terminal:new({
      direction = "float",
      hidden = true,
      dir = "git_dir",
      env = {
        TERM = "xterm-256color",
      },
      on_open = function(term)
        vim.cmd("startinsert!")
        -- Normal mode: press 'q' to close
        vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
        -- Terminal mode: press Ctrl-\ twice to close
        vim.api.nvim_buf_set_keymap(
          term.bufnr,
          "t",
          "<C-\\><C-\\>",
          "<cmd>close<CR>",
          { noremap = true, silent = true }
        )
      end,
    })

    -- Global functions to toggle terminals
    function _PS_TOGGLE()
      terminal_ps:toggle()
    end

    function _PD_TOGGLE()
      terminal_pd:toggle()
    end

    function _TERMINAL_CLOSE()
      -- Close any currently open floating terminal without killing it
      if terminal_ps:is_open() then
        terminal_ps:toggle()
      end
      if terminal_pd:is_open() then
        terminal_pd:toggle()
      end
    end
  end,
  keys = {
    {
      "<leader>ms",
      "<cmd>lua _PS_TOGGLE()<CR>",
      desc = "Toggle Floating Terminal 1",
    },
    {
      "<leader>md",
      "<cmd>lua _PD_TOGGLE()<CR>",
      desc = "Toggle Floating Terminal 2",
    },
    {
      "<leader>mc",
      "<cmd>lua _TERMINAL_CLOSE()<CR>",
      desc = "Close Floating Terminal",
    },
  },
}
