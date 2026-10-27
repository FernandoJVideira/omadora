# shellcheck shell=bash

if [[ -n "${SKEIN_INITIALIZED:-}" ]]; then
  return 0
fi

readonly SKEIN_INITIALIZED=1

readonly SKEIN_ROOT="${SKEIN_ROOT:-$(
  cd -- "$(dirname "${BASH_SOURCE[0]}")/../.." &&
    pwd
)}"

# shellcheck source=paths.sh
source "$SKEIN_ROOT/lib/common/paths.sh"

# shellcheck source=common.sh
source "$SKEIN_ROOT/lib/common/common.sh"
