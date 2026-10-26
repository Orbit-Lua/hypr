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
---@return nil
function M.sound(kind)
  ---@type Hyprconf.SoundConfig
  local config = declarations.read("effects").sounds or {}
  local pattern = sound_patterns[kind]
  if
    not pattern
    or config.mute
    or (kind == "screenshot" and config.mute_screenshots)
    or (kind == "volume" and config.mute_volume)
  then
    return
  end

  local theme = config.theme or "freedesktop"
  for _, dir in ipairs({
    ctx.home .. "/.local/share/sounds/" .. theme .. "/stereo",
    "/usr/share/sounds/" .. theme .. "/stereo",
    ctx.home .. "/.local/share/sounds/freedesktop/stereo",
    "/usr/share/sounds/freedesktop/stereo",
  }) do
    local found = os.execute("test -d " .. shell.quote(dir))
        and shell.capture(
          "find -L "
            .. shell.quote(dir)
            .. " -name "
            .. shell.quote(pattern)
            .. " -print -quit"
        )
      or ""
    if found ~= "" then
      for _, player in ipairs({ "pw-play", "paplay", "aplay" }) do
        if shell.command_exists(player) then
          shell.exec_bg(player .. " " .. shell.quote(found))
          return
        end
      end
      return
    end
  end
end

return M
