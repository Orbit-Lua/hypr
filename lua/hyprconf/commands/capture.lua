local ctx = require("hyprconf.context")
local fs = require("hyprconf.util.fs")
local hyprctl = require("hyprconf.runtime.hyprctl")
local notify = require("hyprconf.runtime.notify")
local shell = require("hyprconf.util.shell")
local toml = require("hyprconf.util.toml")

---@alias Hyprconf.SoundKind "screenshot"|"volume"|"error"|string
---@alias Hyprconf.ScreenshotMode "--now"|"--area"|"--swappy"|"--in5"|"--in10"|"--active"|string|nil

---@class Hyprconf.SoundConfig
---@field mute? boolean
---@field mute_screenshots? boolean
---@field mute_volume? boolean
---@field theme? string

---@class Hyprconf.Commands.Capture
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
  local config = toml.read(ctx.config_file("effects")).sounds or {}
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
    local found = shell.capture(
      "find -L "
        .. shell.quote(dir)
        .. " -name "
        .. shell.quote(pattern)
        .. " -print -quit"
    )
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

---@param target string
---@param body? string
---@param swappy? boolean Open in Swappy instead of the default viewer.
---@return nil
local function notify_saved(target, body, swappy)
  if not fs.exists(target) then
    notify.warn("Screenshot", "Not saved.", "shot-notify")
    M.sound("error")
    return
  end
  M.sound("screenshot")
  local action = notify.send("Screenshot", body or "Saved.", {
    tag = "shot-notify",
    timeout = 10000,
    actions = { "action1=Open", "action2=Delete" },
  })
  if action == "action1" then
    shell.exec_bg(
      (swappy and "swappy -f " or "xdg-open ") .. shell.quote(target)
    )
  elseif action == "action2" then
    os.remove(target)
  end
end

---@param seconds integer
---@return nil
local function countdown(seconds)
  for remaining = seconds, 1, -1 do
    notify.send("Screenshot", "Capturing in " .. remaining .. "s", {
      tag = "shot-notify",
      timeout = 1000,
    })
    os.execute("sleep 1")
  end
end

-- A sortable, unused path in the screenshots directory.
---@param suffix? string
---@return string
local function screenshot_path(suffix)
  local pictures = shell.capture("xdg-user-dir PICTURES")
  if pictures == "" then
    pictures = ctx.home .. "/Pictures"
  end
  local base = pictures
    .. "/Screenshots/Screenshot_"
    .. os.date("%Y-%m-%d_%H-%M-%S")
    .. (suffix and ("_" .. suffix) or "")
  local path = base .. ".png"
  local index = 1
  while fs.exists(path) do
    index = index + 1
    path = base .. "_" .. index .. ".png"
  end
  fs.mkdir_p(fs.dirname(path))
  return path
end

---@param mode? Hyprconf.ScreenshotMode
---@return nil
function M.screenshot(mode)
  if mode == "--in5" then
    countdown(5)
  elseif mode == "--in10" then
    countdown(10)
  end

  if mode == "--area" or mode == "--swappy" then
    local tmp = os.tmpname()
    if
      not os.execute('grim -g "$(slurp)" - > ' .. shell.quote(tmp))
      or not fs.exists(tmp)
    then
      os.remove(tmp)
      return
    end
    os.execute("wl-copy < " .. shell.quote(tmp))
    if mode == "--swappy" then
      notify_saved(tmp, "Captured by Swappy.", true)
    else
      local path = screenshot_path()
      os.execute("mv " .. shell.quote(tmp) .. " " .. shell.quote(path))
      notify_saved(path)
    end
    return
  end

  if mode == "--active" then
    ---@type Hyprconf.HyprWindow
    local active = hyprctl.json("activewindow") or {}
    local at = active.at or {}
    local size = active.size or {}
    local class = active.class or "window"
    local path = screenshot_path(class)
    local geometry = string.format(
      "%s,%s %sx%s",
      at[1] or 0,
      at[2] or 0,
      size[1] or 0,
      size[2] or 0
    )
    os.execute("grim -g " .. shell.quote(geometry) .. " " .. shell.quote(path))
    notify_saved(path, class .. " saved.")
    return
  end

  local path = screenshot_path()
  os.execute("grim - | tee " .. shell.quote(path) .. " | wl-copy")
  os.execute("sleep 1")
  notify_saved(path)
end

return M
