# Back up existing configs that are about to be overwritten
backup_dir="$HOME/.config/skein-backup/$(date +%Y%m%d%H%M%S)"
while IFS= read -r -d '' file; do
  rel="${file#"$SKEIN_PATH"/config/}"
  if [[ -e "$HOME/.config/$rel" ]] && ! cmp -s "$file" "$HOME/.config/$rel"; then
    mkdir -p "$backup_dir/$(dirname "$rel")"
    cp -a "$HOME/.config/$rel" "$backup_dir/$rel"
  fi
done < <(find "$SKEIN_PATH/config" -type f -print0)
if [[ -f ~/.bashrc ]] && ! cmp -s "$SKEIN_PATH/default/bashrc" ~/.bashrc; then
  mkdir -p "$backup_dir"
  cp -a ~/.bashrc "$backup_dir/bashrc"
fi
[[ -d "$backup_dir" ]] && echo "Backed up existing configs to: $backup_dir"
unset backup_dir file rel

# Copy over configs
mkdir -p ~/.config
cp -R "$SKEIN_PATH/config/." ~/.config/

# Use default bashrc
cp "$SKEIN_PATH/default/bashrc" ~/.bashrc
