#!/usr/bin/env bash
set -euo pipefail

# gh is now part of the base install (git's credential helper for github.com points at it).
# Install it on machines that already have Skein. Logging in is left to the user: 'gh auth login'.
sudo dnf install -y gh || true
