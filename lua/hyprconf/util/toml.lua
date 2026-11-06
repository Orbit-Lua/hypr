-- Parse the supported TOML subset and report errors at their source line.
---@alias Hyprconf.TomlScalar string|number|boolean
---@alias Hyprconf.TomlValue Hyprconf.TomlScalar|Hyprconf.TomlArray|Hyprconf.TomlTable
---@alias Hyprconf.TomlArray Hyprconf.TomlValue[]
---@alias Hyprconf.TomlTable table<string, Hyprconf.TomlValue>

---@class Hyprconf.Util.Toml
local M = {}
local escapes = {
  b = "\b",
  f = "\f",
  n = "\n",
  r = "\r",
  t = "\t",
  ['"'] = '"',
  ["\\"] = "\\",
}

---@class Hyprconf.TomlReader
---@field line string
---@field number integer
---@field position integer
---@field kinds table<table, string>

---@class Hyprconf.TomlDocument
---@field root table
---@field current table
---@field sections table<string, boolean>
---@field kinds table<table, string>

---@param reader Hyprconf.TomlReader
---@param message string
---@return any
local function fail(reader, message)
  return error(string.format("TOML line %d: %s", reader.number, message), 0)
end

---@param quote string
---@param escaped boolean
---@param char string
---@return string?
---@return boolean
local function quoted_character(quote, escaped, char)
  if escaped then
    return quote, false
  elseif quote == '"' and char == "\\" then
    return quote, true
  elseif char == quote then
    return nil, false
  end
  return quote, false
end

---@param reader Hyprconf.TomlReader
---@param raw string
---@return string
local function strip_comment(reader, raw)
  local quote, escaped, last = nil, false, #raw
  for index = 1, #raw do
    local char = raw:sub(index, index)
    if quote then
      quote, escaped = quoted_character(quote, escaped, char)
    elseif char == '"' or char == "'" then
      quote = char
    elseif char == "#" then
      last = index - 1
      break
    end
  end
  if quote then
    fail(reader, "unterminated string")
  end
  return raw:sub(1, last):match("^%s*(.-)%s*$")
end

---@param reader Hyprconf.TomlReader
local function space(reader)
  local _, finish = reader.line:find("^%s*", reader.position)
  reader.position = (finish or reader.position - 1) + 1
end

