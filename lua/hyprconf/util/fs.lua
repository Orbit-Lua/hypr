local shell = require("hyprconf.util.shell")

---@class Hyprconf.Util.Fs
local M = {}

---@param path string
---@return string?
function M.read(path)
  local file, err, code = io.open(path, "r")
  if not file then
    assert(code == 2, err)
    return nil
  end
  local content = assert(file:read("*a"))
  assert(file:close())
  return content
end

---@param path string
---@param content string
---@return nil
function M.atomic_write(path, content)
  M.mkdir_p(M.dirname(path))
  local process = require("hyprconf.runtime.process")
  local temporary = process
    .check(process.run({ "mktemp", path .. ".XXXXXX" }), "state temporary file").stdout
    :gsub("%s+$", "")
  local ok, err = pcall(function()
    M.write(temporary, content)
    assert(os.rename(temporary, path))
  end)
  if M.exists(temporary) then
    assert(os.remove(temporary))
  end
  if not ok then
    error(err, 0)
  end
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
  assert(
    os.execute("mkdir -p " .. shell.quote(path)),
    "could not create directory: " .. path
  )
end

---@param path string
---@param content string
---@return nil
function M.write(path, content)
  M.mkdir_p(M.dirname(path))
  local file = assert(io.open(path, "w"))
  assert(file:write(content))
  assert(file:close())
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
  local process = require("hyprconf.runtime.process")
  local found = process.check(
    process.run({
      "find",
      "-L",
      dir,
      "-maxdepth",
      "1",
      "-type",
      "f",
      "-name",
      pattern,
      "-print",
    }),
    "list profile files"
  )
  local sorted = process.check(
    process.run({ "sort", "-V" }, { stdin = found.stdout }),
    "sort profile files"
  )
  local files = {}
  for path in sorted.stdout:gmatch("[^\n]+") do
    files[#files + 1] = path
  end
  return files
end

return M
