local M = {}

local proc = require("snacks.picker.source.proc").proc

-- Each CITC client has a workspace ID which usually looks like {LDAP}/{NUMERIC_ID}.
-- You can get that ID locally by running `citctools info`.
-- Workspace ID is needed when we want the query to include local results.
local workspace_id_cache = nil
local function get_workspace_id()
  if workspace_id_cache == nil then
    local output = vim.fn.system("citctools info")
    workspace_id_cache = output:match("Workspace ID: (%S+)") or false
  end
  return workspace_id_cache or nil
end

-- The function returns a string {LDAP}/{CITC_CLIENT_NAME}.
-- When `cs` returns results from a local workspace, it provides an invalid path
-- similar to `/google/src/cloud/{LDAP}/{ID}/google3/{SOME-GOOGLE3-PATH}`.
-- We fix that by replacing `{LDAP}/{ID}` with your current `{LDAP}/{CITC_CLIENT_NAME}`.
local ldap_and_citc_cache = nil
local function get_ldap_and_citc()
  if ldap_and_citc_cache == nil then
    local cwd = vim.fn.getcwd()
    ldap_and_citc_cache = string.match(cwd, "^/google/src/cloud/([^/]+/[^/]+)/google3") or false
  end
  return ldap_and_citc_cache or nil
end

local function get_build_root_prefix()
  local buf_name = vim.api.nvim_buf_get_name(0)
  if buf_name == "" then
    return nil
  end

  local current_dir = vim.fs.dirname(buf_name)
  local build_file = vim.fs.find("BUILD", { upward = true, path = current_dir })[1]

  if not build_file then
    return nil
  end

  local build_dir = vim.fs.dirname(build_file)
  local google3_pos = build_dir:find("/google3/")
  if not google3_pos then
    return nil
  end

  local relative_path = build_dir:sub(google3_pos + 9)
  if relative_path == "" then
    return nil
  end

  return "f:" .. relative_path .. "/"
end

---@param path string
---@param ldap_and_citc? string
---@param workspace_id? string
local gpath_transform = function(path, ldap_and_citc, workspace_id)
  -- Remove the head path if present
  local head_rm = "/google/src/files/head/depot/google3/"
  path = path:gsub(head_rm, "")

  -- Apply the fix from Link 2: Replace workspace ID with LDAP/CITC client name
  if ldap_and_citc and workspace_id then
    path = path:gsub(workspace_id .. "//depot", ldap_and_citc, 1)
    path = path:gsub(workspace_id, ldap_and_citc, 1)
  end

  -- Optionally, remove the /google/src/cloud/{ldap}/{citc}/google3/ part too for display
  if ldap_and_citc then
    path = path:gsub("^/google/src/cloud/" .. ldap_and_citc .. "/google3/", "")
  end

  return path
end

---@param opts google.snacks.codesearch.Config
---@param ctx snacks.picker.finder.ctx
---@return string[]
local get_args = function(opts, ctx)
  local args = { "--color", "never" }
  if not opts.head then
    table.insert(args, "--local")
  end
  if opts.experimental then
    table.insert(args, "--experimental")
  end
  if opts.max_num_results then
    vim.list_extend(args, { "--max_num_results", opts.max_num_results })
  end
  if opts.files then
    table.insert(args, "-l")
  end
  if opts.corpus then
    vim.list_extend(args, { "--corpora", opts.corpus })
  end
  if opts.local_proxy ~= false then
    vim.list_extend(args, { "--enable_local_proxy" })
  end
  if opts.retrieve_end_user_credentials == false then
    vim.list_extend(args, { "--retrieve_end_user_credentials=false" })
  end

  -- search parameters
  vim.list_extend(args, { "--" })
  if not opts.head and opts.add_workspace ~= false then
    local workspace_id = get_workspace_id()
    if workspace_id then
      vim.list_extend(args, { "add_workspace:" .. workspace_id })
    end
  end

  if opts.default_text then
    vim.list_extend(args, { opts.default_text })
  end

  vim.list_extend(args, { ctx.filter.search })
  return args
end

