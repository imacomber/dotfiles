return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    opts.sections.lualine_c[1] = LazyVim.lualine.root_dir({ cwd = true })
    opts.sections.lualine_c[4] = {
      LazyVim.lualine.pretty_path({ relative = "root", length = 0 }),
    }
  end,
}
