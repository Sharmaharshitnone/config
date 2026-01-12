#!/usr/bin/env bash

STATEFILE="$HOME/.cache/toggle-redshift.state"

if [ -f "$STATEFILE" ] && [ "$(cat "$STATEFILE")" = "on" ]; then
    # Set text to 3800K (matches the toggle script's fixed value)
    echo "3800K"
    # Exit with code 0 (Good state) or echo a specific color if needed
    exit 0
else
    echo "Off"
    # Exit with code 33 (Info/Idle state) or just 0 and handle in config
    # i3status-rust custom blocks: 
    # Exit code 0: Good (Green usually)
    # Exit code 1: Critical (Red)
    # Exit code 2: Warning (Yellow)
    # Exit code 33: Info (Blue)
    exit 33
fi
