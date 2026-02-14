#!/usr/bin/env bash
# Toggle redshift between off and fixed color temperature 3500K.
set -euo pipefail

STATEFILE="$HOME/.cache/toggle-redshift.state"

if [ -f "$STATEFILE" ] && [ "$(cat "$STATEFILE")" = "on" ]; then
    redshift -x
    echo "off" > "$STATEFILE"
else
    redshift -O 3500K # Standard "warm" coding temp
    echo "on" > "$STATEFILE"
fi

# Principal Engineer move: Signal the bar immediately
pkill -RTMIN+10 i3status-rs
