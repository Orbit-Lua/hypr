---@alias Hyprconf.JsonScalar string|number|boolean|nil
---@alias Hyprconf.JsonValue Hyprconf.JsonScalar|Hyprconf.JsonArray|Hyprconf.JsonObject
---@alias Hyprconf.JsonArray Hyprconf.JsonValue[]
---@alias Hyprconf.JsonObject table<string, Hyprconf.JsonValue>

---@class Hyprconf.Util.Json
---@field decode fun(content: string): any
local M = {}

---@param content string
---@param pos integer
---@param message string
---@return string
local function decode_error(content, pos, message)
  return string.format("invalid JSON at byte %d: %s", pos, message)
    .. "\n"
    .. content:sub(pos, pos + 40)
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
    error(decode_error(content, pos, "expected string"), 0)
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
        error(decode_error(content, pos, "invalid escape"), 0)
      end
    else
      result[#result + 1] = char
      pos = pos + 1
    end
  end

  error(decode_error(content, pos, "unterminated string"), 0)
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

  -- An explicit index keeps elements after a null in place.
  local index = 0
  while true do
    index = index + 1
    result[index], pos = parse_value(content, pos)
    pos = skip_space(content, pos)

    local char = content:sub(pos, pos)
    if char == "]" then
      return result, pos + 1
    elseif char ~= "," then
      error(decode_error(content, pos, "expected ',' or ']'"), 0)
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
      error(decode_error(content, pos, "expected ':'"), 0)
    end

    result[key], pos = parse_value(content, skip_space(content, pos + 1))
    pos = skip_space(content, pos)

    local char = content:sub(pos, pos)
    if char == "}" then
      return result, pos + 1
    elseif char ~= "," then
      error(decode_error(content, pos, "expected ',' or '}'"), 0)
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
  local number = value and tonumber(value)
  if not number then
    error(decode_error(content, pos, "expected number"), 0)
  end
  return number, pos + #value
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

  error(decode_error(content, pos, "unexpected token"), 0)
end

---@param content string
---@return any Callers declare the shape with ---@type.
function M.decode(content)
  local value, pos = parse_value(content, 1)
  pos = skip_space(content, pos)
  if pos <= #content then
    error(decode_error(content, pos, "trailing content"), 0)
  end
  return value
end

return M
