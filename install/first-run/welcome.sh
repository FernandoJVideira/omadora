title="  Welcome to Skein!"

message=$(
  cat <<'EOF'
Thanks for installing and your support.

• Press <b>Super+Enter</b> to open a terminal.
• Press <b>Super+Space</b> to launch applications.
• Press <b>Super+Esc</b> to open the system menu.
• Press <b>Super+Ctrl+k</b> to search keybindings.

<b>Click to dismiss</b> this message and open the keybindings menu.
EOF
)

notify-send -u critical "$title" "$message"
