local google_utils = require("config.google_utils")

return {
  "saghen/blink.cmp",
  dependencies = {
    { "zshihang/blink-ciderlsp", url = "sso://user/zshihang/blink-ciderlsp" },
  },
  opts = function(_, opts)
    opts.sources = opts.sources or {}
    opts.sources.providers = opts.sources.providers or {}

    -- Configure the ciderlsp provider
    opts.sources.providers.ciderlsp = {
      name = "ciderlsp",
      module = "blink-ciderlsp",
      score_offset = 200,
      async = true,
      opts = {
        show_model = true,
      },
    }

    if google_utils.is_ciderlsp_available() then
      -- 1. For Google languages, use ONLY ciderlsp (as in your snippet)
      local cider_filetypes = {
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
        "typescriptreact",
        "javascript",
        "javascriptreact",
      }

      opts.sources.per_filetype = opts.sources.per_filetype or {}
      for _, ft in ipairs(cider_filetypes) do
        opts.sources.per_filetype[ft] = { "ciderlsp", "path", "snippets" }
      end

      -- 2. For everything else (like Lua), use standard LSP and buffer
      opts.sources.default = { "lsp", "path", "snippets", "buffer" }
    else
      -- Fallback if ciderlsp isn't on the system at all
      opts.sources.default = { "lsp", "path", "snippets", "buffer" }
    end

    return opts
  end,
}
