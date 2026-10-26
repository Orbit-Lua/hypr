local ctx = require("hyprconf.context")
local keymap = require("hyprconf.keymap")
local notify = require("hyprconf.runtime.notify")
local shell = require("hyprconf.util.shell")
local declarations = require("hyprconf.config")
local process = require("hyprconf.runtime.process")
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

local hints_class = "hypr-key-hints-"
  .. (os.getenv("HYPRLAND_INSTANCE_SIGNATURE") or "default"):gsub(
    "[^%w_-]",
    "_"
  )
local function close_key_hints()
  local result = process.run({
    "pkill",
    "-f",
    "--",
    "^yad --class=" .. hints_class .. "( |$)",
  })
  if result.code ~= 1 then
    process.check(result, "close key hints")
  end
end

---@return nil
function M.key_hints()
  ---@type Hyprconf.KeyHintsConfig
  local config = declarations.read("key-hints")
  close_key_hints()

  local args = {
    "GDK_BACKEND=wayland",
    "yad",
    "--class=" .. hints_class,
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
  close_key_hints()

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

-- Opens a configuration file in the editor. Read-only deployments need
-- a writable checkout for live editing.
---@param path string
---@return nil
local function edit(path)
  local target = ctx.config_dir .. "/" .. path
  if not os.execute("test -w " .. shell.quote(target)) then
    notify.error(
      "Quick Settings",
      "The configuration is read-only. Use a writable checkout as the configuration root to edit it live.",
      "quick-settings"
    )
    return
  end
  shell.exec_bg(ctx.term .. " -e " .. ctx.editor .. " " .. shell.quote(target))
end

---@return nil
function M.quick_settings()
  ---@type Hyprconf.QuickSettingsConfig
  local config = declarations.read("quick-settings")
  ---@type Hyprconf.MenuChoice[]
  local labels = {}
  ---@type table<string, Hyprconf.QuickSettingItem>
  local by_label = {}
  for index, item in ipairs(config.item or {}) do
    labels[#labels + 1] = { id = tostring(index), label = item.label }
    by_label[tostring(index)] = item
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
