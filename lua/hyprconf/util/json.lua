---@class Hyprconf.JsonNull
---@alias Hyprconf.JsonScalar string|number|boolean|Hyprconf.JsonNull
---@alias Hyprconf.JsonValue Hyprconf.JsonScalar|Hyprconf.JsonArray|Hyprconf.JsonObject
---@alias Hyprconf.JsonArray Hyprconf.JsonValue[]
---@alias Hyprconf.JsonObject table<string, Hyprconf.JsonValue>

---@class Hyprconf.Util.Json
---@field decode fun(content: string): any
local M = {}
---@type Hyprconf.JsonNull
M.null = {}

---@param content string
---@param pos integer
---@param message string
---@return string
local function decode_error(content, pos, message)
  return string.format(
    "invalid JSON at byte %d of %d: %s",
    pos,
    #content,
    message
  )
end

---@param content string
---@param pos integer
---@return integer
local function skip_space(content, pos)
  local _, next_pos = content:find("^[ \t\r\n]*", pos)
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
        local hex = content:sub(pos + 2, pos + 5)
        assert(
          hex:match("^%x%x%x%x$"),
          decode_error(content, pos, "invalid Unicode escape")
        )
        local code = assert(tonumber(hex, 16))
        pos = pos + 6
        if code >= 0xd800 and code <= 0xdbff then
          local low = content:sub(pos, pos + 5):match("^\\u(%x%x%x%x)$")
          local value = low and tonumber(low, 16)
          assert(
            value and value >= 0xdc00 and value <= 0xdfff,
            decode_error(content, pos, "missing low surrogate")
          )
          code = 0x10000 + (code - 0xd800) * 0x400 + value - 0xdc00
          pos = pos + 6
        else
          assert(
            code < 0xdc00 or code > 0xdfff,
            decode_error(content, pos, "unexpected low surrogate")
          )
        end
        result[#result + 1] = utf8.char(code)
      else
        error(decode_error(content, pos, "invalid escape"), 0)
      end
    else
      assert(
        char:byte() >= 32,
        decode_error(content, pos, "unescaped control character")
      )
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

    assert(
      result[key] == nil,
      decode_error(content, pos, "duplicate object key")
    )
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
  local start = pos
  if content:sub(pos, pos) == "-" then
    pos = pos + 1
  end
  local integer = content:match("^%d+", pos)
  assert(
    integer and (#integer == 1 or integer:sub(1, 1) ~= "0"),
    decode_error(content, pos, "invalid integer")
  )
  pos = pos + #integer
  if content:sub(pos, pos) == "." then
    local fraction = content:match("^%d+", pos + 1)
    assert(fraction, decode_error(content, pos, "missing fraction"))
    pos = pos + 1 + #fraction
  end
  if content:sub(pos, pos):match("[eE]") then
    pos = pos + 1
    if content:sub(pos, pos):match("[+-]") then
      pos = pos + 1
    end
    local exponent = content:match("^%d+", pos)
    assert(exponent, decode_error(content, pos, "missing exponent"))
    pos = pos + #exponent
  end
  local number = tonumber(content:sub(start, pos - 1))
  assert(
    number and number ~= math.huge and number ~= -math.huge,
    decode_error(content, start, "number out of range")
  )
  return number, pos
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
    return M.null, pos + 4
  elseif char:match("[%-0-9]") then
    return parse_number(content, pos)
  end

  error(decode_error(content, pos, "unexpected token"), 0)
end

---@param content string
---@return any Callers declare the shape with ---@type.
function M.decode(content)
  assert(utf8.len(content), "invalid JSON UTF-8")
  local value, pos = parse_value(content, 1)
  pos = skip_space(content, pos)
  if pos <= #content then
    error(decode_error(content, pos, "trailing content"), 0)
  end
  return value
end

---@param value any
---@return string
function M.encode(value)
  if value == M.null then
    return "null"
  end
  if type(value) == "boolean" then
    return tostring(value)
  end
  if type(value) == "number" then
    assert(
      value == value and value ~= math.huge and value ~= -math.huge,
      "invalid JSON number"
    )
    return tostring(value)
  end
  if type(value) == "string" then
    assert(utf8.len(value), "invalid JSON UTF-8")
    return '"'
      .. value:gsub('[%z\1-\31\\"]', function(char)
        if char == '"' or char == "\\" then
          return "\\" .. char
        end
        return string.format("\\u%04x", char:byte())
      end)
      .. '"'
  end
  assert(type(value) == "table", "unsupported JSON value")
  local keys, array = {}, #value > 0
  for key in pairs(value) do
    keys[#keys + 1] = key
    array = array
      and type(key) == "number"
      and key % 1 == 0
      and key >= 1
      and key <= #value
  end
  local parts = {}
  if array then
    for _, item in ipairs(value) do
      parts[#parts + 1] = M.encode(item)
    end
    return "[" .. table.concat(parts, ",") .. "]"
  end
  for _, key in ipairs(keys) do
    assert(type(key) == "string", "JSON object keys must be strings")
  end
  table.sort(keys)
  for _, key in ipairs(keys) do
    parts[#parts + 1] = M.encode(key) .. ":" .. M.encode(value[key])
  end
  return "{" .. table.concat(parts, ",") .. "}"
end

return M
