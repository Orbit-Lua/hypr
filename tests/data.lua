local root = debug.getinfo(1, "S").source:sub(2):match("(.+)/tests/[^/]+$")
  or "."
package.path = root
  .. "/lua/?.lua;"
  .. root
  .. "/lua/?/init.lua;"
  .. package.path
local json = require("hyprconf.util.json")
local decoded =
  json.decode('[[null,false,1],"\\u4e2d\\u6587\\ud83d\\ude00",-1.5e2]')
assert(
  decoded[1][1] == json.null and #decoded[1] == 3 and decoded[1][2] == false
)
assert(decoded[2] == "中文😀" and decoded[3] == -150)
assert(
  json.encode({ flag = false, values = { json.null, true, 1 }, text = "a\nb" })
    == '{"flag":false,"text":"a\\u000ab","values":[null,true,1]}'
)
for _, invalid in ipairs({
  "01",
  "1.",
  "1e",
  "-",
  '"\\uZZZZ"',
  '"\\ud800"',
  '"\\udc00"',
  '"line\nbreak"',
  '{"x":null,"x":1}',
  "[1,]",
  "true false",
}) do
  assert(not pcall(json.decode, invalid), "accepted malformed JSON")
end
local toml = require("hyprconf.util.toml")
local data = toml.parse(
  "[section]\nvalue = ['literal\\path', \"escaped\\nline\", false, [1, 2]] # comment\n"
    .. "[[row]]\nname='one'\n[[row]]\nname='two'\n"
)
assert(
  data.section.value[1] == "literal\\path"
    and data.section.value[2] == "escaped\nline"
)
assert(data.section.value[3] == false and data.section.value[4][2] == 2)
assert(data.row[1].name == "one" and data.row[2].name == "two")
for _, invalid in ipairs({
  "unrecognized record",
  "x = bare",
  "x=[1,,2]",
  "x=1\nx=2",
  "[a]\n[a]",
  'x="\\q"',
  'x="unterminated',
  "x=[1",
  "x=true extra",
}) do
  local ok, err = pcall(toml.parse, invalid)
  assert(
    not ok and tostring(err):match("TOML line %d+"),
    "malformed TOML lacked a location"
  )
end
