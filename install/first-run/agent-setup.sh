#!/bin/bash

# Omadora ships no default agent, so invite once rather than picking one for you.

[[ -z $("$OMADORA_PATH/libexec/omadora-default-agent") ]] || exit 0

(
  choice="$(notify-send --wait --urgency=critical --action="default=Choose" \
    "󰚩    Set your default agent" "Let your favorite agent help with Omadora." 2>/dev/null)"
  [[ $choice == default ]] && "$OMADORA_PATH/libexec/omadora-menu" agent
) >/dev/null 2>&1 &
