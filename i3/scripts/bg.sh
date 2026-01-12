#!/bin/bash

# Simple wallpaper setter for i3
WALLPAPER_DIR="$HOME/Pictures/wallpapers"

# Find a random wallpaper (null-safe, single pipeline)
wallpaper=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) -print0 | shuf -z -n1 | tr -d '\0')

if [ -n "$wallpaper" ]; then
    # Set wallpaper based on actual display server (reliable detection)
    if [ -n "$WAYLAND_DISPLAY" ] && command -v swaymsg >/dev/null 2>&1; then
        # Wayland session
        swaymsg output "*" bg "$wallpaper" fill
    elif [ -n "$DISPLAY" ] && command -v xwallpaper >/dev/null 2>&1; then
        # X11 session
        xwallpaper --zoom "$wallpaper"
    else
        # Fallback: try feh if available
        command -v feh >/dev/null 2>&1 && feh --bg-fill "$wallpaper" || true
    fi

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
