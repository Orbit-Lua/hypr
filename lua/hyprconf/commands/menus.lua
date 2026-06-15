local cli = require("hyprconf.cli")
local common = require("hyprconf.commands.common")
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
---@field clip_manager fun()
---@field rofi_search fun()
---@field quick_settings fun()
---@field zsh_theme fun()
---@field rofi_theme fun()
---@field kitty_themes fun()
local M = {}

---@return nil
function M.key_hints()
  ---@type Hyprconf.KeyHintsConfig
  local data = toml.read(common.config("key-hints"))
  cli.rofi_close()
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
  cli.rofi_close()

  local lines = {}
  local path = cli.config_dir .. "/lua/hyprconf/binds.lua"
  for line in io.lines(path) do
    if line:match("^%s*bind[_%w]*%(") then
      lines[#lines + 1] = line:gsub("^%s+", ""):gsub("%s+$", "")
    end
  end

  cli.rofi_dmenu(lines, {
    config = cli.rofi_config_dir .. "/config-keybinds.rasi",
    message = "Browse keybinds",
  })
end

---@return nil
function M.clip_manager()
  if not cli.require_command("cliphist", "Install cliphist first.") then
    return
  end
  if not cli.require_command("wl-copy", "Install wl-clipboard first.") then
    return
  end

  cli.rofi_close()
  while true do
    local result, status =
      cli.rofi_dmenu(common.split_lines(cli.capture("cliphist list")), {
        config = cli.rofi_config_dir .. "/config-clipboard.rasi",
        message = "note: Ctrl+Del = delete entry  |  Alt+Del = wipe all",
        custom = {
          { "-kb-custom-1", "Control-Delete" },
          { "-kb-custom-2", "Alt-Delete" },
        },
      })

    if status == 1 then
      return
    elseif status == 0 and result ~= "" then
      cli.exec(
        "printf %s "
          .. cli.shell_quote(result)
          .. " | cliphist decode | wl-copy"
      )
      return
    elseif status == 10 then
      cli.exec("printf %s " .. cli.shell_quote(result) .. " | cliphist delete")
    elseif status == 11 then
      cli.exec("cliphist wipe")
    else
      return
    end
  end
end

---@return nil
function M.rofi_search()
  if not cli.require_command("xdg-open", "Install xdg-utils first.") then
    return
  end
  cli.rofi_close()
  local query, status = cli.rofi_dmenu({ "" }, {
    config = cli.rofi_config_dir .. "/config-search.rasi",
    message = "Search with your default browser",
  })
  if status == 0 and query ~= "" then
    cli.exec_bg(
      "xdg-open "
        .. cli.shell_quote(
          "https://www.google.com/search?q=" .. cli.urlencode(query)
        )
    )
  end
end

---@return nil
function M.quick_settings()
  if not cli.require_command("rofi", "Install rofi first.") then
    return
  end
  ---@type Hyprconf.QuickSettingsConfig
  local data = toml.read(common.config("quick-settings"))
  local labels = {}
  ---@type table<string, Hyprconf.QuickSettingItem>
  local by_label = {}
  for _, item in ipairs(data.item or {}) do
    labels[#labels + 1] = item.label
    by_label[item.label] = item
  end

  cli.rofi_close()
  local choice = cli.rofi_select_marked(labels, {
    config = cli.rofi_config_dir .. "/config-edit.rasi",
    message = "Choose a setting",
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

  cli.rofi_close()
  local choice = cli.rofi_select_marked(labels, {
    config = cli.rofi_config_dir .. "/config-zsh-theme.rasi",
    message = "",
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

---@return string[] themes
---@return table<string, string> seen
local function rofi_theme_paths()
  local dirs = {
    cli.rofi_config_dir .. "/themes",
    (os.getenv("XDG_DATA_HOME") or (cli.home .. "/.local/share"))
      .. "/rofi/themes",
  }
  local themes = {}
  local seen = {}
  for _, dir in ipairs(dirs) do
    for _, file in ipairs(cli.list_files(dir, "*.rasi")) do
      local name = common.basename(file)
      if not seen[name] then
        seen[name] = file
        themes[#themes + 1] = name
      end
    end
  end
  table.sort(themes)
  return themes, seen
end

---@return nil
function M.rofi_theme()
  if not cli.require_command("rofi", "Install rofi first.") then
    return
  end
  local config_file = cli.rofi_config_dir .. "/config.rasi"
  if not cli.file_exists(config_file) then
    cli.notify_error(
      "Rofi Theme",
      "Rofi config not found: " .. config_file,
      "rofi-theme"
    )
    return
  end

  local themes, seen = rofi_theme_paths()
  if #themes == 0 then
    cli.notify_error("Rofi Theme", "No .rasi themes found.", "rofi-theme")
    return
  end

  ---@param name string
  ---@return boolean
  local function apply(name)
    local path = seen[name]
    if not path then
      return false
    end
    local ref = path:gsub("^" .. cli.home:gsub("(%W)", "%%%1") .. "/", "~/")
    local content = cli.read_file(config_file) or ""
    if content:match('@theme%s+"[^"]+"') then
      content = content:gsub('@theme%s+"[^"]+"', '@theme "' .. ref .. '"')
    else
      content = content .. '\n@theme "' .. ref .. '"\n'
    end
    cli.write_file(config_file, content)
    return true
  end

  local original = cli.read_file(config_file) or ""
  cli.rofi_close()

  local current = 1
  local active = original:match('@theme%s+"([^"]+)"')
  if active then
    local active_name = common.basename(active):lower():gsub("_", "-")
    if active_name == "lonerorz.rasi" then
      active_name = "loner-orz.rasi"
    end
    for index, name in ipairs(themes) do
      if name:lower():gsub("_", "-") == active_name then
        current = index
        break
      end
    end
  end

  while true do
    apply(themes[current])
    local labels = {}
    for index, name in ipairs(themes) do
      labels[index] = common.without_suffix(name, ".rasi")
    end
    local selected, status = cli.rofi_dmenu(labels, {
      config = cli.rofi_config_dir .. "/config-theme-selector.rasi",
      message = "Enter: Preview | Ctrl+S: Apply | Esc: Cancel",
      prompt = "Rofi Theme",
      format = "i",
      selected_row = current - 1,
      custom = { { "-kb-custom-1", "Control+s" } },
    })

    if status == 0 then
      local index = tonumber(selected)
      if index and themes[index + 1] then
        current = index + 1
      end
    elseif status == 10 then
      local index = tonumber(selected)
      if index and themes[index + 1] then
        current = index + 1
      end
      apply(themes[current])
      cli.notify_success(
        "Rofi Theme Applied",
        common.without_suffix(themes[current], ".rasi"),
        "rofi-theme"
      )
      return
    else
      cli.write_file(config_file, original)
      return
    end
  end
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

  local original = cli.read_file(kitty_config) or ""
  local current = 1
  local active = original:match("include%s+%./kitty%-themes/([^%s]+)%.conf")
  if active then
    for index, name in ipairs(themes) do
      if name == active then
        current = index
        break
      end
    end
  end

  while true do
    apply(themes[current])
    local selected, status = cli.rofi_dmenu(themes, {
      config = cli.rofi_config_dir .. "/config-kitty-theme.rasi",
      message = "Preview: "
        .. themes[current]
        .. " | Enter: Preview | Ctrl+S: Apply & Exit | Esc: Cancel",
      prompt = "Kitty Theme",
      format = "i",
      selected_row = current - 1,
      custom = { { "-kb-custom-1", "Control+s" } },
    })

    if status == 0 then
      local index = tonumber(selected)
      if index and themes[index + 1] then
        current = index + 1
      end
    elseif status == 10 then
      cli.notify_success("Kitty Theme Applied", themes[current], "kitty-theme")
      return
    else
      cli.write_file(kitty_config, original)
      reload_kitty()
      return
    end
  end
end

return M
