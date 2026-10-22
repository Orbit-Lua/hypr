local ctx = require("hyprconf.context")
local fs = require("hyprconf.util.fs")
local hyprctl = require("hyprconf.runtime.hyprctl")
local notify = require("hyprconf.runtime.notify")
local profile = require("hyprconf.profile")
local vicinae = require("hyprconf.runtime.vicinae")

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

  local files =
    fs.list_files(ctx.config_dir .. "/profiles/" .. category, "*.lua")
  if #files == 0 then
    notify.error("Profile Selector", "No " .. category .. " profiles found.")
    return
  end

  local active = profile.active_name(category)
  local labels = {}
  local current
  for index, file in ipairs(files) do
    labels[index] = profile.label(file)
    if fs.stem(file) == active then
      current = labels[index]
    end
  end

  local title = category:gsub("^%l", string.upper) .. " Profile"
  local choice = vicinae.select(labels, {
    navigation_title = title,
    section_title = "Profiles ({count})",
    placeholder = "Choose a " .. category .. " profile...",
    current = current,
    no_quick_look = true,
  })
  for index, label in ipairs(labels) do
    if label == choice then
      fs.write(profile.selection_file(category), fs.stem(files[index]) .. "\n")
      notify.info(title, label .. " loaded", category .. "-profile")
      hyprctl.reload()
      return
    end
  end
end

return M
