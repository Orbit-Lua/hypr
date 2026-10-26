local root = debug.getinfo(1, "S").source:sub(2):match("(.+)/tests/[^/]+$")
  or "."
package.path = root
  .. "/lua/?.lua;"
  .. root
  .. "/lua/?/init.lua;"
  .. package.path
local events, timers, commands = {}, {}, {}
-- luacheck: globals hl
hl = {
  on = function(event, callback)
    local subscription = { active = true, callback = callback }
    function subscription:remove()
      self.active = false
    end
    events[event] = subscription
    return subscription
  end,
  timer = function(callback)
    local timer = { enabled = true, callback = callback }
    function timer:set_enabled(value)
      self.enabled = value
    end
    function timer.set_timeout() end
    timers[#timers + 1] = timer
    return timer
  end,
  exec_cmd = function(command)
    commands[#commands + 1] = command
  end,
}
local autostart = require("hyprconf.autostart")
autostart.setup()
events["monitor.added"].callback()
events["monitor.removed"].callback()
assert(#commands == 0, "hotplug must wait for the coalescing timer")
timers[1].callback()
timers[1].callback()
assert(
  #commands == 1 and commands[1] == "hyprctl reload",
  "a burst must issue one reload"
)
events["monitor.added"].callback()
local stale_subscription = events["monitor.added"]
autostart.setup()
assert(
  not stale_subscription.active and not timers[1].enabled,
  "setup must dispose old subscriptions and timers"
)
timers[1].callback()
assert(
  #commands == 1,
  "a queued old callback must not reload a replacement configuration"
)
