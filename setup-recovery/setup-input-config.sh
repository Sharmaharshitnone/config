#!/usr/bin/env bash
# Setup trackpad/input configuration for optimal usability
# Applies both Sway (modern) and i3 (X11) input settings

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

log_info "Setting up trackpad and input configurations..."

# === SWAY INPUT CONFIGURATION ===
log_info "Configuring Sway input devices (if Sway is installed)..."

SWAY_INPUT_DIR="${HOME}/.config/sway/config.d"
if [[ -d "$SWAY_INPUT_DIR" ]]; then
    cat > "$SWAY_INPUT_DIR/20-input.conf" << 'EOF'
### Input configuration
#
# Keyboard: High Speed for Coding
input type:keyboard {
    repeat_delay 200
    repeat_rate 45
    xkb_layout us
    # Options: caps:escape maps CapsLock to Esc (Crucial for Vim)
    xkb_options caps:swapescape,altwin:menu_win
}

# Touchpad: Mac-like Feel
input type:touchpad {
    dwt enabled             # Disable While Typing
    tap enabled             # Tap to click
    natural_scroll disable  # Standard scrolling
    middle_emulation enabled
    accel_profile adaptive
    pointer_accel 0.1
}
EOF
    log_info "  ✓ Sway input config created: $SWAY_INPUT_DIR/20-input.conf"
else
    log_warn "Sway config directory not found (skipping Sway input setup)"
fi

# === I3 XINPUT CONFIGURATION (X11) ===
log_info "Configuring i3/X11 touchpad via xinput..."

# Check if xinput is available
if ! command -v xinput &>/dev/null; then
    log_warn "xinput not found (install xorg-xinput for X11 trackpad support)"
    exit 0
fi

# Apply immediately if X11 is running
if [[ -n "${DISPLAY:-}" ]]; then
    log_info "Applying touchpad settings to current X11 session..."
    
    # Enable tapping on all detected touchpads
    for TOUCHPAD in $(xinput list | grep -i "touchpad\|elantech\|synaptics" | awk '{print $NF}' | tr -d '[]'); do
        if [[ "$TOUCHPAD" =~ ^[0-9]+$ ]]; then
            log_info "  Setting tapping for device $TOUCHPAD..."
            xinput set-prop "$TOUCHPAD" "libinput Tapping Enabled" 1 2>/dev/null || \
            xinput set-prop "$TOUCHPAD" "Tapping Enabled" 1 2>/dev/null || \
            log_warn "    Could not enable tapping on device $TOUCHPAD"
            
            # Enable natural scrolling disabled (standard scrolling)
            xinput set-prop "$TOUCHPAD" "libinput Natural Scrolling Enabled" 0 2>/dev/null || \
            xinput set-prop "$TOUCHPAD" "Natural Scrolling" 0 2>/dev/null || true
            
            # Set pointer acceleration
            xinput set-prop "$TOUCHPAD" "libinput Accel Speed" 0.1 2>/dev/null || \
            xinput set-prop "$TOUCHPAD" "Pointer Acceleration" 0.1 2>/dev/null || true
        fi
    done
else
    log_warn "X11 DISPLAY not set (X11 session not active)"
fi

# === I3 STARTUP SCRIPT CONFIGURATION ===
log_info "Configuring i3 startup touchpad settings..."

I3_CONFIG_FILE="${HOME}/.config/i3/config"
if [[ -f "$I3_CONFIG_FILE" ]]; then
    # Check if touchpad config already exists
    if grep -q "libinput Tapping Enabled" "$I3_CONFIG_FILE"; then
        log_info "  ✓ i3 touchpad config already present"
    else
        log_info "  Adding touchpad startup commands to i3 config..."
        cat >> "$I3_CONFIG_FILE" << 'EOF'

# === Touchpad Configuration (auto-apply on startup) ===
exec --no-startup-id xinput set-prop "ELAN0420:00 04F3:3240 Touchpad" "libinput Tapping Enabled" 1 2>/dev/null || true
exec --no-startup-id xinput set-prop "ETPS/2 Elantech Touchpad" "libinput Tapping Enabled" 1 2>/dev/null || true
exec --no-startup-id xinput set-prop "Synaptics TM3075-002" "libinput Tapping Enabled" 1 2>/dev/null || true
EOF
        log_info "  ✓ Touchpad startup commands added to i3 config"
    fi
else
    log_warn "i3 config file not found: $I3_CONFIG_FILE"
fi

# === SUMMARY ===
log_info ""
log_info "✓ Input configuration complete!"
log_info ""
log_info "Configurations applied:"
log_info "  ✓ Keyboard: repeat_delay=200ms, repeat_rate=45/sec, Caps→Esc"
log_info "  ✓ Touchpad: tapping enabled, natural_scroll disabled, accel=0.1"
log_info "  ✓ Sway: Modern input configuration (config.d/20-input.conf)"
log_info "  ✓ i3/X11: xinput commands for immediate and startup application"
log_info ""
log_info "For Sway users: Reload with: swaymsg reload"
log_info "For i3 users: Reload with: i3-msg reload"
log_info ""
