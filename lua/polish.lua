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
