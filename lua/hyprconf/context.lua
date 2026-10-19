---@class Hyprconf.Context
---@field home string User home directory.
---@field config_dir string Hyprland configuration root, read-only when deployed from the Nix store.
---@field state_dir string Writable runtime state: selected profiles and effects.
---@field effects_dir string Generated effect state under state_dir.
---@field hypr_lua string Shell command that runs the Hypr Lua CLI.
---@field main_mod string Primary Hyprland modifier.
---@field vicinae string Vicinae launcher command.
---@field term string Default terminal command.
---@field files string Default file-manager command.
---@field search_engine string Search URL prefix used by runtime helpers.
---@field touchpad_device string Hyprland input device name for touchpad toggling.
local M = {}

---@param value any
---@return string
local function shell_quote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

M.home = os.getenv("HOME") or ""
M.config_dir = os.getenv("HYPR_CONFIG_DIR") or (M.home .. "/.config/hypr")
M.state_dir = os.getenv("HYPR_STATE_DIR")
  or ((os.getenv("XDG_STATE_HOME") or (M.home .. "/.local/state")) .. "/hypr")
M.effects_dir = os.getenv("EFFECTS_DIR") or (M.state_dir .. "/effects")
M.hypr_lua = "lua " .. shell_quote(M.config_dir .. "/lua/bin/hypr.lua")
M.main_mod = "SUPER"
M.vicinae = "vicinae"
M.term = "ghostty"
M.files = "thunar"
M.search_engine = "https://www.google.com/search?q="
M.touchpad_device = "asue1209:00-04f3:319f-touchpad"

return M
