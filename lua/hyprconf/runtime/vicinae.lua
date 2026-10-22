local fs = require("hyprconf.util.fs")
local notify = require("hyprconf.runtime.notify")
local shell = require("hyprconf.util.shell")

---@class Hyprconf.VicinaeOptions
---@field navigation_title? string Window navigation title.
---@field section_title? string Main section title; `{count}` expands to the row count.
---@field placeholder? string Search field placeholder.
---@field query? string Initial search query.
---@field no_section? boolean Hide the main section heading.
---@field no_quick_look? boolean Disable file quick look.
---@field current? string Row to mark as active, for `select`.

---@class Hyprconf.Runtime.Vicinae
local M = {}

local marker = ">"

---@type [string, string][]
local value_flags = {
  { "navigation_title", "--navigation-title" },
  { "section_title", "--section-title" },
  { "placeholder", "--placeholder" },
  { "query", "--query" },
}

---@type [string, string][]
local switch_flags = {
  { "no_section", "--no-section" },
  { "no_quick_look", "--no-quick-look" },
}

---@param lines string[]
---@param opts? Hyprconf.VicinaeOptions
---@return string output Selected row or typed query.
---@return integer status Vicinae's exit status; non-zero when dismissed.
function M.dmenu(lines, opts)
  opts = opts or {}
  if not notify.require_command("vicinae", "Install Vicinae first.") then
    return "", 1
  end

  local args = { "vicinae", "dmenu" }
  for _, flag in ipairs(value_flags) do
    local value = opts[flag[1]]
    if value and value ~= "" then
      args[#args + 1] = flag[2] .. " " .. shell.quote(value)
    end
  end
  for _, flag in ipairs(switch_flags) do
    if opts[flag[1]] then
      args[#args + 1] = flag[2]
    end
  end

  local input = os.tmpname()
  local status_file = os.tmpname()
  fs.write(input, table.concat(lines, "\n") .. "\n")
  local output = shell.capture(
    table.concat(args, " ")
      .. " < "
      .. shell.quote(input)
      .. "; printf $? > "
      .. shell.quote(status_file)
  )
  local status = tonumber(fs.read(status_file) or "") or 1
  os.remove(input)
  os.remove(status_file)
  return output, status
end

-- Shows `labels` with `opts.current` marked and returns the chosen label.
---@param labels string[]
---@param opts? Hyprconf.VicinaeOptions
---@return string?
function M.select(labels, opts)
  opts = opts or {}
  local rows = {}
  for index, label in ipairs(labels) do
    rows[index] = label == opts.current and (marker .. " " .. label) or label
  end

  local choice, status = M.dmenu(rows, opts)
  if status ~= 0 or choice == "" then
    return nil
  end
  return (choice:gsub("^" .. marker .. "%s+", ""))
end

return M
