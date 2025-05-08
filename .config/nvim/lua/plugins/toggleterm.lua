return {
  "akinsho/toggleterm.nvim",
  version = "*",
  opts = {
    size = 60,
    direction = "vertical",
    shade_terminals = false,
  },
  keys = {
    {
      "<leader>rr",
      function()
        local full_path = vim.fn.expand('%')
        -- Find the position of "/source/" in the full_path
        local position = full_path:find("/source/")

        -- if /source/ is found then we have a full path; otherwise it's already relative
        if position then
          -- Find the position of the next slash after "/source/"
          local next_slash_position = full_path:find("/", position + 8)

          -- Extract the relative path starting after the next slash
          local relative_path = full_path:sub(next_slash_position + 1)

          require("toggleterm").exec_command("cmd='run bundle exec rspec " .. relative_path .. "'")
        else
          require("toggleterm").exec_command("cmd='run bundle exec rspec " .. full_path .. "'")
        end
      end,
      desc = "Run RSpec for Current File"
    },
  },
}
