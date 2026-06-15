local colors = require("hyprconf.colors")
local ctx = require("hyprconf.context")

---@class Hyprconf.Options
---@field setup fun()
local M = {}

---@return nil
function M.setup()
  hl.config({
    general = {
      border_size = 1,
      gaps_in = 2,
      gaps_out = 4,
      resize_on_border = true,
      layout = "scrolling",
      col = {
        active_border = colors.get(
          "primary",
          colors.get("color12", "rgb(B39D89)")
        ),
        inactive_border = colors.get(
          "surface",
          colors.get("color10", "rgb(72695D)")
        ),
      },
    },

    decoration = {
      rounding = 2,
      rounding_power = 2,
      active_opacity = 1.0,
      inactive_opacity = 0.9,
      fullscreen_opacity = 1.0,
      dim_inactive = true,
      dim_strength = 0.1,
      dim_special = 0.8,
      shadow = {
        enabled = true,
        range = 4,
        render_power = 3,
        color = colors.get("color12", "rgb(B39D89)"),
        color_inactive = colors.get("color10", "rgb(72695D)"),
      },
      blur = {
        enabled = true,
        size = 3,
        passes = 2,
        ignore_opacity = true,
        new_optimizations = true,
        special = true,
        popups = true,
        vibrancy = 0.1696,
      },
    },

    group = {
      col = {
        border_active = colors.get(
          "secondary",
          colors.get("color15", "rgb(F4EEE4)")
        ),
        border_inactive = colors.get(
          "surface",
          colors.get("color10", "rgb(72695D)")
        ),
        border_locked_active = colors.get("error", "rgb(f7768e)"),
        border_locked_inactive = colors.get(
          "surface",
          colors.get("color10", "rgb(72695D)")
        ),
      },
      groupbar = {
        col = {
          active = colors.get("secondary", colors.get("color0", "rgb(000000)")),
          inactive = colors.get(
            "surface",
            colors.get("color10", "rgb(72695D)")
          ),
          locked_active = colors.get("error", "rgb(f7768e)"),
          locked_inactive = colors.get(
            "surface",
            colors.get("color10", "rgb(72695D)")
          ),
        },
      },
    },

    input = {
      kb_layout = "us",
      repeat_rate = 50,
      repeat_delay = 300,
      sensitivity = 0,
      numlock_by_default = true,
      left_handed = false,
      follow_mouse = 1,
      float_switch_override_focus = false,
      touchpad = {
        disable_while_typing = true,
        natural_scroll = true,
        clickfinger_behavior = false,
        middle_button_emulation = false,
        tap_to_click = true,
        drag_lock = false,
      },
      touchdevice = { enabled = true },
      tablet = { transform = 0, left_handed = 0 },
    },

    gestures = {
      workspace_swipe_distance = 500,
      workspace_swipe_invert = true,
      workspace_swipe_min_speed_to_force = 30,
      workspace_swipe_cancel_ratio = 0.5,
      workspace_swipe_create_new = true,
      workspace_swipe_forever = true,
    },

    dwindle = {
      preserve_split = true,
      special_scale_factor = 0.8,
    },

    master = {
      new_status = "master",
      new_on_top = 1,
      mfact = 0.5,
    },

    scrolling = {
      column_width = 0.5,
      fullscreen_on_one_column = true,
      explicit_column_widths = "0.333, 0.5, 0.667, 1.0",
      follow_focus = true,
      focus_fit_method = 1,
    },

    misc = {
      disable_hyprland_logo = true,
      disable_splash_rendering = true,
      vrr = 2,
      mouse_move_enables_dpms = true,
      enable_swallow = false,
      swallow_regex = "^(kitty)$",
      focus_on_activate = false,
      initial_workspace_tracking = 0,
      middle_click_paste = false,
      enable_anr_dialog = true,
      anr_missed_pings = 15,
      allow_session_lock_restore = true,
      on_focus_under_fullscreen = 1,
    },

    binds = {
      workspace_back_and_forth = true,
      allow_workspace_cycles = true,
      pass_mouse_when_bound = false,
    },

    xwayland = {
      enabled = true,
      force_zero_scaling = true,
    },

    render = { direct_scanout = 0 },

    cursor = {
      sync_gsettings_theme = true,
      no_hardware_cursors = 1,
      enable_hyprcursor = true,
      warp_on_change_workspace = 2,
      no_warps = true,
    },

    animations = { enabled = true },
  })

  hl.device({ name = ctx.touchpad_device, enabled = true })
end

return M
