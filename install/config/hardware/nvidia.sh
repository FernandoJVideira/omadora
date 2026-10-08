# Hyprland environment for the proprietary NVIDIA driver
if lspci -k 2>/dev/null | grep -A3 -E "VGA|3D" | grep -q "Kernel driver in use: nvidia" ||
  [[ -d /proc/driver/nvidia ]]; then
  if ! grep -q "LIBVA_DRIVER_NAME" ~/.config/uwsm/env; then
    cat >>~/.config/uwsm/env <<'ENV'

# NVIDIA
export LIBVA_DRIVER_NAME=nvidia
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export NVD_BACKEND=direct
ENV
  fi
fi