---@param reader Hyprconf.TomlReader
---@return string
local function read_string(reader)
  local delimiter = reader.line:sub(reader.position, reader.position)
  local parts = {}
  reader.position = reader.position + 1
  while reader.position <= #reader.line do
    local char = reader.line:sub(reader.position, reader.position)
    reader.position = reader.position + 1
    if char == delimiter then
      return table.concat(parts)
    end
    if char == "\\" and delimiter == '"' then
      local escaped = reader.line:sub(reader.position, reader.position)
      if not escapes[escaped] then
        fail(reader, "unsupported string escape")
      end
      parts[#parts + 1] = escapes[escaped]
      reader.position = reader.position + 1
    else
      if char:byte() < 32 and char ~= "\t" then
        fail(reader, "control character in string")
      end
      parts[#parts + 1] = char
    end
  end
  return fail(reader, "unterminated string")
end

---@param reader Hyprconf.TomlReader
---@return Hyprconf.TomlScalar
local function read_scalar(reader)
  local token = reader.line:match("^[^,%]%s]+", reader.position)
  if not token then
    fail(reader, "expected value")
  end
  reader.position = reader.position + #token
  if token == "true" then
    return true
  end
  if token == "false" then
    return false
  end
  local numeric = token:gsub("^%+", "")
  local ok, parsed = pcall(require("hyprconf.util.json").decode, numeric)
  if ok and type(parsed) == "number" then
    return parsed
  end
  return fail(reader, "unsupported value; use quoted strings, booleans, numbers or arrays")
end

---@type fun(reader: Hyprconf.TomlReader): Hyprconf.TomlValue
local read_value

---@param reader Hyprconf.TomlReader
---@return Hyprconf.TomlArray
local function read_array(reader)
  reader.position = reader.position + 1
  space(reader)
  local array = {}
  while reader.line:sub(reader.position, reader.position) ~= "]" do
    array[#array + 1] = read_value(reader)
    space(reader)
    local char = reader.line:sub(reader.position, reader.position)
    if char == "]" then
      break
    end
    if char ~= "," then
      fail(reader, "expected ',' or ']' in array")
    end
    reader.position = reader.position + 1
    space(reader)
  end
  reader.position = reader.position + 1
  reader.kinds[array] = "array"
  return array
end

---@param reader Hyprconf.TomlReader
---@return Hyprconf.TomlValue
function read_value(reader)
  space(reader)
  local char = reader.line:sub(reader.position, reader.position)
  if char == '"' or char == "'" then
    return read_string(reader)
  elseif char == "[" then
    return read_array(reader)
  end
  return read_scalar(reader)
end

---@param reader Hyprconf.TomlReader
---@param name string
---@return string[]
local function table_path(reader, name)
  if not name:match("^[%w_-]+[.%w_-]*$") or name:find("..", 1, true) or name:sub(-1) == "." then
    fail(reader, "invalid table or key name")
  end
  local parts = {}
  for part in name:gmatch("[^.]+") do
    parts[#parts + 1] = part
  end
  return parts
end

---@param reader Hyprconf.TomlReader
---@param parent table
---@param key string
---@param kind string
---@param message string
---@return table
local function child_table(reader, parent, key, kind, message)
  if parent[key] == nil then
    parent[key] = {}
    reader.kinds[parent[key]] = kind
  end
  if reader.kinds[parent[key]] ~= kind then
    fail(reader, message)
  end
  return parent[key]
end

---@param document Hyprconf.TomlDocument
---@param reader Hyprconf.TomlReader
---@param name string
---@param array boolean
local function open_table(document, reader, name, array)
  if not array and document.sections[name] then
    fail(reader, "duplicate table declaration")
  end
  local parts = table_path(reader, name)
  local parent = document.root
  for index, part in ipairs(parts) do
    if index == #parts and array then
      local entries = child_table(reader, parent, part, "array", "table conflicts with a value")
      local entry = {}
      reader.kinds[entry] = "table"
      entries[#entries + 1] = entry
      parent = entry
    else
      parent = child_table(reader, parent, part, "table", "table conflicts with a value")
    end
  end
  document.sections[name], document.current = true, parent
end

---@param document Hyprconf.TomlDocument
---@param reader Hyprconf.TomlReader
local function assign_value(document, reader)
  local key, start = reader.line:match("^([%w_.-]+)%s*=%s*()")
  if not key then
    fail(reader, "expected a key assignment or table declaration")
  end
  local parts = table_path(reader, key)
  local parent = document.current
  for index = 1, #parts - 1 do
    parent = child_table(reader, parent, parts[index], "table", "key conflicts with a value")
  end
  key = parts[#parts]
  if parent[key] ~= nil then
    fail(reader, "duplicate key")
  end
  reader.position = start
  parent[key] = read_value(reader)
  space(reader)
  if reader.position <= #reader.line then
    fail(reader, "trailing content")
  end
end

---@param document Hyprconf.TomlDocument
---@param reader Hyprconf.TomlReader
local function read_line(document, reader)
  if reader.line == "" then
    return
  end
  local array_name = reader.line:match("^%[%[([%w_.-]+)%]%]$")
  local name = array_name or reader.line:match("^%[([%w_.-]+)%]$")
  if name then
    open_table(document, reader, name, array_name ~= nil)
  else
    assign_value(document, reader)
  end
end

---@param content string
---@return table<string, any>
function M.parse(content)
  local root = {}
  ---@type Hyprconf.TomlDocument
  local document = { root = root, current = root, sections = {}, kinds = { [root] = "table" } }
  local number = 0
  for raw in (content .. "\n"):gmatch("([^\n]*)\n") do
    number = number + 1
    ---@type Hyprconf.TomlReader
    local reader = { line = "", number = number, position = 1, kinds = document.kinds }
    reader.line = strip_comment(reader, raw)
    read_line(document, reader)
  end
  return root
end

---@param path string
---@return table<string, any>
function M.read(path)
  local file = assert(io.open(path, "r"))
  local content = assert(file:read("*a"))
  assert(file:close())
  local ok, parsed = pcall(M.parse, content)
  if not ok then
    error(path .. ": " .. tostring(parsed), 0)
  end
  return parsed
end

return M
