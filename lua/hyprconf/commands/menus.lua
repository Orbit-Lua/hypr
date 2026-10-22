local ctx = require("hyprconf.context")
local keymap = require("hyprconf.keymap")
local notify = require("hyprconf.runtime.notify")
local shell = require("hyprconf.util.shell")
local toml = require("hyprconf.util.toml")
local vicinae = require("hyprconf.runtime.vicinae")

---@class Hyprconf.KeyHintRow
---@field key? string
---@field description? string
---@field command? string

---@class Hyprconf.KeyHintsConfig
---@field row? Hyprconf.KeyHintRow[]

---@alias Hyprconf.QuickSettingKind "header"|"edit"|"exec"|"action"

---@class Hyprconf.QuickSettingItem
---@field label string
---@field kind Hyprconf.QuickSettingKind
---@field path? string File to edit, relative to the configuration root.
---@field require? string Command that must exist before `command` runs.
---@field command? string Shell command, or helper CLI arguments for actions.

---@class Hyprconf.QuickSettingsConfig
---@field item? Hyprconf.QuickSettingItem[]

---@class Hyprconf.Commands.Menus
local M = {}

---@return nil
function M.key_hints()
  ---@type Hyprconf.KeyHintsConfig
  local config = toml.read(ctx.config_file("key-hints"))
  shell.kill("yad")

  local args = {
    "GDK_BACKEND=wayland",
    "yad",
    "--center",
    "--title=" .. shell.quote("Quick Cheat Sheet"),
    "--no-buttons",
    "--list",
    "--column=Key:",
    "--column=Description:",
    "--column=Command:",
    "--timeout-indicator=bottom",
  }
  for _, row in ipairs(config.row or {}) do
    args[#args + 1] = shell.quote(row.key or "")
    args[#args + 1] = shell.quote(row.description or "")
    args[#args + 1] = shell.quote(row.command or "")
  end

  shell.exec_bg(table.concat(args, " "))
end

---@return nil
function M.keybinds()
  shell.kill("yad")

  local lines = {}
  for _, entry in ipairs(keymap.collect()) do
    if entry.description then
      lines[#lines + 1] =
        string.format("%-32s %s", entry.keys, entry.description)
    end
  end

  vicinae.dmenu(lines, {
    navigation_title = "Hyprland Keybinds",
    section_title = "Bindings ({count})",
    placeholder = "Search keybinds...",
    no_quick_look = true,
  })
end

---@param value string
---@return string
local function urlencode(value)
  return (
    value:gsub("([^%w%-%_%.%~])", function(char)
      return string.format("%%%02X", string.byte(char))
    end)
  )
end

---@return nil
function M.web_search()
  if not notify.require_command("xdg-open", "Install xdg-utils first.") then
    return
  end
  local query, status = vicinae.dmenu({ "" }, {
    navigation_title = "Web Search",
    placeholder = "Search with your default browser...",
    no_section = true,
    no_quick_look = true,
  })
  if status == 0 and query ~= "" then
    shell.exec_bg(
      "xdg-open " .. shell.quote(ctx.search_engine .. urlencode(query))
    )
  end
end

-- Opens a configuration file in the editor. A Nix store deployment is
-- read-only, so editing needs Nacre's live development checkout.
---@param path string
---@return nil
local function edit(path)
  local target = ctx.config_dir .. "/" .. path
  if not os.execute("test -w " .. shell.quote(target)) then
    notify.error(
      "Quick Settings",
      "The deployed configuration is read-only. Point Nacre's development.hyprlandPath at a checkout to edit it live.",
      "quick-settings"
    )
    return
  end
  shell.exec_bg(ctx.term .. " -e " .. ctx.editor .. " " .. shell.quote(target))
end

---@return nil
function M.quick_settings()
  ---@type Hyprconf.QuickSettingsConfig
  local config = toml.read(ctx.config_file("quick-settings"))
  local labels = {}
  ---@type table<string, Hyprconf.QuickSettingItem>
  local by_label = {}
  for _, item in ipairs(config.item or {}) do
    labels[#labels + 1] = item.label
    by_label[item.label] = item
  end

  local choice = vicinae.select(labels, {
    navigation_title = "Hyprland Quick Settings",
    section_title = "Settings ({count})",
    placeholder = "Choose a setting...",
    no_quick_look = true,
  })
  local item = choice and by_label[choice]
  if not item then
    return
  end

  if item.kind == "edit" then
    edit(item.path)
  elseif item.kind == "exec" then
    if not item.require or notify.require_command(item.require) then
      shell.exec_bg(item.command)
    end
  elseif item.kind == "action" then
    shell.exec_bg(ctx.hypr_lua .. " " .. item.command)
  end
end

return M
