#!/usr/bin/env bash
set -euo pipefail

# Screen sharing now asks what to share in Skein's own picker. Switch it on for existing setups,
# unless another picker is already configured (then it is left alone).
skein-share-picker enable || true
