local ctx = require("hyprconf.context")
local fs = require("hyprconf.util.fs")
local hyprctl = require("hyprconf.runtime.hyprctl")
local notify = require("hyprconf.runtime.notify")
local process = require("hyprconf.runtime.process")
local sound = require("hyprconf.commands.sound")

local M = {}
local png = "\137PNG\r\n\26\n"

---@param mode? string
---@return nil
function M.screenshot(mode)
  mode = mode or "--now"
  assert(
    ({
      ["--now"] = true,
      ["--area"] = true,
      ["--swappy"] = true,
      ["--in5"] = true,
      ["--in10"] = true,
      ["--active"] = true,
    })[mode],
    "unknown screenshot mode"
  )
  local delay = mode == "--in5" and 5 or mode == "--in10" and 10 or 0
  for remaining = delay, 1, -1 do
    notify.send(
      "Screenshot",
      "Capturing in " .. remaining .. "s",
      { tag = "shot-notify", timeout = 1000 }
    )
    process.check(process.run({ "sleep", "1" }), "screenshot countdown")
  end

  local command = { "grim" }
  local suffix
  if mode == "--area" or mode == "--swappy" then
    local selection = process.run({ "slurp" }, { timeout = false })
    if
      selection.code == 1
      and selection.stdout == ""
      and selection.stderr == ""
    then
      return
    end
    process.check(selection, "screen selection")
    local geometry = selection.stdout:gsub("%s+$", "")
    assert(
      geometry:match("^%-?%d+,%-?%d+ %d+x%d+$"),
      "invalid screenshot selection"
    )
    command[#command + 1], command[#command + 2] = "-g", geometry
  elseif mode == "--active" then
    ---@type Hyprconf.HyprWindow
    local active = hyprctl.active_window()
    local at, size = active.at, active.size
    assert(
      at and size and #at == 2 and #size == 2 and size[1] > 0 and size[2] > 0,
      "no active window with valid screenshot geometry"
    )
    command[#command + 1], command[#command + 2] =
      "-g", string.format("%d,%d %dx%d", at[1], at[2], size[1], size[2])
    suffix = (active.class or "window"):gsub("[^%w_.-]", "_")
  end
  command[#command + 1] = "-"
  local image = process.check(process.run(command), "screenshot capture").stdout
  assert(
    image:sub(1, #png) == png and #image > #png,
    "screenshot capture produced no PNG image"
  )

  local pictures = process
    .check(process.run({ "xdg-user-dir", "PICTURES" }), "pictures directory").stdout
    :gsub("%s+$", "")
  local directory = (pictures ~= "" and pictures or ctx.home .. "/Pictures")
    .. "/Screenshots"
  fs.mkdir_p(directory)
  local temporary = process
    .check(
      process.run({ "mktemp", directory .. "/.capture.XXXXXX" }),
      "screenshot temporary file"
    ).stdout
    :gsub("%s+$", "")
  local ok, err = pcall(function()
    fs.write(temporary, image)
    local target = temporary
    if mode ~= "--swappy" then
      local base = directory
        .. "/Screenshot_"
        .. os.date("%Y-%m-%d_%H-%M-%S")
        .. (suffix and ("_" .. suffix) or "")
      local index = 1
      while true do
        target = base .. (index > 1 and ("_" .. index) or "") .. ".png"
        local linked = process.run({ "ln", "--", temporary, target })
        if linked.ok then
          break
        end
        if not fs.exists(target) then
          process.check(linked, "screenshot publication")
        end
        index = index + 1
      end
    end
    local copied = process.run(
      { "wl-copy", "--type", "image/png" },
      { stdin = image }
    )
    if not copied.ok then
      if mode ~= "--swappy" then
        notify.warn(
          "Screenshot",
          "Saved; clipboard copy failed.",
          "shot-notify"
        )
      end
      process.check(copied, "screenshot clipboard copy")
    end
    pcall(sound.sound, "screenshot")
    local action = notify.send(
      "Screenshot",
      mode == "--swappy" and "Captured by Swappy." or "Saved.",
      {
        tag = "shot-notify",
        timeout = 10000,
        actions = { "action1=Open", "action2=Delete" },
      }
    )
    if action == "action1" then
      if mode == "--swappy" then
        process.check(
          process.run({ "swappy", "-f", target }, { timeout = false }),
          "Swappy"
        )
      else
        require("hyprconf.util.shell").exec_bg(
          "xdg-open " .. require("hyprconf.util.shell").quote(target)
        )
      end
    elseif action == "action2" then
      assert(os.remove(target))
    end
  end)
  if fs.exists(temporary) then
    assert(os.remove(temporary))
  end
  if not ok then
    error(err, 0)
  end
end

return M
