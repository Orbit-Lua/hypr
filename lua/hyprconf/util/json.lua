---@alias Hyprconf.JsonScalar string|number|boolean|nil
---@alias Hyprconf.JsonValue Hyprconf.JsonScalar|Hyprconf.JsonArray|Hyprconf.JsonObject
---@alias Hyprconf.JsonArray Hyprconf.JsonValue[]
---@alias Hyprconf.JsonObject table<string, Hyprconf.JsonValue>

---@class Hyprconf.Util.Json
---@field read fun(path: string): string
---@field decode fun(content: string): Hyprconf.JsonValue
---@field string_field fun(content: string, key: string): string?
---@field object_string_field fun(content: string, object: string, key: string): string?
---@field encode_object fun(values: table<string, string|number|boolean|nil>, order: string[], indent?: string): string
local M = {}

---@param path string
---@return string
function M.read(path)
  local file = assert(io.open(path, "r"))
  local content = file:read("*a")
  file:close()
  return content
end

---@param content string
---@param pos integer
---@param message string
---@return never
local function decode_error(content, pos, message)
  error(
    string.format("invalid JSON at byte %d: %s", pos, message)
      .. "\n"
      .. content:sub(pos, pos + 40),
    0
  )
end

---@param content string
---@param pos integer
---@return integer
local function skip_space(content, pos)
  local _, next_pos = content:find("^[%s]*", pos)
  return (next_pos or pos - 1) + 1
end

---@type fun(content: string, pos: integer): Hyprconf.JsonValue, integer
local parse_value

---@param content string
---@param pos integer
---@return string
---@return integer
local function parse_string(content, pos)
  if content:sub(pos, pos) ~= '"' then
    decode_error(content, pos, "expected string")
  end

  local result = {}
  pos = pos + 1

  while pos <= #content do
    local char = content:sub(pos, pos)

    if char == '"' then
      return table.concat(result), pos + 1
    end

    if char == "\\" then
      local escaped = content:sub(pos + 1, pos + 1)
      local replacements = {
        ['"'] = '"',
        ["\\"] = "\\",
        ["/"] = "/",
        b = "\b",
        f = "\f",
        n = "\n",
        r = "\r",
        t = "\t",
      }

      if replacements[escaped] then
        result[#result + 1] = replacements[escaped]
        pos = pos + 2
      elseif escaped == "u" then
        result[#result + 1] = "\\u" .. content:sub(pos + 2, pos + 5)
        pos = pos + 6
      else
        decode_error(content, pos, "invalid escape")
      end
    else
      result[#result + 1] = char
      pos = pos + 1
    end
  end

  decode_error(content, pos, "unterminated string")
end

---@param content string
---@param pos integer
---@return Hyprconf.JsonArray
---@return integer
local function parse_array(content, pos)
  local result = {}
  pos = skip_space(content, pos + 1)

  if content:sub(pos, pos) == "]" then
    return result, pos + 1
  end

  while true do
    local value
    value, pos = parse_value(content, pos)
    result[#result + 1] = value
    pos = skip_space(content, pos)

    local char = content:sub(pos, pos)
    if char == "]" then
      return result, pos + 1
    elseif char ~= "," then
      decode_error(content, pos, "expected ',' or ']'")
    end

    pos = skip_space(content, pos + 1)
  end
end

---@param content string
---@param pos integer
---@return Hyprconf.JsonObject
---@return integer
local function parse_object(content, pos)
  local result = {}
  pos = skip_space(content, pos + 1)

  if content:sub(pos, pos) == "}" then
    return result, pos + 1
  end

  while true do
    local key
    key, pos = parse_string(content, pos)
    pos = skip_space(content, pos)

    if content:sub(pos, pos) ~= ":" then
      decode_error(content, pos, "expected ':'")
    end

    result[key], pos = parse_value(content, skip_space(content, pos + 1))
    pos = skip_space(content, pos)

    local char = content:sub(pos, pos)
    if char == "}" then
      return result, pos + 1
    elseif char ~= "," then
      decode_error(content, pos, "expected ',' or '}'")
    end

    pos = skip_space(content, pos + 1)
  end
end

---@param content string
---@param pos integer
---@return number
---@return integer
local function parse_number(content, pos)
  local value = content:match("^-?%d+%.?%d*[eE]?[+-]?%d*", pos)
  if not value or value == "" then
    decode_error(content, pos, "expected number")
  end
  return tonumber(value), pos + #value
end

---@param content string
---@param pos integer
---@return Hyprconf.JsonValue
---@return integer
function parse_value(content, pos)
  pos = skip_space(content, pos)
  local char = content:sub(pos, pos)

  if char == '"' then
    return parse_string(content, pos)
  elseif char == "{" then
    return parse_object(content, pos)
  elseif char == "[" then
    return parse_array(content, pos)
  elseif char == "t" and content:sub(pos, pos + 3) == "true" then
    return true, pos + 4
  elseif char == "f" and content:sub(pos, pos + 4) == "false" then
    return false, pos + 5
  elseif char == "n" and content:sub(pos, pos + 3) == "null" then
    return nil, pos + 4
  elseif char:match("[%-0-9]") then
    return parse_number(content, pos)
  end

  decode_error(content, pos, "unexpected token")
end

---@param content string
---@return Hyprconf.JsonValue
function M.decode(content)
  local value, pos = parse_value(content, 1)
  pos = skip_space(content, pos)
  if pos <= #content then
    decode_error(content, pos, "trailing content")
  end
  return value
end

---@param content string
---@param key string
---@return string?
function M.string_field(content, key)
  local value = M.decode(content)[key]
  return type(value) == "string" and value or nil
end

---@param content string
---@param object string
---@param key string
---@return string?
function M.object_string_field(content, object, key)
  local value = M.decode(content)[object]
  if type(value) ~= "table" then
    return nil
  end

  if key == "" then
    return type(value) == "string" and value or nil
  end

  value = value[key]
  return type(value) == "string" and value or nil
end

---@param values table<string, string|number|boolean|nil>
---@param order string[]
---@param indent? string
---@return string
function M.encode_object(values, order, indent)
  indent = indent or "    "
  local lines = { "{" }

  for index, key in ipairs(order) do
    local comma = index < #order and "," or ""
    local value = tostring(values[key] or "")
    value = value:gsub("\\", "\\\\"):gsub('"', '\\"')
    lines[#lines + 1] =
      string.format('%s"%s": "%s"%s', indent, key, value, comma)
  end

  lines[#lines + 1] = "}"
  return table.concat(lines, "\n") .. "\n"
end

return M
