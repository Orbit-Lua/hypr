local cli = require("hyprconf.cli")
local common = require("hyprconf.commands.common")
local ctx = require("hyprconf.context")
local keymap = require("hyprconf.keymap")
local toml = require("hyprconf.util.toml")

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
---@field path? string
---@field require? string
---@field command? string

---@class Hyprconf.QuickSettingsConfig
---@field item? Hyprconf.QuickSettingItem[]

---@class Hyprconf.Commands.Menus
---@field key_hints fun()
---@field keybinds fun()
---@field web_search fun()
---@field quick_settings fun()
local M = {}

---@return nil
function M.key_hints()
  ---@type Hyprconf.KeyHintsConfig
  local data = toml.read(common.config("key-hints"))
  cli.kill_by_name("yad")

  local args = {
    "GDK_BACKEND=wayland",
    "yad",
    "--center",
    "--title=" .. cli.shell_quote("Quick Cheat Sheet"),
    "--no-buttons",
    "--list",
    "--column=Key:",
    "--column=Description:",
    "--column=Command:",
    "--timeout-indicator=bottom",
  }

  for _, row in ipairs(data.row or {}) do
    args[#args + 1] = cli.shell_quote(row.key or "")
    args[#args + 1] = cli.shell_quote(row.description or "")
    args[#args + 1] = cli.shell_quote(row.command or "")
  end

  os.execute(table.concat(args, " ") .. " >/dev/null 2>&1 &")
end

---@return nil
function M.keybinds()
  cli.kill_by_name("yad")

  local lines = {}
  for _, entry in ipairs(keymap.collect()) do
    if entry.description then
      lines[#lines + 1] =
        string.format("%-32s %s", entry.keys, entry.description)
    end
  end

  cli.vicinae_dmenu(lines, {
    navigation_title = "Hyprland Keybinds",
    section_title = "Bindings ({count})",
    placeholder = "Search keybinds...",
    no_quick_look = true,
  })
end

---@return nil
function M.web_search()
  if not cli.require_command("xdg-open", "Install xdg-utils first.") then
    return
  end
  local query, status = cli.vicinae_dmenu({}, {
    navigation_title = "Web Search",
    placeholder = "Search with your default browser...",
    no_section = true,
    no_quick_look = true,
  })
  if status == 0 and query ~= "" then
    cli.exec_bg(
      "xdg-open " .. cli.shell_quote(ctx.search_engine .. cli.urlencode(query))
    )
  end
end

---@return nil
function M.quick_settings()
  ---@type Hyprconf.QuickSettingsConfig
  local data = toml.read(common.config("quick-settings"))
  local labels = {}
  ---@type table<string, Hyprconf.QuickSettingItem>
  local by_label = {}
  for _, item in ipairs(data.item or {}) do
    labels[#labels + 1] = item.label
    by_label[item.label] = item
  end

  local choice = cli.vicinae_select_marked(labels, {
    navigation_title = "Hyprland Quick Settings",
    section_title = "Settings ({count})",
    placeholder = "Choose a setting...",
    no_quick_look = true,
  })
  local item = choice and by_label[choice]
  if not item or item.kind == "header" then
    return
  end

  if item.kind == "edit" then
    local term = os.getenv("TERMINAL") or "kitty"
    local editor = os.getenv("EDITOR") or "nvim"
    cli.exec_bg(
      term
        .. " -e "
        .. editor
        .. " "
        .. cli.shell_quote(cli.config_dir .. "/" .. item.path)
    )
  elseif item.kind == "exec" then
    if
      not item.require
      or cli.require_command(
        item.require,
        "Install " .. item.require .. " first."
      )
    then
      cli.exec_bg(item.command)
    end
  elseif item.kind == "action" then
    cli.exec_bg(common.lua_cmd(item.command))
  end
end

return M
