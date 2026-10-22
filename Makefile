LUA ?= lua
LUALS ?= $(or $(shell command -v lua-language-server),$(wildcard $(HOME)/.local/share/nvim/mason/bin/lua-language-server),lua-language-server)
LUA_FILES := $(shell git ls-files --cached --others --exclude-standard '*.lua' | grep -vx noctalia.lua)

.PHONY: all check fmt fmt-check lint typecheck keymap config test

all: fmt check

# What CI runs; `all` formats first instead of only checking the format.
check: fmt-check lint typecheck keymap config test

fmt:
	stylua $(LUA_FILES)

fmt-check:
	stylua --check $(LUA_FILES)

lint:
	luacheck $(LUA_FILES)

# Checks annotations against Hyprland's stubs (.luarc.json).
typecheck:
	@log=$$(mktemp -d); \
	$(LUALS) --check=. --checklevel=Warning --logpath="$$log" >"$$log/out" 2>&1; \
	status=$$?; [ $$status -eq 0 ] || cat "$$log/out"; \
	rm -rf "$$log"; exit $$status

# Every bind must match tests/keymap.snapshot. After an intended keymap change:
#   $(LUA) tests/keymap.lua > tests/keymap.snapshot
keymap:
	@actual=$$(mktemp); \
	trap 'rm -f "$$actual"' EXIT; \
	$(LUA) tests/keymap.lua >"$$actual" && diff -u tests/keymap.snapshot "$$actual"

# Everything else the configuration sends to Hyprland must match
# tests/config.snapshot. After an intended behavior change:
#   $(LUA) tests/config.lua "$$(mktemp -d)" > tests/config.snapshot
config:
	@state=$$(mktemp -d); \
	trap 'rm -rf "$$state"' EXIT; \
	$(LUA) tests/config.lua "$$state" >"$$state/actual" && \
	  diff -u tests/config.snapshot "$$state/actual"

# Parses this checkout with a throwaway home and runtime directory, so it never
# reads or reloads the live session.
test:
	@home=$$(mktemp -d) runtime=$$(mktemp -d); \
	env -i HOME="$$home" PATH="$$PATH" XDG_RUNTIME_DIR="$$runtime" \
	  hyprland --verify-config --config "$(CURDIR)/hyprland.lua"; \
	status=$$?; rm -rf "$$home" "$$runtime"; exit $$status
