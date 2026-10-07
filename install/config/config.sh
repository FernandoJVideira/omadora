# Back up existing configs that are about to be overwritten
backup_dir="$HOME/.config/omadora-backup/$(date +%Y%m%d%H%M%S)"
while IFS= read -r -d '' file; do
  rel="${file#"$OMADORA_PATH"/config/}"
  if [[ -e "$HOME/.config/$rel" ]] && ! cmp -s "$file" "$HOME/.config/$rel"; then
    mkdir -p "$backup_dir/$(dirname "$rel")"
    cp -a "$HOME/.config/$rel" "$backup_dir/$rel"
  fi
done < <(find "$OMADORA_PATH/config" -type f -print0)
if [[ -f ~/.bashrc ]] && ! cmp -s "$OMADORA_PATH/default/bashrc" ~/.bashrc; then
  mkdir -p "$backup_dir"
  cp -a ~/.bashrc "$backup_dir/bashrc"
fi
[[ -d "$backup_dir" ]] && echo "Backed up existing configs to: $backup_dir"
unset backup_dir file rel

# Copy over configs
mkdir -p ~/.config
cp -R "$OMADORA_PATH/config/." ~/.config/

# Use default bashrc
cp "$OMADORA_PATH/default/bashrc" ~/.bashrc
