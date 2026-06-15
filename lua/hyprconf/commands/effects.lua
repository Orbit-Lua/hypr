local cli = require("hyprconf.cli")
local common = require("hyprconf.commands.common")

---@class Hyprconf.Commands.Effects
---@field rainbow_border fun()
---@field rainbow_menu fun()
---@field noctalia_theme fun()
local M = {}

---@return string[]
local function material_colors()
  local source = cli.effects_dir .. "/colors-hyprland.conf"
  local colors = {}
  local content = cli.read_file(source) or ""

  for line in content:gmatch("[^\n]+") do
    local value = line:match(
      "0x([0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f])"
    ) or line:match(
      "#([0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f])"
    ) or line:match(
      "rgb%(([0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f])%)"
    )
    if value then
      if #value == 6 then
        value = "ff" .. value
      end
      colors[#colors + 1] = "0x" .. value
    end
  end

  return colors
end

---@return nil
function M.rainbow_border()
  local mode = cli.rainbow_border_mode()
  if mode == "disabled" then
    return
  end

  local colors = material_colors()
  if
    (mode == "material_random" or mode == "gradient_flow") and #colors == 0
  then
    mode = "rainbow"
  end

  math.randomseed(os.time() + (tonumber(cli.capture("date +%N")) or 0))

  local glow = 1
  ---@return string
  local function random_hex()
    return string.format("0xff%06x", math.random(0, 0xffffff))
  end

  ---@param index integer
  ---@return string
  local function pick(index)
    if mode == "material_random" and #colors > 0 then
      return colors[math.random(1, #colors)]
    end

    if mode == "gradient_flow" and #colors >= 16 then
      local distance = index - glow
      if distance > 5 then
        distance = distance - 10
      end
      if distance < -5 then
        distance = distance + 10
      end
      if math.abs(distance) == 0 then
        return colors[16]
      elseif math.abs(distance) == 1 then
        return colors[15]
      elseif math.abs(distance) == 2 then
        return colors[14]
      end
      return colors[11]
    end

    return random_hex()
  end

  local active = {}
  for index = 1, 10 do
    active[#active + 1] = string.format("%q", pick(index))
  end

  cli.hypr_config(
    "{ general = { col = { active_border = { colors = { "
      .. table.concat(active, ", ")
      .. " }, angle = 270 } } } }"
  )
end

---@return nil
function M.rainbow_menu()
  local labels = {
    "Disabled",
    "Material Color",
    "Original Rainbow",
    "Gradient Flow",
  }
  ---@type table<Hyprconf.RainbowBorderMode, string>
  local display = {
    disabled = "Disabled",
    material_random = "Material Color",
    rainbow = "Original Rainbow",
    gradient_flow = "Gradient Flow",
  }
  ---@type table<string, Hyprconf.RainbowBorderMode>
  local modes = {
    ["Disabled"] = "disabled",
    ["Material Color"] = "material_random",
    ["Original Rainbow"] = "rainbow",
    ["Gradient Flow"] = "gradient_flow",
  }
  local choice = cli.rofi_select_marked(labels, {
    config = cli.rofi_config_dir .. "/config-edit.rasi",
    message = "Rainbow Borders",
    current = display[cli.rainbow_border_mode()],
    marker = ">",
  })
  if not choice then
    return
  end

  cli.write_file(cli.rainbow_mode_file, modes[choice] .. "\n")
  cli.exec_bg(common.lua_cmd("refresh"))
  if modes[choice] ~= "disabled" then
    cli.exec_bg(common.lua_cmd("rainbow-border"))
  else
    cli.exec("hyprctl reload >/dev/null 2>&1 || true")
  end
end

---@return nil
function M.noctalia_theme()
  local ok = require("hyprconf.theme.noctalia").apply()
  os.exit(ok and 0 or 1)
end

return M
