local M = {}

function M.is_ciderlsp_available()
  return vim.fn.executable("/google/bin/releases/cider/ciderlsp/ciderlsp") == 1
end

return M
