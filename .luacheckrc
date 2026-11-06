globals = { "hl" }
max_line_length = 100
max_comment_line_length = false
max_string_line_length = false
max_cyclomatic_complexity = 10

-- Remove these transition limits as their owners are split into smaller functions.
files = {
  ["lua/hyprconf/commands/layout.lua"] = { max_cyclomatic_complexity = 13 },
  ["lua/hyprconf/commands/screenshot.lua"] = { max_cyclomatic_complexity = 24 },
  ["lua/hyprconf/commands/sound.lua"] = { max_cyclomatic_complexity = 15 },
  ["lua/hyprconf/config.lua"] = { max_cyclomatic_complexity = 35 },
  ["lua/hyprconf/runtime/notify.lua"] = { max_cyclomatic_complexity = 15 },
  ["lua/hyprconf/runtime/process.lua"] = { max_cyclomatic_complexity = 15 },
  ["lua/hyprconf/runtime/vicinae.lua"] = { max_cyclomatic_complexity = 12 },
  ["tests/data.lua"] = { max_cyclomatic_complexity = 11 },
}
