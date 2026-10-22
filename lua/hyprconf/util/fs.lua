local shell = require("hyprconf.util.shell")

---@class Hyprconf.Util.Fs
local M = {}

---@param path string
---@return string?
function M.read(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end
  local content = file:read("*a")
  file:close()
  return content
end

---@param path string
---@return boolean
function M.exists(path)
  local file = io.open(path, "r")
  if file then
    file:close()
    return true
  end
  return false
end

---@param path string
---@return nil
function M.mkdir_p(path)
  os.execute("mkdir -p " .. shell.quote(path))
end

---@param path string
---@param content string
---@return nil
function M.write(path, content)
  M.mkdir_p(M.dirname(path))
  local file = assert(io.open(path, "w"))
  file:write(content)
  file:close()
end

---@param path string
---@return string
function M.dirname(path)
  return path:match("(.+)/[^/]+$") or "."
end

---@param path string
---@return string File name without its directory or extension.
function M.stem(path)
  return ((path:match("([^/]+)$") or path):gsub("%.[^.]+$", ""))
end

---@param dir string
---@param pattern string Shell glob for file names, such as "*.lua".
---@return string[] Paths in natural sort order.
function M.list_files(dir, pattern)
  return shell.capture_lines(
    "find -L "
      .. shell.quote(dir)
      .. " -maxdepth 1 -type f -name "
      .. shell.quote(pattern)
      .. " -print | sort -V"
  )
end

return M
