o.exec_on_start("skein-first-run")

-- Slow app launch fix -- set systemd vars.
o.exec_on_start("systemctl --user import-environment $(env | cut -d'=' -f 1)")
o.exec_on_start("dbus-update-activation-environment --systemd --all")

-- Run post-boot hooks after startup config has loaded.
o.exec_on_start("sleep 2 && skein-exec skein-hook post-boot")

-- Clipboard history for the launcher
o.exec_on_start("skein-clipboard watch")
