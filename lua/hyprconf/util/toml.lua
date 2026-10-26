---@alias Hyprconf.TomlScalar string|number|boolean
---@alias Hyprconf.TomlValue Hyprconf.TomlScalar|Hyprconf.TomlArray|Hyprconf.TomlTable
---@alias Hyprconf.TomlArray Hyprconf.TomlValue[]
---@alias Hyprconf.TomlTable table<string, Hyprconf.TomlValue>

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

---@param content string
---@return table<string, any>
function M.parse(content)
  local root = {}
  local current = root
  local sections = {}
  local kinds = { [root] = "table" }
  for number, raw in
    ipairs((function()
      local lines = {}
      for line in (content .. "\n"):gmatch("([^\n]*)\n") do
        lines[#lines + 1] = line
      end
      return lines
    end)())
  do
    local function fail(message)
      error(string.format("TOML line %d: %s", number, message), 0)
    end
    local quote, escaped, last = nil, false, #raw
    for index = 1, #raw do
      local char = raw:sub(index, index)
      if escaped then
        escaped = false
      elseif quote == '"' and char == "\\" then
        escaped = true
      elseif quote and char == quote then
        quote = nil
      elseif not quote and (char == '"' or char == "'") then
        quote = char
      elseif not quote and char == "#" then
        last = index - 1
        break
      end
    end
    if quote then
      fail("unterminated string")
    end
    local line = raw:sub(1, last):match("^%s*(.-)%s*$")
    if line ~= "" then
      local position = 1
      local function space()
        local _, finish = line:find("^%s*", position)
        position = (finish or position - 1) + 1
      end
      local value
      value = function()
        space()
        local char = line:sub(position, position)
        if char == '"' or char == "'" then
          local delimiter, parts = char, {}
          position = position + 1
          while position <= #line do
            char = line:sub(position, position)
            position = position + 1
            if char == delimiter then
              return table.concat(parts)
            end
            if char == "\\" and delimiter == '"' then
              local escaped_char = line:sub(position, position)
              if not escapes[escaped_char] then
                fail("unsupported string escape")
              end
              parts[#parts + 1] = escapes[escaped_char]
              position = position + 1
            else
              if char:byte() < 32 and char ~= "\t" then
                fail("control character in string")
              end
              parts[#parts + 1] = char
            end
          end
          fail("unterminated string")
        elseif char == "[" then
          position = position + 1
          space()
          local array = {}
          if line:sub(position, position) ~= "]" then
            while true do
              array[#array + 1] = value()
              space()
              char = line:sub(position, position)
              if char == "]" then
                break
              end
              if char ~= "," then
                fail("expected ',' or ']' in array")
              end
              position = position + 1
              space()
              if line:sub(position, position) == "]" then
                break
              end
            end
          end
          position = position + 1
          kinds[array] = "array"
          return array
        end
        local token = line:match("^[^,%]%s]+", position)
        if not token then
          fail("expected value")
        end
        position = position + #token
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
        fail(
          "unsupported value; use quoted strings, booleans, numbers or arrays"
        )
      end
      local function table_path(name)
        if
          not name:match("^[%w_-]+[.%w_-]*$")
          or name:find("..", 1, true)
          or name:sub(-1) == "."
        then
          fail("invalid table or key name")
        end
        local parts = {}
        for part in name:gmatch("[^.]+") do
          parts[#parts + 1] = part
        end
        return parts
      end
      local array_name = line:match("^%[%[([%w_.-]+)%]%]$")
      local name = array_name or line:match("^%[([%w_.-]+)%]$")
      if name then
        if not array_name and sections[name] then
          fail("duplicate table declaration")
        end
        local parts = table_path(name)
        local parent = root
        for index, part in ipairs(parts) do
          if index == #parts and array_name then
            if parent[part] == nil then
              parent[part] = {}
              kinds[parent[part]] = "array"
            end
            if kinds[parent[part]] ~= "array" then
              fail("table conflicts with a value")
            end
            local entry = {}
            kinds[entry] = "table"
            parent[part][#parent[part] + 1] = entry
            parent = entry
          else
            if parent[part] == nil then
              parent[part] = {}
              kinds[parent[part]] = "table"
            end
            if kinds[parent[part]] ~= "table" then
              fail("table conflicts with a value")
            end
            parent = parent[part]
          end
        end
        sections[name], current = true, parent
      else
        local key, start = line:match("^([%w_.-]+)%s*=%s*()")
        if not key then
          fail("expected a key assignment or table declaration")
        end
        local parts = table_path(key)
        local parent = current
        for index = 1, #parts - 1 do
          local part = parts[index]
          if parent[part] == nil then
            parent[part] = {}
            kinds[parent[part]] = "table"
          end
          if kinds[parent[part]] ~= "table" then
            fail("key conflicts with a value")
          end
          parent = parent[part]
        end
        key = parts[#parts]
        if parent[key] ~= nil then
          fail("duplicate key")
        end
        position = start
        parent[key] = value()
        space()
        if position <= #line then
          fail("trailing content")
        end
      end
    end
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
