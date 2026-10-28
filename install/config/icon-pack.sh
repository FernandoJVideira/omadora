# The dock draws app icons from the WhiteSur pack (rounded squares, like macOS). A failed download is
# not fatal: the dock then falls back to your icon theme.
if skein-icon-pack install whitesur; then
  skein-icon-pack apply whitesur
else
  echo "Could not install the icon pack; the dock will use the system icons" >&2
fi
