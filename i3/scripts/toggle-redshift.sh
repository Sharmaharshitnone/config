#!/usr/bin/env bash
# Toggle redshift between off and fixed color temperature 3800K.
# Uses `redshift -O 3800` to set temperature and `redshift -x` to reset, per
# common usage documented on the Arch Linux wiki. This avoids trying to manage
# a long-running redshift PID and is more reliable across setups.

set -euo pipefail

STATEFILE="$HOME/.cache/toggle-redshift.state"
TEMP=3800

notify() {
    # non-fatal if notify-send isn't available
    command -v notify-send >/dev/null 2>&1 && notify-send "redshift" "$1" || true
}

ensure_display() {
    # If DISPLAY is empty (rare when invoked from some contexts), try :0
    if [ -z "${DISPLAY-}" ]; then
        export DISPLAY=:0
    fi
}

status() {
    if [ -f "$STATEFILE" ] && [ "$(cat "$STATEFILE")" = "on" ]; then
        echo "on"
    else
        echo "off"
    fi
}

turn_on() {
    ensure_display
    # Set color temperature
    if redshift -O "$TEMP" >/dev/null 2>&1; then
        echo on > "$STATEFILE"
        notify "enabled ($TEMP K)"
    else
        notify "failed to enable"
        return 1
    fi
}

turn_off() {
    ensure_display
    # Reset color temperature
    if redshift -x >/dev/null 2>&1; then
        echo off > "$STATEFILE"
        notify "disabled"
    else
        notify "failed to disable"
        return 1
    fi
}

case "${1-}" in
    --status)
        status
        ;;
    --on)
        turn_on
        ;;
    --off)
        turn_off
        ;;
    *)
        if [ "$(status)" = "on" ]; then
            turn_off
        else
            turn_on
        fi
        ;;
esac

