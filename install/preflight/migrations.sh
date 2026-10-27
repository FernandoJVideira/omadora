SKEIN_MIGRATIONS_STATE_PATH="$HOME"/.local/state/skein/migrations
mkdir -p "$SKEIN_MIGRATIONS_STATE_PATH"

files=("$HOME"/.local/share/skein/migrations/*.sh)

for file in "${files[@]}"; do
  [[ -e "$file" ]] || continue
  touch "$SKEIN_MIGRATIONS_STATE_PATH/${file##*/}"
done
