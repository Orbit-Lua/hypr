local json = require("hyprconf.util.json")

---@alias Hyprconf.CommandStatus boolean|integer|nil
---@alias Hyprconf.NotifyUrgency "low"|"normal"|"critical"
---@alias Hyprconf.RainbowBorderMode "disabled"|"gradient_flow"|"material_random"|"rainbow"

---@class Hyprconf.RofiCustomBinding
---@field [1] string Rofi option name.
---@field [2] string Keybinding value.

---@class Hyprconf.RofiDmenuOptions
---@field config? string Rofi config path.
---@field message? string Rofi message.
---@field prompt? string Rofi prompt.
---@field format? string Rofi output format.
---@field selected_row? integer Zero-based selected row.
---@field custom? Hyprconf.RofiCustomBinding[] Extra option/value pairs.

---@class Hyprconf.RofiMarkedOptions: Hyprconf.RofiDmenuOptions
---@field marker? string Prefix for the active row.
---@field current? string Active label.

---@class Hyprconf.HyprOption
---@field int? integer
---@field str? string
---@field float? number
---@field set? boolean

---@class Hyprconf.HyprWindow
---@field pid? integer|string
---@field at? integer[]
---@field size? integer[]
---@field class? string

---@class Hyprconf.Cli
---@field home string
---@field config_dir string
---@field rofi_config_dir string
---@field effects_dir string
---@field rainbow_mode_file string
---@field notify_app_name string
---@field notify_timeout integer
---@field fallback_icon string
local M = {}

M.home = os.getenv("HOME") or ""
M.config_dir = os.getenv("HYPR_CONFIG_DIR") or (M.home .. "/.config/hypr")
M.rofi_config_dir = os.getenv("ROFI_CONFIG_DIR") or (M.home .. "/.config/rofi")
M.effects_dir = os.getenv("EFFECTS_DIR") or (M.config_dir .. "/effects")
M.rainbow_mode_file = os.getenv("RAINBOW_BORDER_MODE_FILE")
  or (M.effects_dir .. "/rainbow-border-mode")
M.notify_app_name = os.getenv("NOTIFY_APP_NAME") or "Hyprland"
M.notify_timeout = tonumber(os.getenv("NOTIFY_DEFAULT_TIMEOUT") or "3000")
M.fallback_icon = os.getenv("NOTIFY_FALLBACK_ICON") or ""

---@param value any
---@return string
function M.shell_quote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

---@param value any
---@return string
function M.lua_string(value)
  return string.format("%q", tostring(value))
end

