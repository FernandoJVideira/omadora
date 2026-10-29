o.exec_on_start("skein-first-run")

-- Locks of Chromium-based apps left under an old hostname would stop them from starting.
o.exec_on_start("skein-clean-browser-locks")

-- Liquid Glass is off by default; when it is on, load its plugin once Hyprland is up.
o.exec_on_start("skein-glass boot")

-- Slow app launch fix -- set systemd vars.
o.exec_on_start("systemctl --user import-environment $(env | cut -d'=' -f 1)")
o.exec_on_start("dbus-update-activation-environment --systemd --all")

-- Run post-boot hooks after startup config has loaded.
o.exec_on_start("sleep 2 && skein-exec skein-hook post-boot")

-- Clipboard history for the launcher
o.exec_on_start("skein-clipboard watch")