---@class google.snacks.codesearch.Config: snacks.picker.Config|{}
---@field backend? string `cs` or `csearch` (default: cs)
---@field files? boolean wether to look only for files (default: false)
---@field experimental? boolean if true shows results from experimental (default: false)
---@field corpus? string comma-separated list of corpus (default: "")
---@field max_num_results? number max results - (default: 200 - from cs)
---@field debounce? number debounce time in ms (default: 100)
---@field alphasort? boolean if true sort the results alphabethically (no ranking) (default: false)
---@field local_proxy? boolean if true use local proxy (default: true) -- faster startup
---@field retrieve_end_user_credentials? boolean if true retreive end user creds (default: false) -- less results moar speed
---@field add_workspace? boolean if true search for files within the current client
---@field default_text? string if set, adds the string as a query parameter before the search term
---@field head? boolean if true omit local workspace results (default: false)
M.default_config = {
  backend = "cs",
  experimental = false,
  files = false,
  alphasort = false,
  local_proxy = true,
  retrieve_end_user_credentials = false,
  add_workspace = true,
  head = false,
  default_text = nil,
  source = "codesearch",
  live = true,
  supports_live = true,
  title = "codesearch",
  format = "file",
  debounce = 500,
  finder = function(opts, ctx)
    -- this prevents showing the help text of `cs` in the picker
    if ctx.filter.search == "" then
      return function() end
    end

    local workspace_id = get_workspace_id()
    local ldap_and_citc = get_ldap_and_citc()

    local p = proc({
      notify = false,
      cmd = opts.backend,
      args = get_args(opts, ctx),
      cwd = vim.fn.getcwd(),
      transform = function(item)
        local raw_path
        if opts.files then
          raw_path = item.text
          item._path = raw_path
          -- Apply workspace fix to item._path so it's a valid path to open
          if ldap_and_citc and workspace_id then
            item._path = item._path:gsub(workspace_id .. "//depot", ldap_and_citc, 1)
            item._path = item._path:gsub(workspace_id, ldap_and_citc, 1)
          end
          item.file = gpath_transform(raw_path, ldap_and_citc, workspace_id)
          return
        end
        local file, line, text = item.text:match("^(.+):(%d+):%s+(.*)$")
        if not file then
          return
        end
        raw_path = file
        item._path = raw_path
        -- Apply workspace fix to item._path so it's a valid path to open
        if ldap_and_citc and workspace_id then
          item._path = item._path:gsub(workspace_id .. "//depot", ldap_and_citc, 1)
          item._path = item._path:gsub(workspace_id, ldap_and_citc, 1)
        end
        item.text = text
        item.file = gpath_transform(raw_path, ldap_and_citc, workspace_id)
        item.pos = { tonumber(line), 0 }
      end,
    }, ctx)

    return function(cb)
      local debounce_ms = opts.debounce or 500
      if debounce_ms > 0 then
        local ok, Async = pcall(require, "snacks.picker.util.async")
        if ok and Async and Async.running() then
          pcall(Async.sleep, debounce_ms)
          local task = Async.running()
          if task and task._aborted then
            return
          end
        end
      end
      if ctx.picker and ctx.picker.closed then
        return
      end

      p(cb)
    end
  end,
}

---@param opts? google.snacks.codesearch.Config
M.query = function(opts)
  local picker_opts = vim.tbl_deep_extend("force", {}, M.default_config, opts or {})
  -- snacks.picker.pick uses search for the initial text
  if opts and opts.search then
    picker_opts.search = opts.search
  end
  Snacks.picker.pick(picker_opts)
end

---@param opts? google.snacks.codesearch.Config
M.word = function(opts)
  local word_opts = {
    search = function(picker)
      return picker:word()
    end,
    title = "codesearch - word",
  }
  local picker_opts = vim.tbl_deep_extend("force", {}, M.default_config, word_opts, opts or {})
  M.query(picker_opts)
end

---@param opts? google.snacks.codesearch.Config
M.visual = function(opts)
  local visual_opts = {
    search = function(picker)
      return picker.visual.text or ""
    end,
    title = "codesearch - visual",
  }
  local picker_opts = vim.tbl_deep_extend("force", {}, M.default_config, visual_opts, opts or {})
  M.query(picker_opts)
end

---@param opts? google.snacks.codesearch.Config
M.head_query = function(opts)
  local prefix = get_build_root_prefix()
  local head_opts = {
    search = prefix and (prefix .. " ") or nil,
    title = "codesearch - head",
  }
  local picker_opts = vim.tbl_deep_extend("force", {}, M.default_config, head_opts, opts or {})
  M.query(picker_opts)
end

return M
