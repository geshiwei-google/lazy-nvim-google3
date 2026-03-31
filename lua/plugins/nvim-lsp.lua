return {
  "neovim/nvim-lspconfig",
  opts = function(_, opts)
    local nvim_lspconfig = require("lspconfig")
    local lsp_configs = require("lspconfig.configs")
    -- Use this to enable Cider LSP advanced features. For instance, this enables
    -- completion placeholders (see go/cider-v-lsp-features#code-completion) and
    -- inlay hints for kotlin local variable types.
    local ciderlsp_settings = {
      "enable_placeholders",
      "enable:inlay_hints_kotlin_show_local_variable_types",
    }

    lsp_configs.ciderlsp = {
      default_config = {
        cmd = {
          "/google/bin/releases/cider/ciderlsp/ciderlsp",
          "--tooltag=nvim-lsp",
          "--noforward_sync_responses",
          "--request_options=" .. table.concat(ciderlsp_settings, ","),
        },
        filetypes = { "c", "cpp", "java", "kotlin", "objc", "proto", "textpb", "go", "python", "bzl", "typescript" },
        offset_encoding = "utf-8",
        root_dir = nvim_lspconfig.util.root_pattern(".citc"),
      },
    }
    nvim_lspconfig.ciderlsp.setup({
      capabilities = require("blink.cmp").get_lsp_capabilities(),
      on_attach = function(client, bufnr)
        local ft = vim.bo[bufnr].filetype
        if ft == "typescript" or ft == "bzl" then
          client.server_capabilities.documentHighlightProvider = false
        end
      end,
    })
  end,
}
