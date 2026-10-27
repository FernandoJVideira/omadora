# Overwrite parts of the skein-menu with user-specific submenus.
# See $SKEIN_PATH/libexec/skein-menu for functions that can be overwritten.
#
# WARNING: Overwritten functions will obviously not be updated when Skein changes.
#
# Example of minimal system menu:
#
# show_system_menu() {
#   case $(menu "System" "  Lock\n󰐥  Shutdown") in
#   *Lock*) skein_run skein-system-lock ;;
#   *Shutdown*) skein_run skein-system-shutdown ;;
#   *) back_to show_main_menu ;;
#   esac
# }
#
# Example of overriding just the about menu action: (Using zsh instead of bash (default))
#
# show_about() {
#   skein_exec skein-launch-or-focus-tui "zsh -c 'fastfetch; read -k 1'"
# }
