local cli = require("hyprconf.cli")
local common = require("hyprconf.commands.common")
local toml = require("hyprconf.util.toml")

---@alias Hyprconf.SoundKind "screenshot"|"volume"|"error"|string
---@alias Hyprconf.ScreenshotMode "--now"|"--area"|"--swappy"|"--in5"|"--in10"|"--active"|"--win"|string|nil

---@class Hyprconf.SoundConfig
---@field mute? boolean
---@field mute_screenshots? boolean
---@field mute_volume? boolean
---@field theme? string

---@class Hyprconf.EffectsConfig
---@field sounds? Hyprconf.SoundConfig

---@class Hyprconf.Commands.Capture
---@field sound fun(kind: Hyprconf.SoundKind)
---@field screenshot fun(mode?: Hyprconf.ScreenshotMode)
local M = {}

---@param kind Hyprconf.SoundKind
---@return nil
function M.sound(kind)
  ---@type Hyprconf.SoundConfig
  local data = toml.read(common.config("effects")).sounds or {}
  if data.mute then
    return
  end
  if kind == "screenshot" and data.mute_screenshots then
    return
  end
  if kind == "volume" and data.mute_volume then
    return
  end

  local patterns = {
    screenshot = "screen-capture.*",
    volume = "audio-volume-change.*",
    error = "dialog-error.*",
  }
  local pattern = patterns[kind]
  if not pattern then
    return
  end

  local theme = data.theme or "freedesktop"
  local candidates = {
    cli.home .. "/.local/share/sounds/" .. theme .. "/stereo",
    "/usr/share/sounds/" .. theme .. "/stereo",
    cli.home .. "/.local/share/sounds/freedesktop/stereo",
    "/usr/share/sounds/freedesktop/stereo",
  }

  for _, dir in ipairs(candidates) do
    local found = cli.capture(
      "find -L "
        .. cli.shell_quote(dir)
        .. " -name "
        .. cli.shell_quote(pattern)
        .. " -print -quit"
    )
    if found ~= "" then
      if cli.command_exists("pw-play") then
        cli.exec_bg("pw-play " .. cli.shell_quote(found))
      elseif cli.command_exists("paplay") then
        cli.exec_bg("paplay " .. cli.shell_quote(found))
      elseif cli.command_exists("aplay") then
        cli.exec_bg("aplay " .. cli.shell_quote(found))
      end
      return
    end
  end
end

---@param target string
---@param body? string
---@param swappy? boolean
---@return nil
local function notify_saved(target, body, swappy)
  if not cli.file_exists(target) then
    cli.notify_warn("Screenshot", "Not saved.", "shot-notify")
    M.sound("error")
    return
  end

  M.sound("screenshot")
  local action = cli.notify_action(
    "Screenshot",
    body or "Saved.",
    10000,
    { "action1=Open", "action2=Delete" },
    "shot-notify"
  )

  if action == "action1" then
    if swappy then
      cli.exec_bg("swappy -f " .. cli.shell_quote(target))
    else
      cli.exec_bg("xdg-open " .. cli.shell_quote(target))
    end
  elseif action == "action2" then
    os.remove(target)
  end
end

---@param seconds integer
---@return nil
local function countdown(seconds)
  for sec = seconds, 1, -1 do
    cli.notify(
      "Screenshot",
      "Capturing in " .. sec .. "s",
      "low",
      "shot-notify",
      1000
    )
    os.execute("sleep 1")
  end
end

---@param mode? Hyprconf.ScreenshotMode
---@return nil
function M.screenshot(mode)
  local pictures = cli.capture("xdg-user-dir PICTURES")
  if pictures == "" then
    pictures = cli.home .. "/Pictures"
  end
  local dir = pictures .. "/Screenshots"
  cli.mkdir_p(dir)

  local stamp = os.date("%d-%b_%H-%M-%S")
  math.randomseed(os.time())
  local file = "Screenshot_"
    .. stamp
    .. "_"
    .. tostring(math.random(10000, 99999))
    .. ".png"
  local path = dir .. "/" .. file

  if mode == "--in5" then
    countdown(5)
  elseif mode == "--in10" then
    countdown(10)
  end

  if mode == "--area" or mode == "--swappy" then
    local tmp = os.tmpname()
    if os.execute('grim -g "$(slurp)" - > ' .. cli.shell_quote(tmp)) then
      if cli.file_exists(tmp) then
        cli.exec("wl-copy < " .. cli.shell_quote(tmp))
        if mode == "--swappy" then
          notify_saved(tmp, "Captured by Swappy.", true)
        else
          cli.exec(
            "mv " .. cli.shell_quote(tmp) .. " " .. cli.shell_quote(path)
          )
          notify_saved(path)
        end
      end
    else
      os.remove(tmp)
    end
    return
  end

  if mode == "--active" or mode == "--win" then
    ---@type Hyprconf.HyprWindow
    local active = cli.hypr_json("activewindow") or {}
    local at = active.at or {}
    local size = active.size or {}
    local class = active.class or "window"
    local active_path = dir .. "/Screenshot_" .. stamp .. "_" .. class .. ".png"
    local geometry = string.format(
      "%s,%s %sx%s",
      at[1] or 0,
      at[2] or 0,
      size[1] or 0,
      size[2] or 0
    )
    cli.exec(
      "grim -g "
        .. cli.shell_quote(geometry)
        .. " "
        .. cli.shell_quote(active_path)
    )
    notify_saved(active_path, class .. " saved.")
    return
  end

  cli.exec("grim - | tee " .. cli.shell_quote(path) .. " | wl-copy")
  os.execute("sleep 1")
  notify_saved(path)
end

return M
