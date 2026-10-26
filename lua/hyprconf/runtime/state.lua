local fs = require("hyprconf.util.fs")
local M = {}

---@param path string
---@param value string?
---@return nil
function M.replace(path, value)
  if value ~= nil then
    fs.atomic_write(path, value)
  elseif fs.exists(path) then
    assert(os.remove(path))
  end
end

---Activation reads the staged declaration; compensation reads the restored one.
---@param path string
---@param value string?
---@param activate fun()
---@return nil
function M.change(path, value, activate)
  local previous = fs.read(path)
  M.replace(path, value)
  local ok, err = pcall(activate)
  if not ok then
    local restored, restore_error = pcall(M.replace, path, previous)
    local applied, apply_error = false, "state restoration failed"
    if restored then
      applied, apply_error = pcall(activate)
    end
    if not restored or not applied then
      error(
        tostring(err)
          .. "; recovery failed: "
          .. tostring(restored and apply_error or restore_error),
        0
      )
    end
    error(tostring(err) .. "; previous state restored", 0)
  end
end

return M
