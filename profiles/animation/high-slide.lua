-- profile: High Slide
-- credit https://github.com/mylinuxforwork/dotfiles

local profile = require("hyprconf.profile")

profile.apply_animation({
  enabled = true,
  curves = {
    { name = "wind", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } },
    { name = "winIn", points = { { 0.1, 1.1 }, { 0.1, 1.1 } } },
    { name = "winOut", points = { { 0.3, -0.3 }, { 0, 1 } } },
    { name = "liner", points = { { 1, 1 }, { 1, 1 } } },
  },
  animations = {
    {
      leaf = "windows",
      enabled = true,
      speed = 6,
      bezier = "wind",
      style = "slide",
    },
    {
      leaf = "windowsIn",
      enabled = true,
      speed = 6,
      bezier = "winIn",
      style = "slide",
    },
    {
      leaf = "windowsOut",
      enabled = true,
      speed = 5,
      bezier = "winOut",
      style = "slide",
    },
    {
      leaf = "windowsMove",
      enabled = true,
      speed = 5,
      bezier = "wind",
      style = "slide",
    },
    { leaf = "border", enabled = true, speed = 1, bezier = "liner" },
    {
      leaf = "borderangle",
      enabled = true,
      speed = 30,
      bezier = "liner",
      style = "once",
    },
    { leaf = "fade", enabled = true, speed = 10, bezier = "default" },
    { leaf = "workspaces", enabled = true, speed = 5, bezier = "wind" },
  },
})
