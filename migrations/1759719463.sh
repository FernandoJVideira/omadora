echo "Add the Flexoki Light theme"

if [[ ! -L ~/.config/skein/themes/flexoki-light ]]; then
  ln -nfs ~/.local/share/skein/themes/flexoki-light ~/.config/skein/themes/
fi
