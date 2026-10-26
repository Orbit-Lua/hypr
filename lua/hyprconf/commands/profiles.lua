local ctx = require("hyprconf.context")
local fs = require("hyprconf.util.fs")
local hyprctl = require("hyprconf.runtime.hyprctl")
local notify = require("hyprconf.runtime.notify")
local profile = require("hyprconf.profile")
local vicinae = require("hyprconf.runtime.vicinae")
local state = require("hyprconf.runtime.state")

---@class Hyprconf.Commands.Profiles
local M = {}

---@param category? Hyprconf.ProfileCategory Asks for one when missing.
---@return nil
function M.profile_selector(category)
  if not category or category == "" then
    category = vicinae.select(profile.categories, {
      navigation_title = "Hyprland Profiles",
      section_title = "Categories ({count})",
      placeholder = "Choose a profile category...",
      no_quick_look = true,
    })
    if not category then
      return
    end
  end

  assert(
    category == "animation" or category == "monitor",
    "invalid profile category"
  )

  local files =
    fs.list_files(ctx.config_dir .. "/profiles/" .. category, "*.lua")
  if #files == 0 then
    notify.error("Profile Selector", "No " .. category .. " profiles found.")
    return
  end

  local active = profile.active_name(category)
  ---@type Hyprconf.MenuChoice[]
  local labels = {}
  for index, file in ipairs(files) do
    labels[index] = { id = fs.stem(file), label = profile.label(file) }
  end

  local title = category:gsub("^%l", string.upper) .. " Profile"
  local choice = vicinae.select(labels, {
    navigation_title = title,
    section_title = "Profiles ({count})",
    placeholder = "Choose a " .. category .. " profile...",
    current = active,
    no_quick_look = true,
  })
  for index, item in ipairs(labels) do
    if item.id == choice then
      state.change(
        profile.selection_file(category),
        fs.stem(files[index]) .. "\n",
        function()
          hyprctl.reload()
          hyprctl.eval(
            string.format(
              "assert(require('hyprconf.profile').loaded[%q] == %q, 'profile did not load')",
              category,
              profile.active_name(category)
            )
          )
        end
      )
      notify.info(title, item.label .. " loaded", category .. "-profile")
      return
    end
  end
end

return M
