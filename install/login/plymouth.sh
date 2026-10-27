# Keep the Nobara boot splash (and avoid rebuilding its initramfs)
if [[ -z "${SKEIN_NOBARA:-}" ]] && [ "$(plymouth-set-default-theme)" != "sliced" ]; then
  skein-exec skein-refresh-plymouth
fi
