local cli = require("hyprconf.cli")
local common = require("hyprconf.commands.common")
local toml = require("hyprconf.util.toml")

---@class Hyprconf.PolkitConfig
---@field paths? string[]

---@class Hyprconf.Commands.Services
---@field polkit fun()
---@field portal_hyprland fun()
---@field refresh fun()
local M = {}

---@return nil
function M.polkit()
  ---@type Hyprconf.PolkitConfig
  local data = toml.read(common.config("polkit"))
  for _, path in ipairs(data.paths or {}) do
    if cli.file_exists(path) then
      os.execute(cli.shell_quote(path))
      return
    end
  end
  io.stderr:write("No valid Polkit agent found. Please install one.\n")
end

---@return nil
function M.portal_hyprland()
  ---@param name string
  ---@return nil
  local function kill(name)
    cli.exec("pkill -x " .. cli.shell_quote(name) .. " 2>/dev/null || true")
  end
  ---@param paths string[]
  ---@return nil
  local function start(paths)
    for _, path in ipairs(paths) do
      if cli.file_exists(path) then
        cli.exec_bg(cli.shell_quote(path))
        return
      end
    end
  end

  os.execute("sleep 1")
  kill("xdg-desktop-portal-hyprland")
  kill("xdg-desktop-portal-wlr")
  kill("xdg-desktop-portal-gnome")
  kill("xdg-desktop-portal")
  os.execute("sleep 1")
  start({
    "/usr/lib/xdg-desktop-portal-hyprland",
    "/usr/libexec/xdg-desktop-portal-hyprland",
  })
  os.execute("sleep 2")
  start({ "/usr/lib/xdg-desktop-portal", "/usr/libexec/xdg-desktop-portal" })
end

---@return nil
function M.refresh()
  if cli.rainbow_border_mode() ~= "disabled" then
    cli.exec_bg(common.lua_cmd("rainbow-border"))
  end
end

return M
