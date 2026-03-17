return {
  url = "sso://user/maxcchuang/unclash.nvim",
  lazy = false, -- unclash is lazy-loaded by default
  opts = function()
    require("unclash").setup({
      action_buttons = {
        enabled = true, -- Enable/disable action buttons above conflicts
      },
      annotations = {
        enabled = true, -- Enable/disable annotations (e.g. "(Current Change)")
      },
    })
  end,
}
