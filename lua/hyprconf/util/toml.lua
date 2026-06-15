---@alias Hyprconf.TomlScalar string|number|boolean
---@alias Hyprconf.TomlValue Hyprconf.TomlScalar|Hyprconf.TomlArray|Hyprconf.TomlTable
---@alias Hyprconf.TomlArray Hyprconf.TomlValue[]
---@alias Hyprconf.TomlTable table<string, Hyprconf.TomlValue>

---@class Hyprconf.Util.Toml
---@field parse fun(content: string): Hyprconf.TomlTable
---@field read fun(path: string): Hyprconf.TomlTable
local M = {}

---@param value string
---@return string
local function trim(value)
  return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

---@param line string
---@return string
local function strip_comment(line)
  local quote = nil
  local escaped = false

  for i = 1, #line do
    local char = line:sub(i, i)
    if quote then
      if escaped then
        escaped = false
      elseif char == "\\" then
        escaped = true
      elseif char == quote then
        quote = nil
      end
    elseif char == '"' or char == "'" then
      quote = char
    elseif char == "#" then
      return line:sub(1, i - 1)
    end
  end

  return line
end

---@param value string
---@return string
local function unescape(value)
  return value
    :gsub("\\n", "\n")
    :gsub("\\t", "\t")
    :gsub('\\"', '"')
    :gsub("\\\\", "\\")
end

---@type fun(value: string): Hyprconf.TomlValue
local parse_value

---@param value string
---@return Hyprconf.TomlArray
local function parse_array(value)
  local result = {}
  local item = {}
  local quote = nil
  local escaped = false
  local depth = 0

  local function push()
    local text = trim(table.concat(item))
    if text ~= "" then
      result[#result + 1] = parse_value(text)
    end
    item = {}
  end

  value = trim(value:sub(2, -2))
  if value == "" then
    return result
  end

  for i = 1, #value do
    local char = value:sub(i, i)
    if quote then
      item[#item + 1] = char
      if escaped then
        escaped = false
      elseif char == "\\" then
        escaped = true
      elseif char == quote then
        quote = nil
      end
    elseif char == '"' or char == "'" then
      quote = char
      item[#item + 1] = char
    elseif char == "[" then
      depth = depth + 1
      item[#item + 1] = char
    elseif char == "]" then
      depth = depth - 1
      item[#item + 1] = char
    elseif char == "," and depth == 0 then
      push()
    else
      item[#item + 1] = char
    end
  end

  push()
  return result
end

parse_value = function(value)
  value = trim(value)

  if value:match('^".*"$') then
    return unescape(value:sub(2, -2))
  end

  if value:match("^'.*'$") then
    return value:sub(2, -2)
  end

  if value:sub(1, 1) == "[" and value:sub(-1) == "]" then
    return parse_array(value)
  end

  if value == "true" then
    return true
  end

  if value == "false" then
    return false
  end

  local number = tonumber(value)
  if number ~= nil then
    return number
  end

  return value
end

---@param root Hyprconf.TomlTable
---@param name string
---@return Hyprconf.TomlTable
local function section(root, name)
  local current = root
  for part in name:gmatch("[^.]+") do
    current[part] = current[part] or {}
    current = current[part]
  end
  return current
end

---@param root Hyprconf.TomlTable
---@param name string
---@return Hyprconf.TomlTable
local function array_section(root, name)
  local parent_name, key = name:match("^(.*)%.([^.]+)$")
  key = key or name
  local parent = parent_name and section(root, parent_name) or root
  parent[key] = parent[key] or {}
  local value = {}
  parent[key][#parent[key] + 1] = value
  return value
end

---@param content string
---@return Hyprconf.TomlTable
function M.parse(content)
  local root = {}
  local current = root

  for raw_line in (content .. "\n"):gmatch("([^\n]*)\n") do
    local line = trim(strip_comment(raw_line))
    if line ~= "" then
      local array_name = line:match("^%[%[([%w_.-]+)%]%]$")
      local section_name = line:match("^%[([%w_.-]+)%]$")
      if array_name then
        current = array_section(root, array_name)
      elseif section_name then
        current = section(root, section_name)
      else
        local key, value = line:match("^([%w_.-]+)%s*=%s*(.+)$")
        if key then
          current[key] = parse_value(value)
        end
      end
    end
  end

  return root
end

---@param path string
---@return Hyprconf.TomlTable
function M.read(path)
  local file = assert(io.open(path, "r"))
  local content = file:read("*a")
  file:close()
  return M.parse(content)
end

return M
