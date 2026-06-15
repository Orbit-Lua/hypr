-- profile: Vertical Flow
-- credit https://github.com/prasanthrangan/hyprdots

local profile = require("hyprconf.profile")

profile.apply_animation({
  enabled = true,
  curves = {
    { name = "fluent_decel", points = { { 0, 0.2 }, { 0.4, 1 } } },
    { name = "easeOutCirc", points = { { 0, 0.55 }, { 0.45, 1 } } },
    { name = "easeOutCubic", points = { { 0.33, 1 }, { 0.68, 1 } } },
    { name = "easeinoutsine", points = { { 0.37, 0 }, { 0.63, 1 } } },
  },
  animations = {
    {
      leaf = "windowsIn",
      enabled = true,
      speed = 1.5,
      bezier = "easeinoutsine",
      style = "popin 60%",
    },
    {
      leaf = "windowsOut",
      enabled = true,
      speed = 1.5,
      bezier = "easeOutCubic",
      style = "popin 60%",
    },
    {
      leaf = "windowsMove",
      enabled = true,
      speed = 1.5,
      bezier = "easeinoutsine",
      style = "slide",
    },
    { leaf = "fade", enabled = true, speed = 2.5, bezier = "fluent_decel" },
    { leaf = "fadeLayersIn", enabled = false },
    { leaf = "border", enabled = false },
    {
      leaf = "layers",
      enabled = true,
      speed = 1.5,
      bezier = "easeinoutsine",
      style = "popin",
    },
    {
      leaf = "workspaces",
      enabled = true,
      speed = 3,
      bezier = "fluent_decel",
      style = "slidefadevert 30%",
    },
    {
      leaf = "specialWorkspace",
      enabled = true,
      speed = 2,
      bezier = "fluent_decel",
      style = "slidefade 10%",
    },
  },
})
