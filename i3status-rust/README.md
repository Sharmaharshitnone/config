# i3status-rust Configuration Documentation

A comprehensive documentation of my i3status-rust setup - a feature-rich, resource-friendly status bar for i3wm written in Rust.

## Table of Contents

- [Overview](#overview)
- [Theme Configuration](#theme-configuration)
- [Icons Configuration](#icons-configuration)
- [Blocks Overview](#blocks-overview)
  - [Task/TimeWarrior Block](#1-tasktimewarrior-block)
  - [Date Block](#2-date-block)
  - [Time Block](#3-time-block)
  - [Focused Window Block](#4-focused-window-block)
  - [Uptime Block](#5-uptime-block)
  - [CPU Block](#6-cpu-block)
  - [Memory Block](#7-memory-block)
  - [Volume Block](#8-volume-block)
  - [Microphone Block](#9-microphone-block)
  - [Backlight Block](#10-backlight-block)
  - [Timer Block](#11-timer-block)
  - [Music Block](#12-music-block)
  - [Power Mode Block](#13-power-mode-block)
  - [Battery Block](#14-battery-block)
  - [Temperature Block](#15-temperature-block)
  - [Redshift Block](#16-redshift-block)
  - [Picom Toggle Block](#17-picom-toggle-block)
  - [Background Wallpaper Block](#18-background-wallpaper-block)
  - [VPN Status Block](#19-vpn-status-block)
  - [Daily Notes Block](#20-daily-notes-block)
- [Helper Scripts](#helper-scripts)
- [Dependencies](#dependencies)
- [Key Bindings](#key-bindings)

---

## Overview

This configuration provides a fully-featured status bar with:
- **Gruvbox Dark Theme** with transparent backgrounds
- **Material Nerd Font Icons** for visual appeal
- **Scratchpad Integration** for quick access to tools via tmux
- **Custom Scripts** for advanced functionality
- **Click Actions** on every block for interactivity

**Location:** `~/.config/i3status-rust/config.toml`

**Bar Command:** `i3status-rs ~/.config/i3status-rust/config.toml`

---

## Theme Configuration

```toml
[theme]
theme = "gruvbox-dark"
overrides = { 
    idle_bg = "none", 
    idle_fg = "#ebdbb2", 
    info_bg = "none", 
    info_fg = "#83a598", 
    good_bg = "none", 
    good_fg = "#b8bb26", 
    warning_bg = "none", 
    warning_fg = "#fabd2f", 
    critical_bg = "none", 
    critical_fg = "#fb4934", 
    separator = "  ", 
    separator_bg = "none", 
    separator_fg = "none" 
}
```

### Color Palette (Gruvbox)
| Color | Hex Code | Usage |
|-------|----------|-------|
| Foreground (Light) | `#ebdbb2` | Default text (idle state) |
| Blue | `#83a598` | Info state |
| Green | `#b8bb26` | Good state |
| Yellow | `#fabd2f` | Warning state |
| Red | `#fb4934` | Critical state |
| Background | `none` | Transparent backgrounds |

### Why Transparent Backgrounds?
Using `none` for all backgrounds creates a minimal, floating-text appearance that integrates seamlessly with the i3bar background color (`#282828`).

---

## Icons Configuration

```toml
icons_format = "<span size='large'>{icon}</span>"

[icons]
icons = "material-nf"
```

**Icon Set:** `material-nf` (Material Design icons from Nerd Fonts)

**Requirement:** Install a Nerd Font (e.g., JetBrainsMono Nerd Font) for icons to render correctly.

---

## Blocks Overview

### 1. Task/TimeWarrior Block
**Purpose:** Displays current task being tracked with TimeWarrior

```toml
[[block]]
block = "custom"
command = "timew | awk '/^Tracking/ { sub(/^Tracking /, \"\"); task=$0 } /Total|Current/ { time=$2 } END { if (task) print \" \" task \" (\" time \")\" }'"
interval = 10
format = "$text"
[[block.click]]
button = "left"
cmd = "tmux select-window -t scratchpad:vit 2>/dev/null || tmux new-window -t scratchpad -n vit vit; i3-msg scratchpad show"
```

**Features:**
- Shows task name and duration
- Left-click opens `vit` (taskwarrior TUI) in scratchpad

**Dependencies:** `timewarrior`, `taskwarrior`, `vit`

---

### 2. Date Block
**Purpose:** Shows current date with calendar icon

```toml
[[block]]
block = "time"
format = "<span weight='bold' size='large'></span> <span rise='1000'>$timestamp.datetime(f:'%a %d %b')</span>"
interval = 60
[[block.click]]
button = "left"
cmd = "tmux select-window -t scratchpad:calcurse 2>/dev/null || tmux new-window -t scratchpad -n calcurse calcurse; i3-msg scratchpad show"
[[block.click]]
button = "right"
cmd = "tmux select-window -t scratchpad:vit 2>/dev/null || tmux new-window -t scratchpad -n vit vit; i3-msg scratchpad show"
```

**Format:** `Wed 15 Jan` (Day of week, day, month)

**Click Actions:**
- Left: Opens `calcurse` calendar
- Right: Opens `vit` task manager

---

### 3. Time Block
**Purpose:** Shows current time with clock icon

```toml
[[block]]
block = "time"
interval = 60
format = "<span size='large' weight='bold' >$icon</span> <span rise='1000'>$timestamp.datetime(f:'%I:%M %p')</span>"
[[block.click]]
button = "left"
cmd = "tmux select-window -t scratchpad:peaclock 2>/dev/null || tmux new-window -t scratchpad -n peaclock peaclock; i3-msg scratchpad show"
```

**Format:** `09:30 AM` (12-hour format)

**Click Action:** Opens `peaclock` (aesthetic terminal clock)

---

### 4. Focused Window Block
**Purpose:** Displays title of currently focused window

```toml
[[block]]
block = "focused_window"
format = " $title.str(max_w:30) |"
```

**Features:**
- Truncates long titles to 30 characters
- Adds separator after window title

---

### 5. Uptime Block
**Purpose:** Shows system uptime

```toml
[[block]]
block = "uptime"
interval = 60
format = "<span weight='bold' size='large'>UP:</span><span rise='1000'>$text</span>"
```

**Format:** `UP:2d 5h` (days and hours)

---

### 6. CPU Block
**Purpose:** Shows CPU utilization and frequency

```toml
[[block]]
block = "cpu"
interval = 1
format = "<span size='large'></span> <span rise='1000'>$utilization $frequency</span>"
[[block.click]]
button = "left"
cmd = "tmux select-window -t scratchpad:btop 2>/dev/null || tmux new-window -t scratchpad -n btop btop; i3-msg scratchpad show"
[[block.click]]
button = "right"
cmd = "tmux select-window -t scratchpad:htop 2>/dev/null || tmux new-window -t scratchpad -n htop htop; i3-msg scratchpad show"
```

**Displayed Values:**
- CPU icon (chip symbol)
- Utilization percentage
- Current frequency

**Click Actions:**
- Left: Opens `btop` (modern system monitor)
- Right: Opens `htop` (classic process viewer)

---

### 7. Memory Block
**Purpose:** Shows RAM usage

```toml
[[block]]
block = "memory"
format = "<span size='large'></span> <span rise='1000'> $mem_used_percents</span>"
format_alt = "<span size='large'></span> <span rise='1000'> $mem_used / $mem_total </span>"
interval = 5
warning_mem = 80
critical_mem = 95
```

**Features:**
- Default: Shows percentage
- Click toggles: Shows actual used/total values
- Warning at 80%, Critical at 95%

---

### 8. Volume Block
**Purpose:** Controls speaker volume

```toml
[[block]]
block = "sound"
driver = "pulseaudio"
format = "<span weight='bold' size='x-large'>$icon</span> <span rise='1000'>$volume</span>"
show_volume_when_muted = true
[[block.click]]
button = "left"
cmd = "i3-msg exec pavucontrol"
[[block.click]]
button = "right"
action = "toggle_mute"
```

**Features:**
- Dynamic icon based on volume level
- Shows muted state
- Left-click: Opens `pavucontrol`
- Right-click: Toggle mute

---

### 9. Microphone Block
**Purpose:** Controls microphone volume

```toml
[[block]]
block = "sound"
driver = "pulseaudio"
device_kind = "source"
format = "<span weight='bold' size='x-large'>$icon</span> <span rise='1000'>$volume</span>"
show_volume_when_muted = true
[[block.click]]
button = "left"
cmd = "pavucontrol"
[[block.click]]
button = "right"
action = "toggle_mute"
```

**Features:**
- Separate from speaker block
- Same click actions as volume

---

### 10. Backlight Block
**Purpose:** Shows and controls screen brightness

```toml
[[block]]
block = "backlight"
cycle = [10, 30, 60, 100]
format = "<span size='large'>$icon</span> <span rise='1000'>$brightness</span>"
missing_format = ""
```

**Features:**
- Click cycles through preset brightness levels: 10%, 30%, 60%, 100%
- Hides block if no backlight device found

---

### 11. Timer Block
**Purpose:** Stopwatch functionality

```toml
[[block]]
block = "custom"
command = "~/.config/i3/scripts/timer_control.sh read"
interval = 1
signal = 11
json = true
[[block.click]]
button = "left"
cmd = "~/.config/i3/scripts/timer_control.sh toggle && pkill -RTMIN+11 i3status-rs"
[[block.click]]
button = "right"
cmd = "~/.config/i3/scripts/timer_control.sh reset && pkill -RTMIN+11 i3status-rs"
```

**Features:**
- Start/pause timer with left-click
- Reset timer with right-click
- JSON output for state-based coloring
- Real-time signal updates (SIGRTMIN+11)

**Script:** `timer_control.sh` (see Helper Scripts section)

---

### 12. Music Block
**Purpose:** Media player controls via MPRIS

```toml
[[block]]
block = "music"
format = "$icon {$combo.str(max_w:25,rot_interval:0.5) $play|}"
[[block.click]]
button = "left"
action = "play_pause"
[[block.click]]
button = "right"
action = "next"
[[block.click]]
button = "middle"
action = "prev"
```

**Features:**
- Rotating text for long song titles (25 char max)
- Auto-rotates every 0.5 seconds
- Full playback controls:
  - Left: Play/Pause
  - Right: Next track
  - Middle: Previous track

**Compatible Players:** Spotify, VLC, mpd (via mpDris2), and any MPRIS-compatible player

---

### 13. Power Mode Block
**Purpose:** CPU power management toggle

```toml
[[block]]
block = "custom"
command = "cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor | sed -e 's/performance/⚡ Perf/' -e 's/powersave/🌱 Save/'"
interval = "once"
signal = 12
format = "$text"
[[block.click]]
button = "left"
cmd = "~/.config/i3/scripts/power-control.sh performance && pkill -RTMIN+12 i3status-rs"
[[block.click]]
button = "right"
cmd = "~/.config/i3/scripts/power-control.sh powersave && pkill -RTMIN+12 i3status-rs"
[[block.click]]
button = "middle"
cmd = "~/.config/i3/scripts/power-control.sh reset && pkill -RTMIN+12 i3status-rs"
```

**Modes:**
- ⚡ **Performance**: Max CPU speed (left-click)
- 🌱 **Powersave**: Energy efficient (right-click)
- 🤖 **Auto**: System managed (middle-click)

**Dependencies:** `auto-cpufreq`, `tlp`, polkit rules for passwordless execution

---

### 14. Battery Block
**Purpose:** Battery status and remaining time

```toml
[[block]]
block = "battery"
format = "$icon $percentage {$time|} {$power|}"
interval = 5
warning = 30
critical = 15
```

**Displayed Values:**
- Battery icon (dynamic based on level/charging)
- Percentage
- Remaining time
- Power draw (watts)

**Thresholds:**
- Warning: 30%
- Critical: 15%

---

### 15. Temperature Block
**Purpose:** CPU temperature monitoring

```toml
[[block]]
block = "temperature"
format = "<span size='large'></span><span rise='1000'> $average</span>"
interval = 5
chip = "*-isa-*"
```

**Features:**
- Shows average CPU temperature
- Wildcard chip selection for compatibility

---

### 16. Redshift Block
**Purpose:** Blue light filter toggle

```toml
[[block]]
block = "custom"
command = "~/.config/i3/scripts/redshift-status.sh"
signal = 10
interval = "once"
format = "<span size='large'>$text</span>"
[[block.click]]
button = "left"
cmd = "~/.config/i3/scripts/toggle-redshift.sh"
```

**States:**
- 󰌵 (lightbulb): Redshift ON (warm: 3500K)
- (outline): Redshift OFF

**Script Features:**
- Uses `redshift -O 3500K` for warm color
- State persisted in `~/.cache/toggle-redshift.state`
- Instant update via SIGRTMIN+10

---

### 17. Picom Toggle Block
**Purpose:** Compositor toggle for performance

```toml
[[block]]
block = "custom"
command = "pgrep -x picom >/dev/null && echo '' || echo ''"
format = "<span size='large'>$text</span>"
interval = "once"
signal = 13
[[block.click]]
button = "left"
cmd = "~/.config/i3/scripts/picom-toggle.sh && pkill -RTMIN+13 i3status-rs"
```

**States:**
-  (filled): Picom running (effects on)
-  (outline): Picom stopped (performance mode)

**Use Case:** Disable compositor for gaming or resource-intensive tasks

---

### 18. Background Wallpaper Block
**Purpose:** Random wallpaper changer

```toml
[[block]]
block = "custom"
command = "echo ''"
format = "<span size='large'>$text</span>"
[[block.click]]
button = "left"
cmd = "~/.config/i3/scripts/bg.sh"
```

**Script Features:**
- Selects random wallpaper from `~/Pictures/wallpapers`
- Supports: X11 (xwallpaper), Wayland (swaymsg), fallback (feh)
- Integrates with `pywal` for color scheme generation
- Desktop notification with wallpaper preview

---

### 19. VPN Status Block
**Purpose:** Cloudflare WARP VPN status

```toml
[[block]]
block = "custom"
command = """
    if warp-cli status 2>/dev/null | grep -qi 'connected'; then
        echo ''
    else
        echo ''
    fi
"""
format = "<span size='x-large'>$text</span>"
interval = 5
[[block.click]]
button = "left"
cmd = "kitty -e zsh -ic warp"
```

**States:**
-  (globe filled): Connected
-  (globe outline): Disconnected

**Click Action:** Opens terminal with warp management command

---

### 20. Daily Notes Block
**Purpose:** Quick note-taking shortcuts

```toml
[[block]]
block = "custom"
command = "echo ''"
format = "<span size='large'>$text </span>"
[[block.click]]
button = "left"
cmd = "mkdir -p ~/notes/10_daily/$(date +'%Y') && (tmux select-window -t scratchpad:notes 2>/dev/null && tmux send-keys -t scratchpad:notes Escape \":e ~/notes/10_daily/$(date +'%Y')/$(date +'%Y-%m-%d').md\" C-m || tmux new-window -t scratchpad -n notes \"nvim ~/notes/10_daily/$(date +'%Y')/$(date +'%Y-%m-%d').md\"); i3-msg scratchpad show"
[[block.click]]
button = "right"
cmd = "mkdir -p ~/notes/20_work/reference && (tmux select-window -t scratchpad:notes 2>/dev/null && tmux send-keys -t scratchpad:notes Escape \":e ~/notes/20_work/reference/\" || tmux new-window -t scratchpad -n notes \"nvim ~/notes/20_work/reference/\") && i3-msg scratchpad show"
[[block.click]]
button = "middle"
cmd = "(tmux select-window -t scratchpad:notes 2>/dev/null && tmux send-keys -t scratchpad:notes Escape Space n s && i3-msg scratchpad show) || (tmux new-window -t scratchpad -n notes \"nvim -c 'normal \\<Space>ns'\" && i3-msg scratchpad show)"
```

**Click Actions:**
- **Left**: Opens daily note (`~/notes/10_daily/YYYY/YYYY-MM-DD.md`)
- **Right**: Opens work reference folder
- **Middle**: Opens nvim note search (Space+n+s)

---

## Helper Scripts

### `timer_control.sh`
**Location:** `~/.config/i3/scripts/timer_control.sh`

**Description:** Stopwatch with pause/resume functionality

**Usage:**
```bash
timer_control.sh toggle  # Start/pause
timer_control.sh reset   # Reset to 00:00
timer_control.sh read    # Output JSON for status bar
```

**State File:** `/tmp/i3_timer.state`

---

### `toggle-redshift.sh`
**Location:** `~/.config/i3/scripts/toggle-redshift.sh`

**Description:** Toggle blue light filter

**Features:**
- Fixed 3500K color temperature
- Persistent state across reboots
- Automatic signal to i3status-rs

---

### `power-control.sh`
**Location:** `~/.config/i3/scripts/power-control.sh`

**Description:** CPU power management via auto-cpufreq and TLP

**Modes:**
- `performance`: Maximum performance
- `powersave`: Energy saving
- `reset`: Automatic management

---

### `bg.sh`
**Location:** `~/.config/i3/scripts/bg.sh`

**Description:** Random wallpaper setter with pywal integration

---

### `picom-toggle.sh`
**Location:** `~/.config/i3/scripts/picom-toggle.sh`

**Description:** Toggle compositor for performance

---

### `redshift-status.sh`
**Location:** `~/.config/i3/scripts/redshift-status.sh`

**Description:** Returns icon based on redshift state

---

## Dependencies

### Required Packages
| Package | Purpose |
|---------|---------|
| `i3status-rust` | Status bar |
| `pulseaudio` / `pipewire` | Audio control |
| `brightnessctl` | Backlight control |
| `lm_sensors` | Temperature monitoring |

### Optional Packages
| Package | Purpose |
|---------|---------|
| `timewarrior` | Time tracking |
| `taskwarrior` + `vit` | Task management |
| `calcurse` | Calendar |
| `btop` / `htop` | System monitoring |
| `pavucontrol` | Audio mixer |
| `peaclock` | Terminal clock |
| `auto-cpufreq` + `tlp` | Power management |
| `redshift` | Blue light filter |
| `picom` | Compositor |
| `warp-cli` | Cloudflare VPN |
| `pywal` | Color scheme generator |

### Fonts
- **JetBrainsMono Nerd Font** (or any Nerd Font) for icons

---

## Key Bindings

These are i3 keybindings that interact with the status bar:

| Keybinding | Action |
|------------|--------|
| `$mod+m` | Toggle bar visibility |
| `$mod+F12` | Toggle redshift |

---

## Signals Reference

The configuration uses POSIX real-time signals for instant updates:

| Signal | Block |
|--------|-------|
| `RTMIN+10` | Redshift |
| `RTMIN+11` | Timer |
| `RTMIN+12` | Power Mode |
| `RTMIN+13` | Picom |

**Send Signal:**
```bash
pkill -RTMIN+10 i3status-rs  # Update redshift block
```

---

## File Structure

```
~/.config/
├── i3status-rust/
│   └── config.toml          # Main configuration
└── i3/
    └── scripts/
        ├── timer_control.sh
        ├── toggle-redshift.sh
        ├── redshift-status.sh
        ├── power-control.sh
        ├── picom-toggle.sh
        └── bg.sh
```

---

## Author Notes

This configuration emphasizes:
1. **Minimal visual footprint** with transparent backgrounds
2. **Maximum functionality** with click actions on every block
3. **Scratchpad integration** via tmux for quick tool access
4. **Real-time updates** using signals instead of polling
5. **Consistent Gruvbox theming** throughout

---

*Last Updated: January 2025*
