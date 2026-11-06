-- Select an available sound and play it as optional desktop feedback.
local ctx = require("hyprconf.context")
local shell = require("hyprconf.util.shell")
local declarations = require("hyprconf.config")

---@alias Hyprconf.SoundKind "screenshot"|"volume"|"error"|string

---@class Hyprconf.SoundConfig
---@field mute? boolean
---@field mute_screenshots? boolean
---@field mute_volume? boolean
---@field theme? string

---@class Hyprconf.Commands.Sound
local M = {}

---@type table<string, string>
local sound_patterns = {
  screenshot = "screen-capture.*",
  volume = "audio-volume-change.*",
  error = "dialog-error.*",
}

---@param kind Hyprconf.SoundKind
---@param config Hyprconf.SoundConfig
---@return boolean
local function muted(kind, config)
  return not sound_patterns[kind]
    or config.mute == true
    or (kind == "screenshot" and config.mute_screenshots == true)
    or (kind == "volume" and config.mute_volume == true)
end

---@param pattern string
---@param theme string
---@return string?
local function find_sound(pattern, theme)
  for _, dir in ipairs({
    ctx.home .. "/.local/share/sounds/" .. theme .. "/stereo",
    "/usr/share/sounds/" .. theme .. "/stereo",
    ctx.home .. "/.local/share/sounds/freedesktop/stereo",
    "/usr/share/sounds/freedesktop/stereo",
  }) do
    local found = os.execute("test -d " .. shell.quote(dir))
        and shell.capture(
          "find -L " .. shell.quote(dir) .. " -name " .. shell.quote(pattern) .. " -print -quit"
        )
      or ""
    if found ~= "" then
      return found
    end
  end
  return nil
end

---@param path string
local function play_sound(path)
  for _, player in ipairs({ "pw-play", "paplay", "aplay" }) do
    if shell.command_exists(player) then
      shell.exec_bg(player .. " " .. shell.quote(path))
      return
    end
  end
end

---@param kind Hyprconf.SoundKind
---@return nil
function M.sound(kind)
  ---@type Hyprconf.SoundConfig
  local config = declarations.read("effects").sounds or {}
  if muted(kind, config) then
    return
  end
  local path = find_sound(sound_patterns[kind], config.theme or "freedesktop")
  if path then
    play_sound(path)
  end
end

return M
