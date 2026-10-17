LUA ?= lua
LUA_FILES := $(shell git ls-files --cached --others --exclude-standard '*.lua' | grep -vx noctalia.lua)

.PHONY: all fmt fmt-check lint keymap test

all: fmt lint keymap test

fmt:
	stylua $(LUA_FILES)

fmt-check:
	stylua --check $(LUA_FILES)

lint:
	luacheck $(LUA_FILES)

# Every bind must match tests/keymap.snapshot. After an intended keymap change:
#   $(LUA) tests/keymap.lua > tests/keymap.snapshot
keymap:
	$(LUA) tests/keymap.lua | diff -u tests/keymap.snapshot -

# Parses this checkout with a throwaway home and runtime directory, so it never
# reads or reloads the live session.
test:
	@home=$$(mktemp -d) runtime=$$(mktemp -d); \
	env -i HOME="$$home" PATH="$$PATH" XDG_RUNTIME_DIR="$$runtime" \
	  hyprland --verify-config --config "$(CURDIR)/hyprland.lua"; \
	status=$$?; rm -rf "$$home" "$$runtime"; exit $$status
