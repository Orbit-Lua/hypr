local colors = require("hyprconf.colors")
local ctx = require("hyprconf.context")
local fs = require("hyprconf.util.fs")
local hyprctl = require("hyprconf.runtime.hyprctl")
local declarations = require("hyprconf.config")
local vicinae = require("hyprconf.runtime.vicinae")
local state = require("hyprconf.runtime.state")

---@alias Hyprconf.RainbowBorderMode "disabled"|"gradient_flow"|"material_random"|"rainbow"

---@class Hyprconf.Commands.Effects
local M = {}

-- Written by the rainbow menu; effects.toml sets the mode without it.
local mode_file = ctx.state_dir .. "/effects/rainbow-border-mode"

---@type [Hyprconf.RainbowBorderMode, string][]
local modes = declarations.border_modes

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
local function rainbow_mode()
  local saved = fs.read(mode_file)
  if saved then
    assert(
      saved:match("^%s*[%w_]+%s*$") and parse_mode(saved),
      "invalid saved border mode"
    )
  end
  return parse_mode(saved)
    or parse_mode((declarations.read("effects").rainbow or {}).default)
    or "disabled"
end

-- Applies the current mode's gradient to the active border.
---@return nil
function M.rainbow_border()
  local active = colors.border_gradient(rainbow_mode(), 10)
  if #active == 0 then
    return
  end
  hyprctl.config({
    general = { col = { active_border = { colors = active, angle = 270 } } },
  })
end

---@return nil
function M.rainbow_menu()
  local active = rainbow_mode()
  ---@type Hyprconf.MenuChoice[]
  local labels = {}
  for index, mode in ipairs(modes) do
    labels[index] = { id = mode[1], label = mode[2] }
  end

  local choice = vicinae.select(labels, {
    navigation_title = "Rainbow Borders",
    section_title = "Modes ({count})",
    placeholder = "Choose a border mode...",
    current = active,
    no_quick_look = true,
  })
  for _, mode in ipairs(modes) do
    if mode[1] == choice then
      state.change(mode_file, mode[1] .. "\n", function()
        if rainbow_mode() == "disabled" then
          hyprctl.reload()
        else
          M.rainbow_border()
        end
      end)
      return
    end
  end
end

return M
