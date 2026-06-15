-- profile: Fast Material
-- credit https://github.com/mylinuxforwork/dotfiles

local profile = require("hyprconf.profile")

profile.apply_animation({
  enabled = true,
  curves = {
    { name = "linear", points = { { 0, 0 }, { 1, 1 } } },
    { name = "md3_standard", points = { { 0.2, 0 }, { 0, 1 } } },
    { name = "md3_decel", points = { { 0.05, 0.7 }, { 0.1, 1 } } },
    { name = "md3_accel", points = { { 0.3, 0 }, { 0.8, 0.15 } } },
    { name = "overshot", points = { { 0.05, 0.9 }, { 0.1, 1.1 } } },
    { name = "crazyshot", points = { { 0.1, 1.5 }, { 0.76, 0.92 } } },
    { name = "hyprnostretch", points = { { 0.05, 0.9 }, { 0.1, 1 } } },
    { name = "fluent_decel", points = { { 0.1, 1 }, { 0, 1 } } },
    { name = "easeInOutCirc", points = { { 0.85, 0 }, { 0.15, 1 } } },
    { name = "easeOutCirc", points = { { 0, 0.55 }, { 0.45, 1 } } },
    { name = "easeOutExpo", points = { { 0.16, 1 }, { 0.3, 1 } } },
  },
  animations = {
    {
      leaf = "windows",
      enabled = true,
      speed = 3,
      bezier = "md3_decel",
      style = "popin 60%",
    },
    { leaf = "border", enabled = true, speed = 10, bezier = "default" },
    { leaf = "fade", enabled = true, speed = 2.5, bezier = "md3_decel" },
    {
      leaf = "workspaces",
      enabled = true,
      speed = 3.5,
      bezier = "easeOutExpo",
      style = "slide",
    },
    {
      leaf = "specialWorkspace",
      enabled = true,
      speed = 3,
      bezier = "md3_decel",
      style = "slidevert",
    },
  },
})
