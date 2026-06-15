-- profile: Standard
-- credit https://github.com/mylinuxforwork/dotfiles

local profile = require("hyprconf.profile")

profile.apply_animation({
  enabled = true,
  curves = {
    { name = "myBezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } },
  },
  animations = {
    { leaf = "windows", enabled = true, speed = 7, bezier = "myBezier" },
    {
      leaf = "windowsOut",
      enabled = true,
      speed = 7,
      bezier = "default",
      style = "popin 80%",
    },
    { leaf = "border", enabled = true, speed = 10, bezier = "default" },
    { leaf = "borderangle", enabled = true, speed = 8, bezier = "default" },
    { leaf = "fade", enabled = true, speed = 7, bezier = "default" },
    { leaf = "workspaces", enabled = true, speed = 6, bezier = "default" },
  },
})
