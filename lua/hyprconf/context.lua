local shell = require("hyprconf.util.shell")

---@class Hyprconf.Context
---@field home string User home directory.
---@field config_dir string Hyprland configuration root, read-only when deployed from the Nix store.
---@field state_dir string Writable runtime state: selected profiles and effects.
---@field hypr_lua string Shell command that runs the Hypr Lua CLI.
---@field main_mod string Primary Hyprland modifier.
---@field vicinae string Vicinae launcher command.
---@field term string Default terminal command.
---@field files string Default file-manager command.
---@field editor string Editor the quick settings open files with.
---@field search_engine string Search URL prefix used by runtime helpers.
---@field touchpad_device string Hyprland input device name for touchpad toggling.
---@field touchpad_state string Session file holding the toggled touchpad state.
local M = {}

-- The configuration root is two levels above this file, so the compositor and
-- the helper CLI always agree on it, wherever the tree is deployed.
---@return string
local function source_root()
  local path = debug.getinfo(1, "S").source:sub(2)
  if path:sub(1, 1) ~= "/" then
    path = (os.getenv("PWD") or ".") .. "/" .. path
  end
  return path:match("(.+)/lua/hyprconf/[^/]+$") or "."
end

M.home = os.getenv("HOME") or ""
M.config_dir = os.getenv("HYPR_CONFIG_DIR") or source_root()
M.state_dir = os.getenv("HYPR_STATE_DIR")
  or ((os.getenv("XDG_STATE_HOME") or (M.home .. "/.local/state")) .. "/hypr")
M.hypr_lua = "lua " .. shell.quote(M.config_dir .. "/lua/bin/hypr.lua")
M.main_mod = "SUPER"
M.vicinae = "vicinae"
M.term = "ghostty"
M.files = "thunar"
M.editor = os.getenv("EDITOR") or "nvim"
M.search_engine = "https://www.google.com/search?q="
M.touchpad_device = "asue1209:00-04f3:319f-touchpad"
M.touchpad_state = (os.getenv("XDG_RUNTIME_DIR") or "/tmp")
  .. "/touchpad.status"

---@param name string File name under lua/config without the .toml suffix.
---@return string
function M.config_file(name)
  return M.config_dir .. "/lua/config/" .. name .. ".toml"
end

return M
