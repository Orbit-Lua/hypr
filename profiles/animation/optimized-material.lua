-- profile: Optimized Material
-- credit https://github.com/prasanthrangan/hyprdots

local profile = require("hyprconf.profile")

profile.apply_animation({
  enabled = true,
  curves = {
    { name = "wind", points = { { 0.05, 0.85 }, { 0.03, 0.97 } } },
    { name = "winIn", points = { { 0.07, 0.88 }, { 0.04, 0.99 } } },
    { name = "winOut", points = { { 0.2, -0.15 }, { 0, 1 } } },
    { name = "liner", points = { { 1, 1 }, { 1, 1 } } },
    { name = "md3_standard", points = { { 0.12, 0 }, { 0, 1 } } },
    { name = "md3_decel", points = { { 0.05, 0.8 }, { 0.1, 0.97 } } },
    { name = "md3_accel", points = { { 0.2, 0 }, { 0.8, 0.08 } } },
    { name = "overshot", points = { { 0.05, 0.85 }, { 0.07, 1.04 } } },
    { name = "crazyshot", points = { { 0.1, 1.22 }, { 0.68, 0.98 } } },
    { name = "hyprnostretch", points = { { 0.05, 0.82 }, { 0.03, 0.94 } } },
    { name = "menu_decel", points = { { 0.05, 0.82 }, { 0, 1 } } },
    { name = "menu_accel", points = { { 0.2, 0 }, { 0.82, 0.1 } } },
    { name = "easeInOutCirc", points = { { 0.75, 0 }, { 0.15, 1 } } },
    { name = "easeOutCirc", points = { { 0, 0.48 }, { 0.38, 1 } } },
    { name = "easeOutExpo", points = { { 0.1, 0.94 }, { 0.23, 0.98 } } },
    { name = "softAcDecel", points = { { 0.2, 0.2 }, { 0.15, 1 } } },
    { name = "md2", points = { { 0.3, 0 }, { 0.15, 1 } } },
    { name = "OutBack", points = { { 0.28, 1.4 }, { 0.58, 1 } } },
    { name = "easeInOutCirc", points = { { 0.78, 0 }, { 0.15, 1 } } },
  },
  animations = {
    { leaf = "border", enabled = true, speed = 1.6, bezier = "liner" },
    {
      leaf = "borderangle",
      enabled = true,
      speed = 82,
      bezier = "liner",
      style = "once",
    },
    {
      leaf = "windowsIn",
      enabled = true,
      speed = 3.2,
      bezier = "winIn",
      style = "slide",
    },
    {
      leaf = "windowsOut",
      enabled = true,
      speed = 2.8,
      bezier = "easeOutCirc",
    },
    {
      leaf = "windowsMove",
      enabled = true,
      speed = 3,
      bezier = "wind",
      style = "slide",
    },
    { leaf = "fade", enabled = true, speed = 1.8, bezier = "md3_decel" },
    {
      leaf = "layersIn",
      enabled = true,
      speed = 1.8,
      bezier = "menu_decel",
      style = "slide",
    },
    { leaf = "layersOut", enabled = true, speed = 1.5, bezier = "menu_accel" },
    {
      leaf = "fadeLayersIn",
      enabled = true,
      speed = 1.6,
      bezier = "menu_decel",
    },
    {
      leaf = "fadeLayersOut",
      enabled = true,
      speed = 1.8,
      bezier = "menu_accel",
    },
    {
      leaf = "workspaces",
      enabled = true,
      speed = 4,
      bezier = "menu_decel",
      style = "slide",
    },
    {
      leaf = "specialWorkspace",
      enabled = true,
      speed = 2.3,
      bezier = "md3_decel",
      style = "slidefadevert 15%",
    },
  },
})
