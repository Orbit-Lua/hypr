-- profile: Smooth Default
-- credit https://github.com/mahaveergurjar

local profile = require("hyprconf.profile")

profile.apply_animation({
  enabled = true,
  curves = {
    { name = "wind", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } },
    { name = "winIn", points = { { 0.1, 1.1 }, { 0.1, 1.1 } } },
    { name = "winOut", points = { { 0.3, -0.3 }, { 0, 1 } } },
    { name = "liner", points = { { 1, 1 }, { 1, 1 } } },
    { name = "overshot", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } },
    { name = "smoothOut", points = { { 0.5, 0 }, { 0.99, 0.99 } } },
    { name = "smoothIn", points = { { 0.5, -0.5 }, { 0.68, 1.5 } } },
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
      speed = 5,
      bezier = "winIn",
      style = "slide",
    },
    {
      leaf = "windowsOut",
      enabled = true,
      speed = 3,
      bezier = "smoothOut",
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
      speed = 100,
      bezier = "liner",
      style = "loop",
    },
    { leaf = "fade", enabled = true, speed = 3, bezier = "smoothOut" },
    { leaf = "workspaces", enabled = true, speed = 5, bezier = "overshot" },
    {
      leaf = "workspacesIn",
      enabled = true,
      speed = 5,
      bezier = "winIn",
      style = "slide",
    },
    {
      leaf = "workspacesOut",
      enabled = true,
      speed = 5,
      bezier = "winOut",
      style = "slide",
    },
  },
})
