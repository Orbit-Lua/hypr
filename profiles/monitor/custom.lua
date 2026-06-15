-- profile: Mirrored Laptop

hl.monitor({
  output = "eDP-1",
  mode = "1920x1080@100",
  position = "0x0",
  scale = 1,
})

hl.monitor({
  output = "HDMI-A-1",
  mode = "1920x1080@100",
  position = "0x0",
  scale = 1,
  mirror = "eDP-1",
})

hl.monitor({
  output = "",
  mode = "1920x1080@100",
  position = "0x0",
  scale = 1,
  mirror = "eDP-1",
})
