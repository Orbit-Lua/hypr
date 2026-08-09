LUA ?= luajit
LUA_FILES := $(shell find . -path './.git' -prune -o -type f -name '*.lua' ! -name 'noctalia.lua' -print | sort)

.PHONY: fmt lint test all

all: fmt lint test

fmt:
	@echo "===> Formatting"
	stylua $(LUA_FILES)

lint:
	@echo "===> Linting"
	luacheck $(LUA_FILES)

test:
	@echo "===> Validation"
	hyprland --verify-config --config ~/.config/hypr/hyprland.lua
