# i3 Window Manager Configuration

A comprehensive, modular i3 configuration designed for productivity, featuring dynamic workspace naming, hardware-accelerated screen recording, and a fully integrated status bar with i3status-rust.

## Table of Contents

- [Overview](#overview)
- [Dependencies](#dependencies)
- [File Structure](#file-structure)
- [Key Bindings](#key-bindings)
  - [Core Navigation](#core-navigation)
  - [Window Management](#window-management)
  - [Workspace Management](#workspace-management)
  - [Application Launcher Mode](#application-launcher-mode)
  - [Neovim/Editor Mode](#nevimeditor-mode)
  - [Copy/Clipboard Mode](#copyclipboard-mode)
  - [Package Manager Mode](#package-manager-mode)
  - [Resize Mode](#resize-mode)
  - [Media Controls](#media-controls)
  - [Screenshot & Recording](#screenshot--recording)
  - [System Controls](#system-controls)
- [Configuration Modules](#configuration-modules)
- [Scripts Documentation](#scripts-documentation)
- [Status Bar Configuration](#status-bar-configuration)
- [Theme and Colors](#theme-and-colors)
- [Startup Applications](#startup-applications)
- [Recommendations for Improvement](#recommendations-for-improvement)

---

## Overview

This i3 configuration follows a modular design pattern, with the main configuration split across multiple files in the `config.d/` directory. Key features include:

- **Modular Configuration**: Split into logical modules (apps, audio, camera, clipboard, etc.)
- **Dynamic Workspace Names**: Automatically renames workspaces based on focused application with icons
- **Alternating Layouts**: Automatic split direction based on window dimensions (Spiraling/Fibonacci-like tiling)
- **Hardware-Accelerated Recording**: VAAPI-powered screen recording with minimal CPU impact
- **Vim-Style Navigation**: `h/j/k/l` keys for movement
- **Modal Keybindings**: Multiple modes for different tasks (app launcher, editor, clipboard, package manager)
- **Gruvbox/Catppuccin Hybrid Theme**: A carefully crafted color scheme combining both palettes

**Modifier Key**: `Mod4` (Super/Windows key)

---

## Dependencies

### Required Dependencies

| Package | Purpose |
|---------|---------|
| `i3-wm` / `i3-gaps` | Window manager (gaps support recommended) |
| `i3status-rust` | Status bar |
| `kitty` | Terminal emulator |
| `dmenu` | Application launcher |
| `picom` | Compositor (transparency, blur, animations) |
| `dunst` | Notification daemon |
| `xwallpaper` | Wallpaper setter |
| `maim` | Screenshot utility |
| `xdotool` | X11 automation |
| `xclip` | Clipboard management |
| `ffmpeg` | Screen recording |
| `pactl` / PipeWire / PulseAudio | Audio control |
| `brightnessctl` | Backlight control |
| `unclutter` | Auto-hide mouse cursor |
| `i3lock` | Screen locker |
| `xss-lock` | Automatic locking |
| `nm-applet` | NetworkManager system tray |
| `blueman-applet` | Bluetooth system tray |
| `udiskie` | Automount removable media |
| `clipmenud` / `clipmenu` | Clipboard manager |
| `python-i3ipc` | Python library for i3 IPC |

### Optional Dependencies

| Package | Purpose |
|---------|---------|
| `aw-qt` | ActivityWatch time tracker |
| `polkit-gnome` | PolicyKit authentication agent |
| `redshift` | Blue light filter |
| `slop` | Region selection for recording |
| `pywal` | Color scheme generator |
| `feh` | Alternative wallpaper setter |
| `mpc` / `mpd` | Music Player Daemon control |
| `tmux` | Terminal multiplexer (for scratchpad sessions) |

### Dependency Validation

The configuration includes automatic dependency checking at startup:

```bash
exec --no-startup-id bash -c 'missing=""; for cmd in xdotool ffmpeg pactl xwallpaper; do command -v $cmd >/dev/null || missing="$missing $cmd"; done; [ -n "$missing" ] && notify-send -u critical "Missing Dependencies" "Install:$missing" || true'
```

---

## File Structure

```
i3/
├── config              # Main configuration file
├── config.d/           # Modular configuration files
│   ├── apps.conf       # Application-specific rules and launcher mode
│   ├── audio.conf      # Volume and audio controls
│   ├── backlight.conf  # Brightness controls
│   ├── binds.conf      # Keyboard remapping
│   ├── camera.conf     # Webcam PiP window
│   ├── clipboard.conf  # Clipboard management mode
│   ├── editor.conf     # Neovim/editor launcher mode
│   ├── gamma.conf      # Redshift/color temperature
│   ├── media.conf      # MPD/music controls
│   ├── pkg.conf        # Package manager mode
│   ├── scratchpad.conf # Scratchpad configuration
│   ├── shots.conf      # Screenshot bindings
│   └── theme.conf      # Window colors and decorations
├── scripts/            # Helper scripts
│   ├── alternating_layouts.py
│   ├── bg.sh
│   ├── picom-toggle.sh
│   ├── power-control.sh
│   ├── record.sh
│   ├── record-with-mic.sh
│   ├── record-window-mic.sh
│   ├── redshift-status.sh
│   ├── secure-passmenu.sh
│   ├── start-polkit-agent.sh
│   ├── timer_control.sh
│   ├── toggle-redshift.sh
│   └── workspace-names.py
└── README.md           # This documentation
```

---

## Key Bindings

### Core Navigation

| Keybinding | Action |
|------------|--------|
| `$mod+h` | Focus left |
| `$mod+j` | Focus down |
| `$mod+k` | Focus up |
| `$mod+l` | Focus right |
| `$mod+a` | Focus parent container |
| `$mod+space` | Toggle focus between tiling/floating |

### Window Management

| Keybinding | Action |
|------------|--------|
| `$mod+Return` | Open terminal (kitty) |
| `$mod+Ctrl+Return` | Open terminal with tmux attach |
| `$mod+Shift+Return` | Open terminal in same directory |
| `$mod+Shift+q` | Kill focused window |
| `$mod+d` | Open dmenu launcher |
| `$mod+f` | Toggle fullscreen |
| `$mod+Shift+space` | Toggle floating |
| `$mod+Shift+h/j/k/l` | Move focused window |
| `$mod+s` | Stacking layout |
| `$mod+w` | Tabbed layout |
| `$mod+e` | Toggle split |

### Workspace Management

| Keybinding | Action |
|------------|--------|
| `$mod+1-0` | Switch to workspace 1-10 |
| `$mod+Shift+1-0` | Move container to workspace 1-10 |
| `$mod+m` | Toggle bar visibility |

### Application Launcher Mode (`$mod+o`)

Enter mode with `$mod+o`, then:

| Key | Application |
|-----|-------------|
| `f` | Firefox |
| `c` | VS Code |
| `g` | Google Chrome (Profile 1) |
| `Shift+g` | Google Chrome (Profile 5) |
| `t` | Thunar file manager |
| `m` | rmpc (MPD client in tmux) |
| `y` | Yazi file manager |
| `n` | nvtop (GPU monitor) |
| `b` | bc calculator |
| `o` | OBS Studio |
| `p` | PulseAudio volume control |
| `v` | VLC |
| `Shift+v` | mpv |
| `Shift+t` | Telegram |
| `z` | Zathura PDF viewer |
| `i` | GIMP |
| `x` | VirtualBox |
| `Escape/Return` | Exit mode |

### Neovim/Editor Mode (`$mod+n`)

Enter mode with `$mod+n`, then:

| Key | Action |
|-----|--------|
| `l` | Open leetcode.nvim |
| `w` | Open ~/work/ in nvim |
| `c` | Open config in nvim |
| `n` | Open notes in nvim |
| `t` | Open vit (taskwarrior TUI) |
| `d` | Open calcurse |
| `Escape/Return` | Exit mode |

### Copy/Clipboard Mode (`$mod+c`)

Enter mode with `$mod+c`, then:

| Key | Action |
|-----|--------|
| `x` | Password manager (pass with dmenu) |
| `b` | Character picker |
| `c` | Clipboard menu |
| `Escape/Return` | Exit mode |

### Package Manager Mode (`$mod+p`)

Enter mode with `$mod+p`, then:

| Key | Action |
|-----|--------|
| `p` | Install with pacman (fzf) |
| `y` | Install with yay (AUR) |
| `d` | Remove with yay |
| `Escape/Return` | Exit mode |

### Resize Mode (`$mod+r`)

Enter mode with `$mod+r`, then:

| Key | Action |
|-----|--------|
| `h` / `Left` | Shrink width |
| `l` / `Right` | Grow width |
| `j` / `Down` | Shrink height |
| `k` / `Up` | Grow height |
| `Escape/Return` | Exit mode |

### Media Controls

| Keybinding | Action |
|------------|--------|
| `$mod+Alt+/` | Next track (mpc) |
| `$mod+Alt+,` | Previous track (mpc) |
| `$mod+Alt+.` | Toggle play/pause (mpc) |
| `$mod+Alt+Left` | Seek -5 seconds |
| `$mod+Alt+Right` | Seek +5 seconds |
| `XF86AudioNext` | Next track |
| `XF86AudioPrev` | Previous track |
| `XF86AudioPause` | Toggle play/pause |

### Audio Controls

| Keybinding | Action |
|------------|--------|
| `XF86AudioRaiseVolume` | Increase volume 5% |
| `XF86AudioLowerVolume` | Decrease volume 5% |
| `XF86AudioMute` | Toggle mute |
| `XF86AudioMicMute` | Toggle microphone mute |
| `$mod+F4` | Toggle microphone mute |

### Brightness Controls

| Keybinding | Action |
|------------|--------|
| `XF86MonBrightnessUp` | Increase brightness 5% |
| `XF86MonBrightnessDown` | Decrease brightness 5% |

### Screenshot & Recording

| Keybinding | Action |
|------------|--------|
| `Print` | Full screen screenshot (save to file) |
| `$mod+Print` | Active window screenshot |
| `Shift+Print` | Select area screenshot |
| `Ctrl+Print` | Full screen to clipboard |
| `Ctrl+$mod+Print` | Active window to clipboard |
| `Ctrl+Shift+Print` | Select area to clipboard |
| `$mod+Shift+Print` | Toggle screen recording |
| `$mod+Ctrl+Shift+Print` | Toggle recording with mic |
| `$mod+Shift+w` | Window selection recording with mic |

### System Controls

| Keybinding | Action |
|------------|--------|
| `$mod+Shift+c` | Reload i3 config |
| `$mod+Shift+r` | Restart i3 in place |
| `$mod+Shift+e` | Exit i3 (clean logout) |
| `$mod+Shift+s` | Shutdown system |
| `$mod+Shift+n` | Click latest notification |
| `$mod+Shift+F10` | Webcam PiP window |
| `$mod+F12` | Toggle redshift |

### Gaps Controls

| Keybinding | Action |
|------------|--------|
| `$mod+Shift++` | Increase inner gaps by 5 |
| `$mod+Shift+-` | Decrease inner gaps by 5 |

---

## Configuration Modules

### apps.conf
Application-specific window rules and the application launcher mode. Includes:
- Floating rules for blueman-manager, pavucontrol
- Sticky window support for calculator
- Comprehensive application launcher mode (`$mod+o`)

### audio.conf
Audio controls using PipeWire/wpctl and PulseAudio/pactl for volume management.

### backlight.conf
Display brightness controls using brightnessctl.

### binds.conf
Keyboard remapping at startup:
- Caps Lock → Escape
- Menu key → Super_L

### camera.conf
Webcam Picture-in-Picture configuration using mpv with low-latency profile and horizontal flip.

### clipboard.conf
Clipboard management mode with:
- Password manager integration (pass + dmenu)
- Character picker
- Clipboard history (clipmenu)

### editor.conf
Editor/development launcher mode for quick access to:
- Leetcode in neovim
- Work directory
- Config files
- Notes
- Task management (vit/taskwarrior)
- Calendar (calcurse)

### gamma.conf
Redshift color temperature toggle binding.

### media.conf
MPD (Music Player Daemon) controls using mpc client.

### pkg.conf
Package manager mode for Arch Linux using pacman and yay with fzf integration.

### scratchpad.conf
Scratchpad configuration with tmux session for quick terminal access. Bound to `` $mod+` ``.

### shots.conf
Comprehensive screenshot bindings using maim:
- Full screen, active window, selection
- Save to file or clipboard
- Window selection recording with mic

### theme.conf
Window decoration colors using a Gruvbox-Catppuccin hybrid theme.

---

## Scripts Documentation

### alternating_layouts.py
Automatically switches between horizontal and vertical splits based on window dimensions, creating a spiral/Fibonacci-like tiling effect. Uses i3ipc Python library.

**Features:**
- Listens to window focus events
- Respects tabbed/stacked layouts
- Optimal for varying window sizes

### bg.sh
Random wallpaper setter with support for:
- X11 (xwallpaper) and Wayland (swaymsg)
- Fallback to feh
- Optional pywal integration for automatic color schemes
- Desktop notification with wallpaper name

### picom-toggle.sh
Toggles the picom compositor on/off. Useful for troubleshooting or reducing resource usage.

### power-control.sh
CPU power management wrapper for:
- **performance**: Maximum performance mode
- **powersave**: Battery-saving mode
- **reset**: Return to automatic management

Uses auto-cpufreq and TLP with polkit for privilege escalation.

### record.sh
Screen recording with system audio:
- Hardware-accelerated when available
- Automatic resolution detection
- Toggle functionality
- PID file management for safe start/stop
- Saves to `~/Videos/recordings/`

### record-with-mic.sh
Screen recording with both system audio and microphone:
- VAAPI hardware acceleration (Intel QuickSync)
- 60 FPS capture
- Audio mixing (system + mic)
- Saves to `~/Videos/recordings/`

### record-window-mic.sh
Window/region selection recording:
- Uses slop for region selection
- Hardware-accelerated encoding
- System audio + microphone mixing
- Even dimension handling for encoder compatibility

### redshift-status.sh
Returns redshift status for i3status-rust custom block. Uses exit codes for state indication.

### secure-passmenu.sh
Secure password menu that temporarily disables clipboard monitoring:
1. Disables clipmenud
2. Runs passmenu
3. Re-enables clipmenud

Prevents passwords from being stored in clipboard history.

### start-polkit-agent.sh
Starts the PolicyKit authentication agent with:
- Event-driven DBUS socket wait (inotifywait)
- Duplicate agent detection
- Proper daemonization

### timer_control.sh
Simple stopwatch/timer for i3status-rust:
- **toggle**: Start/pause timer
- **reset**: Reset to zero
- **read**: Output JSON for status bar

Supports running/paused states with persistent state file.

### toggle-redshift.sh
Toggles redshift between off and 3500K color temperature. Signals i3status-rs for immediate bar update.

### workspace-names.py
Dynamic workspace naming script that:
- Detects focused application class/instance
- Maps to Nerd Font icons with Gruvbox colors
- Automatically renames workspaces
- Supports 70+ applications with custom icons

---

## Status Bar Configuration

The status bar uses **i3status-rust** with a customized gruvbox-dark theme. Located at `~/.config/i3status-rust/config.toml`.

### Blocks (left to right):

1. **TimeWarrior Task** - Active task timer
2. **Date** - Current date with calendar click
3. **Time** - Current time with peaclock click
4. **Focused Window** - Current window title (max 30 chars)
5. **Uptime** - System uptime
6. **CPU** - Utilization and frequency
7. **Memory** - RAM usage percentage
8. **Volume** - Speaker volume with mute toggle
9. **Microphone** - Mic volume with mute toggle
10. **Backlight** - Screen brightness
11. **Timer** - Custom stopwatch
12. **Music** - Current playing track (MPD)
13. **Power Mode** - CPU governor status
14. **Battery** - Battery percentage and time
15. **Temperature** - CPU temperature
16. **Redshift** - Color temperature status
17. **Picom** - Compositor status
18. **Background** - Wallpaper changer
19. **VPN** - Cloudflare WARP status
20. **Daily Notes** - Quick note access

### Theme Colors (Gruvbox-Dark)
- Background: Transparent
- Idle: `#ebdbb2`
- Info: `#83a598` (blue)
- Good: `#b8bb26` (green)
- Warning: `#fabd2f` (yellow)
- Critical: `#fb4934` (red)

---

## Theme and Colors

### Color Variables
```
$blue      #89b4fa   (Catppuccin)
$surface0  #313244   (Catppuccin)
$text      #cdd6f4   (Catppuccin)
$surface1  #45475a   (Catppuccin)
$mantle    #181825   (Catppuccin)
$subtext1  #bac2de   (Catppuccin)
$base      #1e1e2e   (Catppuccin)
$overlay1  #7f849c   (Catppuccin)
$maroon    #eba0ac   (Catppuccin)
$red       #fb4934   (Gruvbox)
$green     #b8bb26   (Gruvbox)
$yellow    #fabd2f   (Gruvbox)
```

### Window Decorations
- **Focused**: Yellow indicator, transparent border
- **Focused Inactive**: Gray border
- **Unfocused**: Dark border
- **Urgent**: Red highlight

### Bar Colors
- **Focused workspace**: Blue text on dark background
- **Active workspace**: Light gray text
- **Inactive workspace**: Gray text
- **Urgent workspace**: Red/maroon highlight

---

## Startup Applications

The following applications are started when i3 launches:

| Application | Purpose |
|-------------|---------|
| `unclutter` | Auto-hide mouse cursor after 1 second of inactivity |
| `xss-lock` | Automatic screen locking |
| `nm-applet` | NetworkManager system tray icon |
| `blueman-applet` | Bluetooth system tray icon |
| `dunst` | Notification daemon |
| `clipmenud` | Clipboard manager daemon |
| `udiskie` | Auto-mount USB drives |
| `aw-qt` | ActivityWatch time tracker |
| `polkit-gnome` | PolicyKit authentication agent |
| `bg.sh` | Set random wallpaper |
| `picom` | Compositor (runs with `exec_always`) |
| `workspace-names.py` | Dynamic workspace naming |
| `alternating_layouts.py` | Auto split direction |
| `setxkbmap` | Caps:Escape swap, Menu→Win |
| Touchpad settings | Tap-to-click enabled |

---

## Recommendations for Improvement

### High Priority

1. **Add `i3-gaps` specific features** (if using i3-gaps)
   - Smart gaps: `smart_gaps on` - Remove gaps when only one window
   - Smart borders: `smart_borders on` - Hide borders on single window
   ```
   smart_gaps on
   smart_borders on
   ```

2. **Improve screen locking**
   - Use `betterlockscreen` or `i3lock-color` for a more aesthetic lock screen
   - Add blur effect to lock screen
   ```bash
   exec --no-startup-id xss-lock --transfer-sleep-lock -- betterlockscreen -l blur
   ```

3. **Add focus follows mouse option**
   ```
   focus_follows_mouse no  # Consider disabling if you find it annoying
   ```

4. **Add urgent workspace indicator**
   ```
   for_window [urgent=latest] focus  # Auto-focus urgent windows
   ```

### Medium Priority

5. **Add window marks for quick jumping**
   ```
   bindsym $mod+Shift+m mark --toggle "quickmark"
   bindsym $mod+apostrophe [con_mark="quickmark"] focus
   ```

6. **Implement workspace assignments for specific applications**
   ```
   assign [class="Firefox"] $ws1
   assign [class="code"] $ws2
   assign [class="discord"] $ws9
   ```

7. **Add floating window rules for dialogs**
   ```
   for_window [window_role="pop-up"] floating enable
   for_window [window_role="task_dialog"] floating enable
   for_window [window_type="dialog"] floating enable
   ```

8. **Improve scratchpad with multiple named scratchpads**
   ```
   # Named scratchpads
   for_window [instance="dropdown_terminal"] move scratchpad
   for_window [instance="dropdown_calc"] move scratchpad
   ```

### Low Priority

9. **Add monitor management bindings**
   ```
   bindsym $mod+Shift+m exec --no-startup-id autorandr --change
   bindsym $mod+Ctrl+m exec --no-startup-id arandr
   ```

10. **Consider using rofi instead of dmenu**
    - Better theming support
    - Window switcher mode
    - Calculator mode
    ```
    bindsym $mod+d exec --no-startup-id rofi -show drun
    bindsym $mod+Tab exec --no-startup-id rofi -show window
    ```

11. **Add notification management bindings**
    ```
    bindsym $mod+minus exec --no-startup-id dunstctl close
    bindsym $mod+equal exec --no-startup-id dunstctl history-pop
    ```

12. **Add keyboard layout switching**
    ```
    bindsym $mod+F1 exec --no-startup-id setxkbmap -layout us
    bindsym $mod+F2 exec --no-startup-id setxkbmap -layout de
    ```

### Performance Improvements

13. **Lazy-load startup applications**
    - Use systemd user services for better startup management
    - Implement delayed startup for non-critical applications

14. **Consider using sway for Wayland**
    - Better performance on modern hardware
    - Native Wayland support
    - Similar configuration syntax

### Security Improvements

15. **Add screen dimming before lock**
    ```bash
    exec --no-startup-id xset s 300 5
    exec --no-startup-id xss-lock -n /usr/lib/xsecurelock/dimmer -l -- xsecurelock
    ```

16. **Implement clipboard clearing**
    - Auto-clear clipboard after a timeout for sensitive data
    - Consider `greenclip` as an alternative to clipmenu

### Documentation Improvements

17. **Add keybinding cheatsheet wallpaper**
    - Create a visual keybinding reference
    - Toggle display with a keybinding

18. **Create backup/restore scripts**
    - Script to backup/restore i3 configuration
    - Version control integration

---

## Troubleshooting

### Common Issues

**Q: Gaps not working?**
A: Ensure you're using `i3-gaps` not vanilla `i3-wm`.

**Q: Workspace names not updating?**
A: Check if `workspace-names.py` is running: `pgrep -f workspace-names.py`

**Q: Screen recording fails?**
A: Check ffmpeg is installed and VAAPI is available: `vainfo`

**Q: Picom causing issues?**
A: Toggle with `$mod+o` then `p` or run `~/.config/i3/scripts/picom-toggle.sh`

**Q: Status bar not showing?**
A: Ensure `i3status-rs` is installed and config.toml path is correct.

---

## Credits

- [i3 Window Manager](https://i3wm.org/)
- [i3status-rust](https://github.com/greshake/i3status-rust)
- [Gruvbox Theme](https://github.com/morhetz/gruvbox)
- [Catppuccin Theme](https://github.com/catppuccin/catppuccin)
- [Nerd Fonts](https://www.nerdfonts.com/)

---

*This documentation was generated from configuration analysis. Last updated: 2026-01-31*
