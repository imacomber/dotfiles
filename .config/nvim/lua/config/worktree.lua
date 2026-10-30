local M = {}

local function git(args)
  local out = vim.fn.systemlist(vim.list_extend({ "git" }, args))
  return vim.v.shell_error == 0, out
end

function M.list()
  local ok, out = git({ "worktree", "list", "--porcelain" })
  if not ok then
    return {}
  end
  local list, current = {}, nil
  for _, line in ipairs(out) do
    local path = line:match("^worktree (.+)")
    if path then
      current = { path = path }
      table.insert(list, current)
    end
    current.branch = line:match("^branch refs/heads/(.+)") or current.branch
    current.bare = current.bare or line == "bare"
  end
  return vim.tbl_filter(function(w)
    return not w.bare
  end, list)
end

-- Saves this worktree's session, then swaps cwd, buffers, LSP, and session over to the target.
-- Terminal buffers (Claude, toggleterm) are left alone so running jobs survive the switch.
function M.switch(path)
  local root = vim.fn.getcwd()
  if path == root then
    return
  end

  local file = vim.api.nvim_buf_get_name(0)
  local relative = vim.startswith(file, root .. "/") and file:sub(#root + 2) or nil

  vim.cmd("silent! wall")
  require("persistence").save()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buftype == "" then
      pcall(vim.api.nvim_buf_delete, buf, {})
    end
  end
  for _, client in ipairs(vim.lsp.get_clients()) do
    client:stop()
  end

  vim.cmd.cd(vim.fn.fnameescape(path))
  require("persistence").load()

  if vim.api.nvim_buf_get_name(0) == "" and relative and vim.uv.fs_stat(path .. "/" .. relative) then
    vim.cmd.edit(vim.fn.fnameescape(path .. "/" .. relative))
  end
  vim.notify("Worktree: " .. vim.fn.fnamemodify(path, ":~"))
end

function M.pick()
  vim.ui.select(M.list(), {
    prompt = "Worktree",
    format_item = function(w)
      return string.format("%-40s %s", w.branch or "(detached)", vim.fn.fnamemodify(w.path, ":~"))
    end,
  }, function(w)
    if w then
      M.switch(w.path)
    end
  end)
end

-- Creates ../<repo>-<branch> next to the main checkout, reusing the branch if it already exists.
function M.add()
  vim.ui.input({ prompt = "Worktree branch: " }, function(branch)
    if not branch or branch == "" then
      return
    end
    local main = M.list()[1].path
    local path = main .. "-" .. branch:gsub("/", "-")
    local exists = git({ "show-ref", "--verify", "--quiet", "refs/heads/" .. branch })
    local args = exists and { "worktree", "add", path, branch } or { "worktree", "add", "-b", branch, path }
    local ok, out = git(args)
    if not ok then
      return vim.notify(table.concat(out, "\n"), vim.log.levels.ERROR)
    end
    M.switch(path)
  end)
end

return M
