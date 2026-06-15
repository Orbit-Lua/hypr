local ctx = require("hyprconf.context")

---@class Hyprconf.Deps
---@field sync fun(): string[]
---@field setup fun()
local M = {}

---@type string
local rofi_config_dir = os.getenv("ROFI_CONFIG_DIR")
  or (ctx.home .. "/.config/rofi")

---@type string[]
local rofi_files = {
  "config.rasi",
  "config-animations.rasi",
  "config-clipboard.rasi",
  "config-edit.rasi",
  "config-keybinds.rasi",
  "config-kitty-theme.rasi",
  "config-monitors.rasi",
  "config-search.rasi",
  "config-theme-selector.rasi",
  "config-zsh-theme.rasi",
  "shared-fonts.rasi",
  "noctalia/colors.rasi",
  "themes/default.rasi",
}

---@param value any
---@return string
local function shell_quote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

---@param path string
---@return boolean
local function file_exists(path)
  local file = io.open(path, "r")
  if file then
    file:close()
    return true
  end
  return false
end

---@param path string?
---@return nil
local function mkdir_p(path)
  if path and path ~= "" then
    os.execute("mkdir -p " .. shell_quote(path))
  end
end

---@param status boolean|integer|nil
---@param _? string
---@param code? integer
---@return boolean
local function command_ok(status, _, code)
  return status == true or status == 0 or code == 0
end

---@param source string
---@param target string
---@return boolean
local function copy_missing(source, target)
  if file_exists(target) or not file_exists(source) then
    return false
  end

  mkdir_p(target:match("(.+)/[^/]+$"))
  return command_ok(
    os.execute(
      "install -m 0644 " .. shell_quote(source) .. " " .. shell_quote(target)
    )
  )
end

---@return string[]
function M.sync()
  local copied = {}
  local source_dir = ctx.config_dir .. "/deps/rofi"

  for _, relative in ipairs(rofi_files) do
    local target = rofi_config_dir .. "/" .. relative
    if copy_missing(source_dir .. "/" .. relative, target) then
      copied[#copied + 1] = target
    end
  end

  return copied
end

---@return nil
function M.setup()
  M.sync()
end

return M
