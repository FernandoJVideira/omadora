# Set the default GDK_SCALE from what the monitor is currently reporting

sed -i -E "s|^local skein_gdk_scale = .*|local skein_gdk_scale = $(skein-exec skein-hyprland-monitor-scale)|" ~/.config/hypr/monitors.lua
