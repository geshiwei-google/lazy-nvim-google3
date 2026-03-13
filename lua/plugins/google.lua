return {
  -- CiderLSP setup
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local nvim_lspconfig = require("lspconfig")
      local lsp_configs = require("lspconfig.configs")

      local ciderlsp_settings = {
        "enable_placeholders",
        "enable:inlay_hints_kotlin_show_local_variable_types",
      }

      if not lsp_configs.ciderlsp then
        lsp_configs.ciderlsp = {
          default_config = {
            cmd = {
              "/google/bin/releases/cider/ciderlsp/ciderlsp",
              "--tooltag=nvim-lsp",
              "--noforward_sync_responses",
              "--request_options=" .. table.concat(ciderlsp_settings, ","),
            },
            filetypes = {
              "c",
              "cpp",
              "java",
              "kotlin",
              "objc",
              "proto",
              "textpb",
              "go",
              "python",
              "bzl",
              "typescript",
            },
            offset_encoding = "utf-8",
            root_dir = nvim_lspconfig.util.root_pattern(".citc"),
          },
        }
      end

      opts.servers = opts.servers or {}
      opts.servers.ciderlsp = {}
    end,
  },

  -- Critique Integration
  {
    "google/critique-nvim",
    url = "sso://google/critique-nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = "BufReadPost",
    opts = {},
  },

  -- Google Comments
  {
    "google/google-comments.nvim",
    url = "sso://google/google-comments.nvim",
    event = "BufReadPost",
    opts = {},
  },

  -- Buganizer
  {
    "google/buganizer.nvim",
    url = "sso://google/buganizer.nvim",
    cmd = { "Buganizer" },
    opts = {},
  },

  -- Telescope extensions
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      { "google/telescope-codesearch.nvim", url = "sso://google/telescope-codesearch.nvim" },
      { "google/telescope-citc.nvim", url = "sso://google/telescope-citc.nvim" },
    },
    opts = function(_, opts)
      -- Load extensions
      local telescope = require("telescope")
      telescope.load_extension("codesearch")
      telescope.load_extension("citc")
    end,
    keys = {
      { "<leader>fC", "<cmd>Telescope codesearch<cr>", desc = "CodeSearch" },
      { "<leader>fc", "<cmd>Telescope citc<cr>", desc = "CitC" },
    },
  },

  -- Google Paths (//depot/...)
  {
    "google/googlepaths.nvim",
    url = "sso://google/googlepaths.nvim",
    event = "BufReadPost",
    opts = {},
  },

  -- Internal Terms highlighting
  {
    "google/goog-terms.nvim",
    url = "sso://google/goog-terms.nvim",
    event = "BufReadPost",
    opts = {},
  },
}
