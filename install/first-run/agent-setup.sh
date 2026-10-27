#!/bin/bash

# Skein ships no default agent, so invite once rather than picking one for you.

[[ -z $("$SKEIN_PATH/libexec/skein-default-agent") ]] || exit 0

(
  choice="$(notify-send --wait --urgency=critical --action="default=Choose" \
    "󰚩    Set your default agent" "Let your favorite agent help with Skein." 2>/dev/null)"
  [[ $choice == default ]] && "$SKEIN_PATH/libexec/skein-menu" agent
) >/dev/null 2>&1 &
