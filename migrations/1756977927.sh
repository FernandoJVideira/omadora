echo "Update Ghostty config"

if [ -d "$HOME/.config/ghostty" ]; then
    skein-refresh-config ghostty/config || true
else
    cp -r "$SKEIN_PATH/config/ghostty" "$HOME/.config/"
fi
