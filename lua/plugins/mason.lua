local is_google3 = vim.fn.finddir(".citc", vim.fn.getcwd() .. ";") ~= ""

return {
  -- Keep Mason but disable automatic installation of LSPs
  {
    "mason-org/mason-lspconfig.nvim",
    enabled = not is_google3,
    opts = {
      automatic_installation = false,
      ensure_installed = {}, -- Prevent it from trying to install any defaults
    },
  },

  -- Also ensure Mason itself doesn't have any hardcoded "ensure_installed" from LazyVim defaults
  {
    "mason-org/mason.nvim",
    enabled = not is_google3,
    opts = {
      ensure_installed = {},
    },
  },
}
