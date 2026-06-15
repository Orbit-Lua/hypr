-- profile: Minimal Quart
-- credit https://github.com/prasanthrangan/hyprdots

local profile = require("hyprconf.profile")

profile.apply_animation({
  enabled = true,
  curves = {
    { name = "quart", points = { { 0.25, 1 }, { 0.5, 1 } } },
  },
  animations = {
    {
      leaf = "windows",
      enabled = true,
      speed = 6,
      bezier = "quart",
      style = "slide",
    },
    { leaf = "border", enabled = true, speed = 6, bezier = "quart" },
    { leaf = "borderangle", enabled = true, speed = 6, bezier = "quart" },
    { leaf = "fade", enabled = true, speed = 6, bezier = "quart" },
    { leaf = "workspaces", enabled = true, speed = 6, bezier = "quart" },
  },
})
