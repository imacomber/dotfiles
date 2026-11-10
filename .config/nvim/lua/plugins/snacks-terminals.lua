local function toggle(count)
  Snacks.terminal.toggle(nil, {
    cwd = LazyVim.root(),
    count = count,
    env = { TERM = "xterm-256color" },
    win = {
      position = "float",
      width = 150,
      height = 40,
      border = "rounded",
      on_buf = function(self)
        vim.b[self.buf].project_terminal = true
      end,
      keys = {
        hide_double_ctrl_backslash = { "<C-\\><C-\\>", "hide", mode = "t" },
      },
    },
  })
end

return {
  "folke/snacks.nvim",
  keys = {
    {
      "<leader>ms",
      function()
        toggle(1)
      end,
      desc = "Toggle Floating Terminal 1",
    },
    {
      "<leader>md",
      function()
        toggle(2)
      end,
      desc = "Toggle Floating Terminal 2",
    },
    {
      "<leader>mc",
      function()
        for _, terminal in ipairs(Snacks.terminal.list()) do
          if vim.b[terminal.buf].project_terminal then
            terminal:hide()
          end
        end
      end,
      desc = "Close Floating Terminal",
    },
  },
}
