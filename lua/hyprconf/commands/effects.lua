local cli = require("hyprconf.cli")
local colors = require("hyprconf.colors")
local common = require("hyprconf.commands.common")

---@class Hyprconf.Commands.Effects
---@field rainbow_border fun()
---@field rainbow_menu fun()
local M = {}

---@return nil
function M.rainbow_border()
  local mode = cli.rainbow_border_mode()
  if mode == "disabled" then
    return
  end

  local active = colors.border_gradient(mode, 10)
  for index, value in ipairs(active) do
    active[index] = string.format("%q", value)
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
  local choice = cli.vicinae_select_marked(labels, {
    navigation_title = "Rainbow Borders",
    section_title = "Modes ({count})",
    placeholder = "Choose a border mode...",
    current = display[cli.rainbow_border_mode()],
    marker = ">",
    no_quick_look = true,
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

return M
