local notify = require("hyprconf.runtime.notify")
local process = require("hyprconf.runtime.process")

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

---@class Hyprconf.MenuChoice
---@field id string
---@field label string

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
      args[#args + 1] = flag[2]
      args[#args + 1] = value
    end
  end
  for _, flag in ipairs(switch_flags) do
    if opts[flag[1]] then
      args[#args + 1] = flag[2]
    end
  end

  local result = process.run(
    args,
    { stdin = table.concat(lines, "\n") .. "\n", timeout = false }
  )
  if result.code ~= 1 or result.stderr ~= "" then
    process.check(result, "Vicinae")
  end
  return result.stdout:gsub("%s+$", ""), result.code
end

-- Shows `labels` with `opts.current` marked and returns the chosen label.
---@param labels (string|Hyprconf.MenuChoice)[]
---@param opts? Hyprconf.VicinaeOptions
---@return string?
function M.select(labels, opts)
  opts = opts or {}
  local rows, identities, seen = {}, {}, {}
  for index, entry in ipairs(labels) do
    local label = type(entry) == "table" and entry.label or entry
    local id = type(entry) == "table" and entry.id or entry
    assert(
      type(label) == "string" and type(id) == "string",
      "invalid menu choice"
    )
    assert(not seen[label], "duplicate menu label")
    seen[label] = true
    rows[index] = id == opts.current and (marker .. " " .. label) or label
    assert(not identities[rows[index]], "ambiguous menu label")
    identities[rows[index]] = id
  end

  local choice, status = M.dmenu(rows, opts)
  if status ~= 0 or choice == "" then
    return nil
  end
  return identities[choice]
end

return M
