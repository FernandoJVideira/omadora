# Copy all bundled icons to the applications/icons directory
ICON_DIR="$HOME/.local/share/applications/icons"
ICON_SOURCE_DIR="${SKEIN_PATH:-$HOME/.local/share/skein}/applications/icons"

mkdir -p "$ICON_DIR"
cp "$ICON_SOURCE_DIR"/*.png "$ICON_DIR/"
