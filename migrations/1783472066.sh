echo "Refreshing configs for changes..."
skeinctl config restore-path starship.toml
skeinctl config restore-path tmux/tmux.conf
skeinctl config restore-path systemd/user/skein-weather-check.timer

echo "Restarting services..."
skeinctl service daemon-reload
skeinctl service restart skein-weather-check.timer
