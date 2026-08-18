local cli = require("hyprconf.cli")
local common = require("hyprconf.commands.common")
local ctx = require("hyprconf.context")
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
---@field zsh_theme fun()
---@field kitty_themes fun()
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
  local path = cli.config_dir .. "/lua/hyprconf/binds.lua"
  for line in io.lines(path) do
    if line:match("^%s*bind[_%w]*%(") then
      lines[#lines + 1] = line:gsub("^%s+", ""):gsub("%s+$", "")
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

---@return nil
function M.zsh_theme()
  local themes_dir = cli.home .. "/.oh-my-zsh/themes"
  local files = cli.list_files(themes_dir, "*.zsh-theme")
  local labels = { "Random" }
  for _, file in ipairs(files) do
    labels[#labels + 1] =
      common.without_suffix(common.basename(file), ".zsh-theme")
  end

  local choice = cli.vicinae_select_marked(labels, {
    navigation_title = "Zsh Theme",
    section_title = "Themes ({count})",
    placeholder = "Choose an oh-my-zsh theme...",
    no_quick_look = true,
  })
  if not choice then
    return
  end

  if choice == "Random" and #labels > 1 then
    math.randomseed(os.time())
    choice = labels[math.random(2, #labels)]
    cli.notify_info("Zsh Theme", "Random: " .. choice, "zsh-theme")
  else
    cli.notify_info("Zsh Theme", "Selected: " .. choice, "zsh-theme")
  end

  local zshrc = cli.home .. "/.zshrc"
  local content = cli.read_file(zshrc)
  if not content then
    cli.notify_error("OMZ Theme", "~/.zshrc file not found.", "zsh-theme")
    return
  end

  content = content:gsub('ZSH_THEME="[^"]*"', 'ZSH_THEME="' .. choice .. '"')
  content = content:gsub("ZSH_THEME='[^']*'", 'ZSH_THEME="' .. choice .. '"')
  content = content:gsub("ZSH_THEME=[^\n]*", 'ZSH_THEME="' .. choice .. '"')
  cli.write_file(zshrc, content)
  cli.notify_success(
    "OMZ Theme",
    "Applied. Restart your terminal.",
    "zsh-theme"
  )
end

---@return nil
function M.kitty_themes()
  local themes_dir = cli.home .. "/.config/kitty/kitty-themes"
  local kitty_config = cli.home .. "/.config/kitty/kitty.conf"
  if not cli.file_exists(kitty_config) then
    cli.notify_error(
      "Kitty Theme",
      "Kitty config not found: " .. kitty_config,
      "kitty-theme"
    )
    return
  end

  local files = cli.list_files(themes_dir, "*.conf")
  if #files == 0 then
    cli.notify_error(
      "Kitty Theme",
      "No .conf files found in " .. themes_dir,
      "kitty-theme"
    )
    return
  end

  local themes = {}
  for index, file in ipairs(files) do
    themes[index] = common.without_suffix(common.basename(file), ".conf")
  end

  ---@return nil
  local function reload_kitty()
    cli.exec("pidof kitty | xargs -r -I{} kill -SIGUSR1 {} 2>/dev/null || true")
  end

  ---@param name string
  ---@return nil
  local function apply(name)
    local content = cli.read_file(kitty_config) or ""
    local line = "include ./kitty-themes/" .. name .. ".conf"
    if content:match("include%s+%./kitty%-themes/[^%s]+%.conf") then
      content = content:gsub("include%s+%./kitty%-themes/[^%s]+%.conf", line)
    else
      content = content .. "\n" .. line .. "\n"
    end
    cli.write_file(kitty_config, content)
    reload_kitty()
  end

  local content = cli.read_file(kitty_config) or ""
  local active = content:match("include%s+%./kitty%-themes/([^%s]+)%.conf")
  local current = ""
  if active then
    for _, name in ipairs(themes) do
      if name == active then
        current = name
        break
      end
    end
  end

  local selected = cli.vicinae_select_marked(themes, {
    navigation_title = "Kitty Theme",
    section_title = "Themes ({count})",
    placeholder = "Choose and apply a Kitty theme...",
    current = current,
    no_quick_look = true,
  })
  if selected then
    apply(selected)
    cli.notify_success("Kitty Theme Applied", selected, "kitty-theme")
  end
end

return M
