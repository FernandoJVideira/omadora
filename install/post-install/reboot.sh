clear
if [[ -n "${OMADORA_NOBARA:-}" ]]; then
  cat ~/.local/share/omadora/logo.txt
  echo
  echo "You're done! Log out and pick \"Hyprland (uwsm-managed)\" at the login screen,"
  echo "or run \"omadora\" from a TTY."
  return 0
fi
cat ~/.local/share/omadora/logo.txt
echo
echo "You're done! So we're rebooting now..."
sleep 5
reboot