---@param path string
---@return string?
function M.read_file(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end
  local content = file:read("*a")
  file:close()
  return content
end

---@param path string
---@param content string
---@return nil
function M.write_file(path, content)
  M.mkdir_p(path:match("(.+)/[^/]+$"))
  local file = assert(io.open(path, "w"))
  file:write(content)
  file:close()
end

---@param path string
---@return boolean
function M.file_exists(path)
  local file = io.open(path, "r")
  if file then
    file:close()
    return true
  end
  return false
end

---@param path string?
---@return nil
function M.mkdir_p(path)
  if path and path ~= "" then
    os.execute("mkdir -p " .. M.shell_quote(path))
  end
end

---@param command string
---@return Hyprconf.CommandStatus
function M.exec(command)
  return os.execute(command)
end

---@param command string
---@return Hyprconf.CommandStatus
function M.exec_bg(command)
  return os.execute(command .. " >/dev/null 2>&1 &")
end

---@param command string
---@return string
function M.capture(command)
  local handle = io.popen(command .. " 2>/dev/null")
  if not handle then
    return ""
  end
  local output = handle:read("*a") or ""
  handle:close()

  -- only need first return (string), second one is count
  return (output:gsub("%s+$", ""))
end

---@param command string
---@return boolean
function M.command_exists(command)
  return os.execute(
    "command -v " .. M.shell_quote(command) .. " >/dev/null 2>&1"
  ) == true
end

---@param command string
---@param hint? string
---@return boolean
function M.require_command(command, hint)
  if M.command_exists(command) then
    return true
  end
  M.notify_error(
    "Missing Dependency",
    hint or ("Install " .. command .. " first.")
  )
  return false
end

---@param title string
---@param body? string
---@param urgency? Hyprconf.NotifyUrgency
---@param tag? string
---@param timeout? integer|false
---@param icon? string
---@return nil
function M.notify(title, body, urgency, tag, timeout, icon)
  local args = {
    "notify-send",
    "-a",
    M.shell_quote(M.notify_app_name),
    "-u",
    M.shell_quote(urgency or "low"),
    "-h",
    M.shell_quote(
      "string:x-canonical-private-synchronous:" .. (tag or "hypr-notify")
    ),
  }

  if timeout ~= false then
    args[#args + 1] = "-t"
    args[#args + 1] = tostring(timeout or M.notify_timeout)
  end

  icon = icon or M.fallback_icon
  if icon ~= "" and M.file_exists(icon) then
    args[#args + 1] = "-i"
    args[#args + 1] = M.shell_quote(icon)
  end

  args[#args + 1] = M.shell_quote(title)
  args[#args + 1] = M.shell_quote(body or "")

  os.execute(table.concat(args, " ") .. " >/dev/null 2>&1 || true")
end

---@param title string
---@param body? string
---@param tag? string
---@return nil
function M.notify_info(title, body, tag)
  M.notify(title, body, "low", tag or "hypr-info")
end

---@param title string
---@param body? string
---@param tag? string
---@return nil
function M.notify_success(title, body, tag)
  M.notify(title, body, "low", tag or "hypr-success")
end

---@param title string
---@param body? string
---@param tag? string
---@return nil
function M.notify_warn(title, body, tag)
  M.notify(title, body, "normal", tag or "hypr-warn")
end

---@param title string
---@param body? string
---@param tag? string
---@return nil
function M.notify_error(title, body, tag)
  M.notify(title, body, "critical", tag or "hypr-error")
end

---@param title string
---@param body? string
---@param timeout_ms? integer
---@param actions? string[]
---@param tag? string
---@return string
function M.notify_action(title, body, timeout_ms, actions, tag)
  local args = {
    "notify-send",
    "-e",
    "-a",
    M.shell_quote(M.notify_app_name),
    "-t",
    tostring(timeout_ms or 10000),
    "-h",
    M.shell_quote(
      "string:x-canonical-private-synchronous:" .. (tag or "hypr-action")
    ),
  }

  for _, action in ipairs(actions or {}) do
    args[#args + 1] = "-A"
    args[#args + 1] = M.shell_quote(action)
  end

  args[#args + 1] = M.shell_quote(title)
  args[#args + 1] = M.shell_quote(body or "")

  return M.capture(table.concat(args, " "))
end

---@param ... string
---@return nil
function M.kill_by_name(...)
  for _, proc in ipairs({ ... }) do
    os.execute("pkill -x " .. M.shell_quote(proc) .. " 2>/dev/null || true")
  end
end

---@return nil
function M.rofi_close()
  M.kill_by_name("rofi")
end

---@param lines string[]
---@return string
local function temp_input(lines)
  local path = os.tmpname()
  M.write_file(path, table.concat(lines, "\n") .. "\n")
  return path
end

---@param lines string[]?
---@param opts? Hyprconf.RofiDmenuOptions
---@return string output
---@return integer status
function M.rofi_dmenu(lines, opts)
  opts = opts or {}
  local path = temp_input(lines or { "" })
  local args = { "rofi", "-i", "-dmenu" }
  if opts.config and opts.config ~= "" then
    args[#args + 1] = "-config"
    args[#args + 1] = M.shell_quote(opts.config)
  end
  if opts.message and opts.message ~= "" then
    args[#args + 1] = "-mesg"
    args[#args + 1] = M.shell_quote(opts.message)
  end
  if opts.prompt then
    args[#args + 1] = "-p"
    args[#args + 1] = M.shell_quote(opts.prompt)
  end
  if opts.format then
    args[#args + 1] = "-format"
    args[#args + 1] = M.shell_quote(opts.format)
  end
  if opts.selected_row then
    args[#args + 1] = "-selected-row"
    args[#args + 1] = tostring(opts.selected_row)
  end
  for _, custom in ipairs(opts.custom or {}) do
    args[#args + 1] = custom[1]
    args[#args + 1] = M.shell_quote(custom[2])
  end

  local status_file = os.tmpname()
  local command = table.concat(args, " ")
    .. " < "
    .. M.shell_quote(path)
    .. "; printf $? > "
    .. M.shell_quote(status_file)
  local output = M.capture(command)
  local status = tonumber(M.read_file(status_file) or "1") or 1
  os.remove(path)
  os.remove(status_file)
  return output, status
end

---@param labels string[]
---@param opts? Hyprconf.RofiMarkedOptions
---@return string? choice
---@return integer status
function M.rofi_select_marked(labels, opts)
  opts = opts or {}
  local marker = opts.marker or ">"
  local current = opts.current or ""
  local selected_row = 0
  local rows = {}

  for index, label in ipairs(labels) do
    if label == current then
      rows[index] = marker .. " " .. label
      selected_row = index - 1
    else
      rows[index] = label
    end
  end

  local choice, status = M.rofi_dmenu(rows, {
    config = opts.config,
    message = opts.message,
    selected_row = selected_row,
  })
  if status ~= 0 or choice == "" then
    return nil, status
  end
  return choice:gsub("^" .. marker:gsub("(%W)", "%%%1") .. "%s+", ""), status
end

---@param code string
---@return Hyprconf.CommandStatus
function M.hypr_eval(code)
  return os.execute(
    "hyprctl eval " .. M.shell_quote(code) .. " >/dev/null 2>&1"
  )
end

---@param code string
---@return Hyprconf.CommandStatus
function M.hypr_config(code)
  return M.hypr_eval("hl.config(" .. code .. ")")
end

---@param option string
---@return Hyprconf.HyprOption
function M.hypr_option(option)
  local content = M.capture("hyprctl -j getoption " .. M.shell_quote(option))
  local ok, value = pcall(json.decode, content)
  if not ok then
    return {}
  end
  return value
end

---@param command string
---@return Hyprconf.JsonValue?
function M.hypr_json(command)
  local content = M.capture("hyprctl -j " .. command)
  local ok, value = pcall(json.decode, content)
  if not ok then
    return nil
  end
  return value
end

---@param dir string
---@param pattern? string
---@return string[]
function M.list_files(dir, pattern)
  local suffix = pattern or ""
  local cmd = "find -L "
    .. M.shell_quote(dir)
    .. " -maxdepth 1 -type f "
    .. (suffix ~= "" and ("-name " .. M.shell_quote(suffix) .. " ") or "")
    .. "-print | sort -V"
  local files = {}
  for file in (M.capture(cmd) .. "\n"):gmatch("([^\n]+)\n") do
    files[#files + 1] = file
  end
  return files
end

---@param dir string
---@return string[]
function M.list_dirs(dir)
  local dirs = {}
  local cmd = "find -L "
    .. M.shell_quote(dir)
    .. " -mindepth 1 -maxdepth 1 -type d ! -name '.*' -printf '%f\\n' | sort -V"
  for name in (M.capture(cmd) .. "\n"):gmatch("([^\n]+)\n") do
    dirs[#dirs + 1] = name
  end
  return dirs
end

---@param value any
---@return string
function M.urlencode(value)
  return tostring(value):gsub("([^%w%-%_%.%~])", function(char)
    return string.format("%%%02X", string.byte(char))
  end)
end

---@param source string
---@param target string
---@return Hyprconf.CommandStatus
function M.copy_file(source, target)
  M.mkdir_p(target:match("(.+)/[^/]+$"))
  return os.execute(
    "install -m 0644 " .. M.shell_quote(source) .. " " .. M.shell_quote(target)
  )
end

---@return Hyprconf.RainbowBorderMode
function M.rainbow_border_mode()
  local mode = M.read_file(M.rainbow_mode_file)
  mode = mode and mode:match("^%s*(%S+)") or "disabled"
  if
    mode == "gradient_flow"
    or mode == "material_random"
    or mode == "rainbow"
  then
    return mode
  end
  return "disabled"
end

return M
