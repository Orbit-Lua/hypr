local cli = require("hyprconf.cli")
local common = require("hyprconf.commands.common")
local toml = require("hyprconf.util.toml")

---@class Hyprconf.ProfileTargetSpec
---@field target? string Active profile target path relative to config root.

---@alias Hyprconf.ProfilesConfig table<string, Hyprconf.ProfileTargetSpec>

---@class Hyprconf.Commands.Profiles
---@field profile_selector fun(category?: Hyprconf.ProfileCategory)
local M = {}

---@param path string
---@return string
local function profile_label(path)
  local content = cli.read_file(path) or ""
  return content:match("^%-%- profile:%s*([^\n]+)")
    or common.without_suffix(common.basename(path), ".lua")
end

---@param category Hyprconf.ProfileCategory
---@return string
local function profile_target(category)
  ---@type Hyprconf.ProfilesConfig
  local data = toml.read(common.config("profiles"))
  local spec = data[category] or {}
  return cli.config_dir
    .. "/"
    .. (spec.target or ("lua/user/" .. category .. ".lua"))
end

---@param category Hyprconf.ProfileCategory
---@param profile_dir string
---@param active_profile string
---@return string?
local function current_profile_key(category, profile_dir, active_profile)
  local state = cli.config_dir .. "/profiles/.selected/" .. category
  local selected = cli.read_file(state)
  if selected then
    selected = selected:match("^%s*(%S+)")
    if
      selected and cli.file_exists(profile_dir .. "/" .. selected .. ".lua")
    then
      return selected
    end
  end

  local active = cli.read_file(active_profile)
  if not active then
    return nil
  end

  for _, file in ipairs(cli.list_files(profile_dir, "*.lua")) do
    if cli.read_file(file) == active then
      return common.without_suffix(common.basename(file), ".lua")
    end
  end
end

---@param category? Hyprconf.ProfileCategory
---@return nil
function M.profile_selector(category)
  local root = cli.config_dir .. "/profiles"
  if not category or category == "" then
    category = cli.vicinae_select_marked(cli.list_dirs(root), {
      navigation_title = "Hyprland Profiles",
      section_title = "Categories ({count})",
      placeholder = "Choose a profile category...",
      marker = ">",
      no_quick_look = true,
    })
    if not category then
      return
    end
  end

  local profile_dir = root .. "/" .. category
  local profiles = cli.list_files(profile_dir, "*.lua")
  if #profiles == 0 then
    cli.notify_error(
      "Profile Selector",
      "No Lua profiles found in " .. profile_dir
    )
    return
  end

  local labels = {}
  local current =
    current_profile_key(category, profile_dir, profile_target(category))
  local current_label = ""
  for index, file in ipairs(profiles) do
    labels[index] = profile_label(file)
    if common.without_suffix(common.basename(file), ".lua") == current then
      current_label = labels[index]
    end
  end

  local title = category:gsub("^%l", string.upper) .. " Profile"
  local selected = cli.vicinae_select_marked(labels, {
    navigation_title = title,
    section_title = "Profiles ({count})",
    placeholder = "Choose a " .. category .. " profile...",
    current = current_label,
    marker = ">",
    no_quick_look = true,
  })
  if not selected then
    return
  end

  for index, label in ipairs(labels) do
    if label == selected then
      local source = profiles[index]
      cli.copy_file(source, profile_target(category))
      cli.write_file(
        root .. "/.selected/" .. category,
        common.without_suffix(common.basename(source), ".lua") .. "\n"
      )
      cli.notify_success(
        category:gsub("^%l", string.upper) .. " Profile",
        selected .. " loaded",
        category .. "-profile"
      )
      cli.exec("hyprctl reload >/dev/null 2>&1 || true")
      return
    end
  end
end

return M
