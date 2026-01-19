#!/usr/bin/env bash
# Toggle redshift between off and fixed color temperature 3800K.
# Uses `redshift -O 3800` to set temperature and `redshift -x` to reset, per
# common usage documented on the Arch Linux wiki. This avoids trying to manage
# a long-running redshift PID and is more reliable across setups.

set -euo pipefail

STATEFILE="$HOME/.cache/toggle-redshift.state"

#!/usr/bin/env bash
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
