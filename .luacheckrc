globals = { "hl" }
max_line_length = 100
max_comment_line_length = false
max_string_line_length = false
max_cyclomatic_complexity = 10

-- Remove these transition limits as their owners are split into smaller functions.
files = {
  ["tests/data.lua"] = { max_cyclomatic_complexity = 11 },
}
