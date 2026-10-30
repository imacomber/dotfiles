-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local worktree = require("config.worktree")
vim.keymap.set("n", "<leader>gw", worktree.pick, { desc = "Switch Worktree" })
vim.keymap.set("n", "<leader>gW", worktree.add, { desc = "New Worktree" })
