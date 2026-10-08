# Keep the Nobara boot splash (and avoid rebuilding its initramfs)
if [[ -z "${OMADORA_NOBARA:-}" ]] && [ "$(plymouth-set-default-theme)" != "sliced" ]; then
  omadora-exec omadora-refresh-plymouth
fi
