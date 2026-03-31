return {
  {
    "mhinz/vim-signify",
    lazy = false,
    init = function()
      -- Use 'hg pdiff' to include committed (but not yet pushed) and uncommitted changes.
      vim.g.signify_vcs_list = { "hg" }
      vim.g.signify_vcs_cmds = {
        -- Using %f for the file path, and removing the '--' which can sometimes cause issues with hg pdiff.
        hg = "hg diff --rev p4base --color=never --nodates -U0 %f",
      }
      -- Faster updates for signs
      vim.g.signify_update_on_bufenter = 1
      vim.g.signify_update_on_focusgained = 1
    end,
  },
}
