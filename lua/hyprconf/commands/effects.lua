local colors = require("hyprconf.colors")
local ctx = require("hyprconf.context")
local fs = require("hyprconf.util.fs")
local hyprctl = require("hyprconf.runtime.hyprctl")
local toml = require("hyprconf.util.toml")
local vicinae = require("hyprconf.runtime.vicinae")

---@alias Hyprconf.RainbowBorderMode "disabled"|"gradient_flow"|"material_random"|"rainbow"

---@class Hyprconf.Commands.Effects
local M = {}

-- Written by the rainbow menu; effects.toml sets the mode without it.
local mode_file = ctx.state_dir .. "/effects/rainbow-border-mode"

---@type [Hyprconf.RainbowBorderMode, string][]
local modes = {
  { "disabled", "Disabled" },
  { "material_random", "Material Color" },
  { "rainbow", "Original Rainbow" },
  { "gradient_flow", "Gradient Flow" },
}

---@param value string?
---@return Hyprconf.RainbowBorderMode?
local function parse_mode(value)
  local name = value and value:match("^%s*(%S+)")
  for _, mode in ipairs(modes) do
    if mode[1] == name then
      return mode[1]
    end
  end
end

---@return Hyprconf.RainbowBorderMode
function M.rainbow_mode()
  return parse_mode(fs.read(mode_file))
    or parse_mode((toml.read(ctx.config_file("effects")).rainbow or {}).default)
    or "disabled"
end

-- Applies the current mode's gradient to the active border.
---@return nil
function M.rainbow_border()
  local active = colors.border_gradient(M.rainbow_mode(), 10)
  if #active == 0 then
    return
  end
  for index, value in ipairs(active) do
    active[index] = string.format("%q", value)
  end

  hyprctl.config(
    "{ general = { col = { active_border = { colors = { "
      .. table.concat(active, ", ")
      .. " }, angle = 270 } } } }"
  )
end

---@return nil
function M.rainbow_menu()
  local labels = {}
  local current
  for index, mode in ipairs(modes) do
    labels[index] = mode[2]
    if mode[1] == M.rainbow_mode() then
      current = mode[2]
    end
  end

  local choice = vicinae.select(labels, {
    navigation_title = "Rainbow Borders",
    section_title = "Modes ({count})",
    placeholder = "Choose a border mode...",
    current = current,
    no_quick_look = true,
  })
  for _, mode in ipairs(modes) do
    if mode[2] == choice then
      fs.write(mode_file, mode[1] .. "\n")
      if mode[1] == "disabled" then
        -- Reloading restores the theme's border.
        hyprctl.reload()
      else
        M.rainbow_border()
      end
      return
    end
  end
end

return M
