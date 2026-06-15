-- profile: Soft Pop

local profile = require("hyprconf.profile")

profile.apply_animation({
  enabled = true,
  curves = {
    { name = "myBezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } },
    { name = "linear", points = { { 0, 0 }, { 1, 1 } } },
    { name = "wind", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } },
    { name = "winIn", points = { { 0.1, 1.1 }, { 0.1, 1.1 } } },
    { name = "winOut", points = { { 0.3, -0.3 }, { 0, 1 } } },
    { name = "slow", points = { { 0, 0.85 }, { 0.3, 1 } } },
    { name = "overshot", points = { { 0.7, 0.6 }, { 0.1, 1.1 } } },
    { name = "bounce", points = { { 1.1, 1.6 }, { 0.1, 0.85 } } },
    { name = "sligshot", points = { { 1, -1 }, { 0.15, 1.25 } } },
    { name = "nice", points = { { 0, 6.9 }, { 0.5, -4.2 } } },
  },
  animations = {
    {
      leaf = "windowsIn",
      enabled = true,
      speed = 5,
      bezier = "slow",
      style = "popin",
    },
    {
      leaf = "windowsOut",
      enabled = true,
      speed = 5,
      bezier = "winOut",
      style = "popin",
    },
    {
      leaf = "windowsMove",
      enabled = true,
      speed = 5,
      bezier = "wind",
      style = "slide",
    },
    { leaf = "border", enabled = true, speed = 10, bezier = "linear" },
    {
      leaf = "borderangle",
      enabled = true,
      speed = 100,
      bezier = "linear",
      style = "loop",
    },
    { leaf = "fade", enabled = true, speed = 5, bezier = "overshot" },
    { leaf = "workspaces", enabled = true, speed = 5, bezier = "wind" },
    {
      leaf = "windows",
      enabled = true,
      speed = 5,
      bezier = "bounce",
      style = "popin",
    },
  },
})
