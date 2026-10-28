# Log in through greetd with the Quickshell greeter (skein-greeter; its colors and logo follow the
# active Skein theme). `skein-remove-kde` drops KDE Plasma altogether.
if [[ -n "${SKEIN_NOBARA:-}" ]]; then
  "$SKEIN_PATH/libexec/skein-greeter" install ||
    echo "WARNING: the greeter didn't install; run skein-greeter install by hand."
fi
