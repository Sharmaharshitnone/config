# i3status-rust Improvements and Best Practices

This document outlines recommended improvements for the i3status-rust configuration based on research from official documentation, community best practices, and modern statusbar design principles.

---

## Table of Contents

1. [High Priority Improvements](#high-priority-improvements)
2. [Medium Priority Improvements](#medium-priority-improvements)
3. [Low Priority / Nice-to-Have](#low-priority--nice-to-have)
4. [Performance Optimizations](#performance-optimizations)
5. [Security Considerations](#security-considerations)
6. [Advanced Features](#advanced-features)
7. [Implementation Guide](#implementation-guide)

---

## High Priority Improvements

### 1. Add Disk Space Monitoring

**Current:** No disk space block present.

**Recommendation:** Add disk space monitoring to prevent storage issues.

```toml
[[block]]
block = "disk_space"
path = "/"
info_type = "available"
alert_unit = "GB"
interval = 60
warning = 20.0
alert = 10.0
format = "<span size='large'>󰋊</span> <span rise='1000'>$available / $total</span>"
format_alt = "<span size='large'>󰋊</span> <span rise='1000'>$percentage</span>"
[[block.click]]
button = "left"
cmd = "thunar /"
```

**Additional mount point (for /home):**
```toml
[[block]]
block = "disk_space"
path = "/home"
info_type = "available"
interval = 60
warning = 20.0
alert = 10.0
format = "<span size='large'>󱂵</span> <span rise='1000'>$available</span>"
```

---

### 2. Add Network Status Block

**Current:** No network monitoring.

**Recommendation:** Add network block for connection status and speeds.

```toml
[[block]]
block = "net"
device = "wlan0"
format = "<span size='large'>$icon</span> <span rise='1000'>{$signal_strength|}</span>"
format_alt = "<span size='large'>$icon</span> <span rise='1000'>↓$speed_down ↑$speed_up</span>"
interval = 5
missing_format = ""
[[block.click]]
button = "left"
cmd = "nm-connection-editor"
[[block.click]]
button = "right"
cmd = "tmux select-window -t scratchpad:nmtui 2>/dev/null || tmux new-window -t scratchpad -n nmtui nmtui; i3-msg scratchpad show"
```

---

### 3. Add Notification Block

**Current:** Using dunst but no indicator in status bar.

**Recommendation:** Add notification status/count.

```toml
[[block]]
block = "notify"
format = "<span size='large'>$icon</span> {$count|}"
driver = "dunst"
[[block.click]]
button = "left"
cmd = "dunstctl history-pop"
[[block.click]]
button = "right"
cmd = "dunstctl close-all"
[[block.click]]
button = "middle"
action = "toggle_paused"
```

---

### 4. Improve Error Handling with `error_format`

**Current:** No global error formatting.

**Recommendation:** Add global error configuration for better UX.

```toml
# Add at the top of config.toml
error_format = "<span foreground='#fb4934'>⚠ $short_error_message</span>"
error_fullscreen_format = "<span foreground='#fb4934' size='large'>Error: $full_error_message</span>"
```

---

### 5. Add Weather Block

**Current:** No weather information.

**Recommendation:** Add weather for at-a-glance forecast.

```toml
[[block]]
block = "weather"
format = "<span size='large'>$icon</span> <span rise='1000'>$temp $location</span>"
format_alt = "<span size='large'>$icon</span> <span rise='1000'>$weather $temp, $humidity, $wind</span>"
interval = 600
[block.service]
name = "openweathermap"
api_key = "YOUR_API_KEY"  # Store in environment variable!
city_id = "YOUR_CITY_ID"
units = "metric"
```

**Alternative (no API key):**
```toml
[[block]]
block = "custom"
command = "curl -s 'wttr.in/?format=%c+%t' | head -1"
interval = 600
format = "<span size='large'>$text</span>"
hide_when_empty = true
```

---

## Medium Priority Improvements

### 6. Add Bluetooth Block

**Current:** Using blueman-applet but no status bar indicator.

**Recommendation:**

```toml
[[block]]
block = "bluetooth"
format = "<span size='large'>$icon{ $name|}</span>"
format_alt = "<span size='large'>$icon</span> <span rise='1000'>$name - $percentage</span>"
mac = ""  # Leave empty to show any connected device
disconnected_format = ""  # Hide when disconnected
[[block.click]]
button = "left"
cmd = "blueman-manager"
[[block.click]]
button = "right"
cmd = "bluetoothctl power toggle"
```

---

### 7. Improve CPU Block with Barchart

**Current:** Shows utilization and frequency.

**Enhancement:** Add per-core barchart for visual load distribution.

```toml
[[block]]
block = "cpu"
interval = 1
format = "<span size='large'></span> <span rise='1000'>$barchart $utilization</span>"
format_alt = "<span size='large'></span> <span rise='1000'>$utilization $frequency{ $boost|}</span>"
info_cpu = 30
warning_cpu = 60
critical_cpu = 90
[[block.click]]
button = "left"
cmd = "tmux select-window -t scratchpad:btop 2>/dev/null || tmux new-window -t scratchpad -n btop btop; i3-msg scratchpad show"
```

**Benefits:** The barchart (`▁▂▃▄▅▆▇█`) shows per-core utilization at a glance.

---

### 8. Add Keyboard Layout Indicator

**Current:** Using `setxkbmap` but no visual indicator.

**Recommendation:**

```toml
[[block]]
block = "keyboard_layout"
format = "<span size='large'>󰌌</span> <span rise='1000'>$layout</span>"
driver = "setxkbmap"
interval = 1
[[block.click]]
button = "left"
cmd = "setxkbmap -option && setxkbmap -option grp:alt_shift_toggle us,ru"
```

---

### 9. Add Pomodoro Timer Block

**Current:** Using custom stopwatch.

**Enhancement:** Replace with dedicated pomodoro functionality.

```toml
[[block]]
block = "pomodoro"
format = "<span size='large'>$icon</span> <span rise='1000'>{$time_remaining|$completed}</span>"
format_stopped = "<span size='large'>󰐥</span>"
length = 25  # 25 minutes work
break_length = 5  # 5 minutes break
notify_cmd = "notify-send 'Pomodoro' 'Time for a break!'"
break_notify_cmd = "notify-send 'Break Over' 'Back to work!'"
[[block.click]]
button = "left"
action = "toggle"
[[block.click]]
button = "right"
action = "stop"
```

---

### 10. Add Kdeconnect Integration

**Current:** No phone integration.

**Recommendation:**

```toml
[[block]]
block = "kdeconnect"
format = "<span size='large'>$icon</span> {$name $bat_icon $notification_icon|}"
format_disconnected = ""
device_id = ""  # Leave empty to use first available
[[block.click]]
button = "left"
cmd = "kdeconnect-indicator"
[[block.click]]
button = "right"
cmd = "kdeconnect-sms"
```

---

## Low Priority / Nice-to-Have

### 11. Add GPU Monitoring (NVIDIA/AMD)

```toml
# For NVIDIA
[[block]]
block = "nvidia_gpu"
format = "<span size='large'>󰢮</span> <span rise='1000'>$utilization $temperature</span>"
interval = 5
[[block.click]]
button = "left"
cmd = "nvtop"
```

---

### 12. Add Package Updates Counter

```toml
[[block]]
block = "pacman"
format = "<span size='large'>󰏔</span> {$pacman + $aur|Up to date}"
format_singular = "<span size='large'>󰏔</span> $count update"
format_up_to_date = ""  # Hide when up to date
interval = 3600  # Check hourly
aur_command = "yay -Qu"
[[block.click]]
button = "left"
cmd = "kitty -e yay -Syu"
```

---

### 13. Add System Load Average

```toml
[[block]]
block = "load"
format = "<span size='large'>󰑓</span> <span rise='1000'>$1m $5m</span>"
interval = 5
info = 3.0
warning = 5.0
critical = 10.0
```

---

### 14. Add Docker Container Status

```toml
[[block]]
block = "docker"
format = "<span size='large'>󰡨</span> <span rise='1000'>$running/$total</span>"
interval = 10
[[block.click]]
button = "left"
cmd = "kitty -e lazydocker"
```

---

### 15. Add Calendar/Agenda Integration

```toml
[[block]]
block = "custom"
command = "calcurse -a 2>/dev/null | head -3 | tr '\n' ' '"
interval = 300
format = "<span size='large'>󰃭</span> <span rise='1000'>{$text|No events}</span>"
hide_when_empty = true
[[block.click]]
button = "left"
cmd = "tmux select-window -t scratchpad:calcurse 2>/dev/null || tmux new-window -t scratchpad -n calcurse calcurse; i3-msg scratchpad show"
```

---

## Performance Optimizations

### 16. Reduce Polling Frequency

**Current Issues:**
- CPU block at 1s (high CPU usage)
- Timer at 1s (necessary for stopwatch)

**Recommendations:**
```toml
# CPU: Increase to 2-5 seconds unless you need real-time monitoring
[[block]]
block = "cpu"
interval = 2  # Was 1

# Memory: 10 seconds is usually sufficient
[[block]]
block = "memory"
interval = 10  # Was 5

# Battery: 30-60 seconds is fine for most use cases
[[block]]
block = "battery"
interval = 30  # Was 5

# VPN: Can use signals instead of polling
[[block]]
block = "custom"
# ... warp status ...
interval = "once"
signal = 14
# Add to warp command: && pkill -RTMIN+14 i3status-rs
```

---

### 17. Use Signals Instead of Polling

**Current:** Many blocks poll even when values don't change.

**Optimization:** Use `interval = "once"` with signals for event-driven updates.

```toml
# Example: Backlight (only changes when you change it)
[[block]]
block = "backlight"
interval = "once"
# Signal when brightness changes via keybind:
# brightnessctl set +5% && pkill -RTMIN+15 i3status-rs
```

**Signal Reference:**
| Signal | Recommended Use |
|--------|-----------------|
| RTMIN+10 | Redshift (existing) |
| RTMIN+11 | Timer (existing) |
| RTMIN+12 | Power Mode (existing) |
| RTMIN+13 | Picom (existing) |
| RTMIN+14 | VPN Status |
| RTMIN+15 | Backlight |
| RTMIN+16 | Network |

---

### 18. Optimize Custom Block Commands

**Current:** Some commands use multiple subshells.

**Optimization Examples:**

```bash
# Before (power mode):
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor | sed -e 's/performance/⚡ Perf/' -e 's/powersave/🌱 Save/'

# After (direct read, single sed):
sed 's/performance/⚡ Perf/;s/powersave/🌱 Save/' /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
```

---

## Security Considerations

### 19. Secure API Keys

**Issue:** Weather block requires API key.

**Solution:** Use environment variables.

```toml
[[block]]
block = "weather"
[block.service]
name = "openweathermap"
api_key = "$OPENWEATHERMAP_API_KEY"  # Set in shell profile
```

---

### 20. Sanitize Custom Command Output

**Issue:** Custom blocks output raw text which could be exploited via pango markup injection.

**Solution:** Use `.pango-str()` to sanitize:

```toml
format = "$text.pango-str()"  # Escapes special characters
```

---

### 21. Avoid Storing Secrets in State Files

**Issue:** Some scripts store state in world-readable `/tmp`.

**Solution:** Use `$XDG_RUNTIME_DIR` which is user-owned:

```bash
# Before:
STATE_FILE="/tmp/i3_timer.state"

# After:
STATE_FILE="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/i3_timer.state"
```

---

## Advanced Features

### 22. Add Format Toggling to All Blocks

**Pattern:** Every block should have `format` and `format_alt` for information density.

```toml
[[block]]
block = "temperature"
format = "<span size='large'></span><span rise='1000'> $average</span>"
format_alt = "<span size='large'></span><span rise='1000'> min:$min max:$max avg:$average</span>"
```

---

### 23. Add Conditional Formatting

**Use Case:** Show different formats based on state.

```toml
[[block]]
block = "battery"
format = "$icon $percentage"
charging_format = "$icon $percentage ⚡"
full_format = "$icon Full"
empty_format = "󰂎 CRITICAL!"
not_charging_format = "$icon $percentage (not charging)"
```

---

### 24. Add Theme Variants for Day/Night

**Concept:** Use two config files and switch based on time.

```bash
#!/bin/bash
# ~/.config/i3/scripts/theme-switcher.sh
HOUR=$(date +%H)
if [ $HOUR -ge 8 ] && [ $HOUR -lt 20 ]; then
    ln -sf ~/.config/i3status-rust/config-day.toml ~/.config/i3status-rust/config.toml
else
    ln -sf ~/.config/i3status-rust/config-night.toml ~/.config/i3status-rust/config.toml
fi
pkill -USR2 i3status-rs  # Restart with new config
```

---

### 25. Add Multi-Monitor Support

**Issue:** Status bar content may differ per monitor.

**Solution:** Use multiple config files with bar-specific blocks.

```bash
# In i3 config:
bar {
    output primary
    status_command i3status-rs ~/.config/i3status-rust/config-primary.toml
}
bar {
    output HDMI-1
    status_command i3status-rs ~/.config/i3status-rust/config-secondary.toml
}
```

---

## Implementation Guide

### Quick Wins (Implement First)
1. ✅ Add disk space block
2. ✅ Add network block
3. ✅ Add notification block
4. ✅ Add `error_format` global config
5. ✅ Increase polling intervals

### Medium Effort
1. Add Bluetooth block
2. Improve CPU block with barchart
3. Add format_alt to all blocks
4. Convert polling to signals where possible

### Advanced (Weekend Project)
1. Add weather integration
2. Add pomodoro functionality
3. Implement day/night themes
4. Add multi-monitor configs
5. Add KDE Connect integration

---

## Summary

### Current Strengths ✓
- Excellent scratchpad integration via tmux
- Consistent Gruvbox theming
- Signal-based updates for key blocks
- Comprehensive click actions

### Areas for Improvement
- Missing system monitoring (disk, network)
- No notification indicator
- Some blocks poll unnecessarily
- Could benefit from format toggling everywhere
- Security: state files should use XDG_RUNTIME_DIR

### Recommended Priority
1. **Disk Space** - Critical for preventing storage issues
2. **Network** - Essential for laptop users
3. **Notification Block** - Better dunst integration
4. **Performance Tuning** - Reduce polling where possible

---

*Document generated based on i3status-rust official documentation, GitHub issues, and community configurations.*
