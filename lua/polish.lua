-- This will run last in the setup process.
-- This is just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

-- Use the right clipboard when on WSL
local function is_wsl()
  local wsl_check = os.getenv "WSL_DISTRO_NAME" ~= nil
  return wsl_check
end

-- win32yank required
if is_wsl() then
  vim.g.clipboard = {
    name = "win32yank-wsl",
    copy = {
      ["+"] = "win32yank.exe -i --crlf",
      ["*"] = "win32yank.exe -i --crlf",
    },
    paste = {
      ["+"] = "win32yank.exe -o --lf",
      ["*"] = "win32yank.exe -o --lf",
    },
    cache_enabled = false,
  }
  vim.g.loaded_clipboard_provider = nil
  vim.opt.clipboard = ""
end

-- Pi: Direct queries for pi coding agent
-- Usage: nvim --server <socket> --remote-expr 'v:lua.PiGetBuffers()'

local lsp_result_file = "/tmp/pi-lsp-result.json"
local exclude_filetypes = {
  "gitcommit", "gitrebase", "qf", "help", "ministart",
  "TelescopePrompt", "neo-tree", "oil", "noice",
}
local exclude_patterns = { "^%a+://" }
local severity_names = { "Error", "Warning", "Info", "Hint" }

local function write_lsp_result(result)
  local data = vim.json.encode({ timestamp = os.time(), result = result })
  local f = io.open(lsp_result_file, "w")
  if f then f:write(data); f:close() end
end

local function format_location(loc)
  local uri = loc.uri or loc.targetUri or ""
  local path = vim.uri_to_fname(uri)
  local range = loc.range or loc.targetRange or loc.targetSelectionRange or {}
  local start = range.start or { line = 0, character = 0 }
  local end_ = range["end"] or range["end"] or { line = 0, character = 0 }
  return {
    file = path,
    line = start.line + 1,
    column = start.character + 1,
    endLine = (end_ and end_.line + 1) or nil,
    endColumn = (end_ and end_.character + 1) or nil,
  }
end

-- PiGetBuffers: Return buffer metadata for direct querying
_G.PiGetBuffers = function()
  local buffers = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buflisted then
      local name = vim.api.nvim_buf_get_name(buf)
      local ft = vim.bo[buf].filetype or ""
      if vim.tbl_contains(exclude_filetypes, ft) then goto continue end
      local excluded = false
      for _, pat in ipairs(exclude_patterns) do
        if string.match(name, pat) then excluded = true; break end
      end
      if excluded then goto continue end
      table.insert(buffers, {
        path = name ~= "" and name or "[No Name]",
        filetype = ft,
        lineCount = vim.api.nvim_buf_line_count(buf),
        modified = vim.bo[buf].modified,
      })
    end
    ::continue::
  end
  return vim.json.encode({ buffers = buffers, count = #buffers })
end

-- PiGetDiagnostics: Return LSP diagnostics for all buffers
_G.PiGetDiagnostics = function()
  local all_diagnostics = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buflisted then
      local file = vim.api.nvim_buf_get_name(buf)
      for _, diag in ipairs(vim.diagnostic.get(buf)) do
        table.insert(all_diagnostics, {
          file = file,
          line = diag.lnum + 1,
          column = diag.col + 1,
          severity = severity_names[diag.severity] or "Unknown",
          message = diag.message,
          source = diag.source or "",
          code = diag.code or nil,
        })
      end
    end
  end
  return vim.json.encode({ diagnostics = all_diagnostics, count = #all_diagnostics })
end

-- PiLspQuery: Query LSP by position
_G.PiLspQuery = function(query_type, filepath, line, col)
  if not query_type or not filepath or not line or not col then
    write_lsp_result({ error = "Missing parameters" })
    return "Error: missing parameters"
  end

  line = tonumber(line) - 1
  col = tonumber(col) - 1

  local buf
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_name(b) == filepath then buf = b; break end
  end
  if not buf then
    local old_buf = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()
    vim.cmd("silent keepalt keepjumps edit " .. vim.fn.fnameescape(filepath))
    buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_set_current_buf(old_buf)
    vim.api.nvim_set_current_win(win)
  end

  local clients = vim.lsp.get_clients({ bufnr = buf })
  local client = clients[1]
  if not client then
    write_lsp_result({ error = "No LSP client found for " .. filepath })
    return "No LSP client for: " .. filepath
  end

  local methods = {
    definition = "textDocument/definition",
    references = "textDocument/references",
    typeDefinition = "textDocument/typeDefinition",
    implementation = "textDocument/implementation",
    documentHighlight = "textDocument/documentHighlight",
  }
  local method = methods[query_type]
  if not method then
    write_lsp_result({ error = "Unknown query type: " .. query_type })
    return "Unknown query type"
  end

  local params = {
    textDocument = vim.lsp.util.make_text_document_params(buf),
    position = { line = line, character = col },
  }
  local results = {}
  local ok, response = pcall(client.request_sync, method, params, nil, buf)
  if not ok or not response then
    write_lsp_result({ error = "LSP request failed" })
    return "LSP request failed"
  end

  if response.result then
    local result = response.result
    if type(result) == "table" then
      if result[1] then
        for _, loc in ipairs(result) do table.insert(results, format_location(loc)) end
      elseif result.range then
        table.insert(results, format_location(result))
      elseif result.targetUri then
        table.insert(results, format_location(result))
      end
    end
  end

  write_lsp_result({
    type = query_type,
    file = filepath,
    line = line + 1,
    column = col + 1,
    results = results,
    count = #results,
  })
  return "Found " .. #results .. " result(s)"
end
