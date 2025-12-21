#!/bin/bash

# Simple wallpaper setter for i3
WALLPAPER_DIR="$HOME/Pictures/wallpapers"

# Find a random wallpaper
wallpaper=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) | shuf -n 1)

if [ -n "$wallpaper" ]; then
    # Set wallpaper with xwallpaper
    swaybg -i "$wallpaper" &
    # Update the symlink for compatibility
    ln -sf "$wallpaper" "$WALLPAPER_DIR/w3.jpg"

    # Optional: Run pywal if available (but don't fail if it errors)
    if command -v wal >/dev/null 2>&1; then
        # wal -n -i "$wallpaper" -o "$HOME/.config/wal/postrun" >/dev/null 2>&1 || true
        # Run wal in a subshell and send it to the background
(wal -n -i "$wallpaper" -o ~/.config/sway/pywal.conf &)
    fi

    # Send notification
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -i "$wallpaper" "Wallpaper set: $(basename "$wallpaper")" || true
    fi
fi
