#!/usr/bin/env bash
# i3-marks: Vim-style mark operations via themed dmenu
# Usage: i3-marks.sh {goto|set|swap}

set -euo pipefail

# ── Source shared dmenu theme ─────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/dmenu-theme.sh"

get_marks() {
    i3-msg -t get_marks 2>/dev/null | tr -d '[]"' | tr ',' '\n' | sort
}

case "${1:-}" in
    goto)
        marks=$(get_marks)
        if [[ -z "$marks" ]]; then
            notify-send -t 1500 "Marks" "No marks set"
            exit 0
        fi
        mark=$(echo "$marks" | dmenu_themed -p "  Go to mark:")
        [[ -n "$mark" ]] && i3-msg "[con_mark=\"^${mark}$\"] focus" >/dev/null
        ;;
    set)
        mark=$(echo "" | dmenu_themed -p "  Set mark:")
        [[ -n "$mark" ]] && i3-msg "mark --toggle ${mark}" >/dev/null
        ;;
    swap)
        marks=$(get_marks)
        if [[ -z "$marks" ]]; then
            notify-send -t 1500 "Marks" "No marks set"
            exit 0
        fi
        mark=$(echo "$marks" | dmenu_themed -p "  Swap with:")
        [[ -n "$mark" ]] && i3-msg "swap container with mark ${mark}" >/dev/null
        ;;
    *)
        echo "Usage: i3-marks.sh {goto|set|swap}"
        exit 1
        ;;
esac
