#!/bin/bash
# Sway Wallpaper Setter
# This script sets a random wallpaper exactly ONCE per execution.

# Safe exit on error
set -euo pipefail

# Configuration
WALLPAPER_DIR="$HOME/Pictures/wallpapers"


# 2. Wait for Sway IPC readiness (max 5 seconds)
for i in {1..25}; do
    swaymsg -t get_outputs >/dev/null 2>&1 && break
    sleep 0.2
done

# 4. Select Random Wallpaper
# We use 'shuf -n 1' to pick exactly one file.
WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) | shuf -n 1)


# 5. Set Wallpaper via swaymsg
# Sway doesn't support wildcard "*" for bg command - must enumerate outputs
for output in $(swaymsg -t get_outputs | jq -r '.[].name'); do
    swaymsg output "$output" bg "$WALLPAPER" fill
done

# 6. Persistence (Optional)
# Symlink for lockscreens or other tools
ln -sf "$WALLPAPER" "$WALLPAPER_DIR/current_wallpaper.jpg"


# 8. Notify
# notify-send "Wallpaper Set" "$(basename "$WALLPAPER")"

exit 0
