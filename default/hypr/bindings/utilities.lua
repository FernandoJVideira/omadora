-- Menus.
o.bind("SUPER + SPACE", "Launch apps", o.libexec("skein-menu apps"))
o.bind("SUPER + CTRL + C", "Capture menu", o.libexec("skein-menu capture"))
o.bind("SUPER + CTRL + H", "Hardware menu", o.libexec("skein-menu hardware"))
o.bind("SUPER + SHIFT + SPACE", "Skein menu", o.libexec("skein-menu"))
o.bind("SUPER + SHIFT + code:201", "Skein menu", o.libexec("skein-menu"))
o.bind("SUPER + ESCAPE", "System menu", o.libexec("skein-menu system"))
o.bind("XF86PowerOff", "Power menu", o.libexec("skein-menu system"), { locked = true })
o.bind("SUPER + K", "Show key bindings", o.libexec("skein-menu-keybindings"))
o.bind("SUPER + ALT + K", "Show Tmux key bindings", o.libexec("skein-menu-tmux-keybindings"))
o.bind("XF86Calculator", "Calculator", "gnome-calculator")

-- Aesthetics.
o.bind("SUPER + ALT + SPACE", "Toggle top bar", "skeinctl ui toggle bar")
o.bind("SUPER + CTRL + SPACE", "Next theme background", o.libexec("skein-theme-bg-next"))
o.bind("SUPER + SHIFT + CTRL + SPACE", "Theme menu", o.libexec("skein-menu theme"))
o.bind("SUPER + CTRL + ALT + SPACE", "Background switcher", "qs -c skein ipc call wallpapers open")
o.bind(
  "SUPER + BACKSPACE",
  "Toggle window transparency",
  o.libexec("skein-hyprland-window-transparency-toggle")
)
o.bind(
  "SUPER + SHIFT + BACKSPACE",
  "Toggle window gaps",
  o.libexec("skein-hyprland-window-gaps-toggle")
)
o.bind(
  "SUPER + CTRL + BACKSPACE",
  "Toggle single-window square aspect",
  o.libexec("skein-hyprland-window-single-square-aspect-toggle")
)

-- Notifications.
o.bind("SUPER + COMMA", "Dismiss last notification", "qs -c skein ipc call notifications dismiss")
o.bind("SUPER + SHIFT + COMMA", "Dismiss all notifications", "qs -c skein ipc call notifications dismissAll")
o.bind(
  "SUPER + CTRL + COMMA",
  "Toggle silencing notifications",
  o.libexec("skein-toggle-notification-silencing")
)
o.bind("SUPER + ALT + COMMA", "Invoke last notification", "qs -c skein ipc call notifications invokeLast")
o.bind("SUPER + SHIFT + ALT + COMMA", "Restore last notification", "qs -c skein ipc call notifications restoreLast")

-- Toggles.
o.bind("SUPER + SHIFT + W", "Toggle weather", o.libexec("skein-toggle-weather-check"))
o.bind("SUPER + CTRL + I", "Toggle locking on idle", o.libexec("skein-toggle-idle"))
o.bind("SUPER + CTRL + N", "Toggle nightlight", o.libexec("skein-toggle-nightlight"))
o.bind(
  "SUPER + CTRL + Delete",
  "Toggle laptop display",
  o.libexec("skein-hyprland-monitor-internal toggle")
)
o.bind(
  "SUPER + CTRL + ALT + Delete",
  "Toggle laptop display mirroring",
  o.libexec("skein-hyprland-monitor-internal-mirror toggle")
)
o.bind(
  "switch:on:Lid Switch",
  nil,
  o.libexec("skein-hw-external-monitors")
    .. " && "
    .. o.libexec("skein-hyprland-monitor-internal off"),
  { locked = true }
)
o.bind(
  "switch:off:Lid Switch",
  nil,
  o.libexec("skein-hyprland-monitor-internal on"),
  { locked = true }
)

-- Captures.
o.bind("PRINT", "Screenshot with editing", o.libexec("skein-capture-screenshot"))
o.bind("ALT + PRINT", "Screenrecording", o.libexec("skein-menu screenrecord"))
o.bind("SUPER + PRINT", "Color picker", "pkill hyprpicker || hyprpicker -a")
o.bind(
  "SUPER + CTRL + PRINT",
  "Extract text (OCR) from screenshot",
  o.libexec("skein-capture-text-extraction")
)
o.bind("SUPER + CTRL + S", "Share", o.libexec("skein-menu share"))
o.bind(
  "SUPER + CTRL + PERIOD",
  "Transcode",
  o.libexec("skein-launch-floating-terminal-with-presentation skein-exec skein-transcode")
)

-- Reminders.
o.bind("SUPER + CTRL + R", "Set reminder", o.libexec("skein-menu reminder-set"))
o.bind("SUPER + CTRL + ALT + R", "Show reminders", o.libexec("skein-reminder show"))
o.bind("SUPER + SHIFT + CTRL + R", "Clear reminders", o.libexec("skein-reminder clear"))

-- Information without a bar.
o.bind(
  "SUPER + CTRL + ALT + T",
  "Show time",
  'notify-send -u low "    $(date +"%A %H:%M  ·  %d %B %Y  ·  Week %V")"'
)
o.bind(
  "SUPER + CTRL + ALT + B",
  "Show battery remaining",
  'notify-send -u low "$(' .. o.libexec("skein-battery-status") .. ')"'
)
o.bind(
  "SUPER + CTRL + ALT + W",
  "Show weather",
  'notify-send -u low "$(' .. o.libexec("skein-weather-status") .. ')"'
)

-- Control panels.
o.bind("SUPER + CTRL + A", "Audio controls", "qs -c skein ipc call bar panel audio")
o.bind("SUPER + SHIFT + CTRL + A", "Agent", o.libexec("skein-agent --pick"))
o.bind("SUPER + CTRL + B", "Bluetooth controls", "qs -c skein ipc call bar panel bluetooth")
o.bind("SUPER + CTRL + W", "Wifi controls", "qs -c skein ipc call bar panel network")
o.bind("SUPER + CTRL + T", "Activity", o.libexec("skein-launch-system-monitor"))

-- Zoom.
o.bind("SUPER + CTRL + Z", "Zoom in", function()
  local zoom = hl.get_config("cursor.zoom_factor") or 1
  hl.config({ cursor = { zoom_factor = zoom + 1 } })
end)

o.bind("SUPER + CTRL + ALT + Z", "Reset zoom", function()
  hl.config({ cursor = { zoom_factor = 1 } })
end)

-- Lock system.
o.bind("SUPER + CTRL + L", "Lock system", o.libexec("skein-system-lock"))
