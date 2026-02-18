# kb-rgb — Deep Technical Reference

**Script:** `bin/kb-rgb`  
**Hardware:** Tongfang/Clevo P15 Gen 23 (single-zone keyboard backlight)  
**Author:** Dotfiles @ `~/work/config`

---

## Table of Contents

1. [Hardware Layer — How the keyboard actually works](#1-hardware-layer)
2. [Security Model — Why root-owned](#2-security-model)
3. [Architecture — Layers of the system](#3-architecture)
4. [State Machine — How state is persisted](#4-state-machine)
5. [Effect Engine — Background process management](#5-effect-engine)
6. [Notification Glow — dunst integration](#6-notification-glow)
7. [Preset System — Color palettes](#7-preset-system)
8. [i3 Integration — Keybindings & modes](#8-i3-integration)
9. [Setup & Recovery — Installation across machines](#9-setup--recovery)
10. [Full Command Reference](#10-full-command-reference)
11. [Troubleshooting](#11-troubleshooting)

---

## 1. Hardware Layer

### The ACPI Call Interface

This keyboard has no native userspace API. The only way to control it is through the **ACPI WMI (Windows Management Instrumentation) bridge** exposed by the Tongfang/Clevo firmware.

The kernel module `acpi_call-dkms` exposes a file:

```
/proc/acpi/call
```

Writing a specially formatted string to this file triggers a BIOS/EC (Embedded Controller) method.

### WMI Method

```
\_SB_.WMI_.WMBB   (namespace path in the ACPI table)
   |
   ├─ Instance: 0
   ├─ Method ID: 0x67  (keyboard backlight control)
   └─ Data: 4-byte payload
```

### Wire Protocol — Color

The EC expects a 4-byte payload for color:

```
0xF0  BB  RR  GG
^^^^^^ ^^  ^^  ^^
 cmd  Blue Red Green
```

**Critical:** The byte order is **BRG**, NOT RGB. Most documentation assumes RGB. Getting this wrong silently writes a wrong color (e.g., requesting red produces blue).

Example — Set color to Gruvbox Red (`#ea6962`):
- R = `0xEA`, G = `0x69`, B = `0x62`
- Payload = `0xF0_62_EA_69`

The script builds this with:
```bash
wmi_write "$(printf '0xF0%s%s%s' "$b" "$r" "$g")"
#                           ^^   ^^   ^^
#                         Blue  Red  Green
```

### Wire Protocol — Brightness

```
0xF4  00  00  XX
               ^^
               brightness value: 0x00–0xC8 (0–200 decimal)
               maps to 0–100% (multiply user value by 2)
```

Example — Set brightness to 50%:
- User value: 50
- XX = 50 × 2 = 100 = `0x64`
- Payload = `0xF4000064`

The script:
```bash
wmi_write "$(printf '0xF40000%02X' $(( val * 2 )))"
```

### EC Settle Time

The embedded controller needs **at least 30ms** between successive WMI writes. Writing faster causes glitches (partial colors, brightness flickering). The script enforces this with:

```bash
readonly EC_SETTLE=0.035   # 35ms — 5ms headroom over minimum
```

Every effect loop uses `sleep "$EC_SETTLE"` as a minimum delay floor enforced in `speed_to_delay()`.

---

## 2. Security Model

### Why This Script Runs as Root

The script performs two privileged operations:
1. **Writes to `/proc/acpi/call`** — requires root (kernel interface)
2. **Is called by dunst** (notification daemon) via `sudo` without a password

### The NOPASSWD Attack Surface

A file allowed via `NOPASSWD` in `/etc/sudoers` creates a **privilege escalation path**. If a non-root attacker can modify that file, they can inject any code and have it run as root.

**Mitigation: root:root 0755 ownership**

| Property | Value | Meaning |
|----------|-------|---------|
| Owner | `root:root` | Only root can write |
| Mode | `0755` | Everyone can read and execute |

With this in place:
- A non-root attacker **cannot modify** `bin/kb-rgb`
- Therefore they **cannot inject** code into the NOPASSWD path
- The privilege escalation path is **locked down**

This mirrors the exact same model used by system binaries like `/usr/bin/sudo` itself.

### Self-Escalation Pattern

Unlike `warp` (which uses `realpath + exec sudo`), `kb-rgb` uses a simpler pattern because it has a direct hardware check:

```bash
[[ -w "$ACPI_CALL" ]] || {
    (( EUID != 0 )) && exec sudo "$0" "$@"
}
```

Logic:
1. If `/proc/acpi/call` is writable → already root (or kernel gave write perms) → proceed
2. If not writable AND not root → re-exec as root via `sudo`

The `$0` here is safe because `kb-rgb` is root-owned — an attacker cannot replace `$0` with a malicious script.

### Sudoers Entry

```
kali ALL=(ALL) NOPASSWD: /home/kali/work/config/bin/kb-rgb
```

The path **must be the canonical realpath** — not a symlink. If you call `sudo ~/.local/bin/kb-rgb`, sudo resolves the symlink chain and checks the canonical path against the rule. Both must match.

This is why `restore-dotfiles.sh` and `update-paths.sh` use `realpath` to generate the rule dynamically based on the actual clone location.

---

## 3. Architecture

The script is organized into strict layers. Each layer only calls downward:

```
┌──────────────────────────────────────────────────────┐
│  COMMAND DISPATCH  (case "$cmd")                     │  ← User entry point
├──────────────────────────────────────────────────────┤
│  HIGH-LEVEL API                                      │
│  apply()  apply_preset()  do_cycle()  do_fade()      │  ← Combines color + brightness + state
├──────────────────────────────────────────────────────┤
│  EFFECT ENGINE                                       │
│  fx_breathe() fx_wave() fx_strobe() fx_candle()      │  ← Background subprocess management
│  fx_police()  fx_disco() fx_heartbeat() fx_pulse()   │
├──────────────────────────────────────────────────────┤
│  NOTIFICATION GLOW                                   │
│  glow_flash()  glow_toggle()  glow_test()            │  ← dunst integration
├──────────────────────────────────────────────────────┤
│  STATE LAYER                                         │
│  save_state()  load_state()  get_color()             │  ← ~/.local/state/kb-rgb/
├──────────────────────────────────────────────────────┤
│  HARDWARE LAYER                                      │
│  hw_set_color()  hw_set_brightness()  wmi_write()    │  ← /proc/acpi/call
└──────────────────────────────────────────────────────┘
```

### Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Single file | No install step; easy to symlink and version-control |
| No daemon | Effects use background subshells; no persistent process to manage |
| State in XDG_STATE | Survives reboots; follows freedesktop spec |
| Filelock on glow | Prevents concurrent WMI writes from dunst + user |
| Speed as integer 1–10 | Intuitive; converted to milliseconds by `speed_to_delay()` |

---

## 4. State Machine

### State Files

All state lives in `~/.local/state/kb-rgb/`:

| File | Content | Purpose |
|------|---------|---------|
| `state` | `RRGGBB\nBRIGHTNESS\n` | Last set color + brightness |
| `effect.pid` | PID integer | PID of running effect subshell |
| `effect.name` | String | Name of current effect (e.g., "breathe") |
| `glow_enabled` | `0` or `1` | Whether dunst glow is active |
| `cycle_index` | Integer | Position in `CYCLE_COLORS` array |
| `lock` | empty (flock target) | Prevents concurrent WMI access |

### State Persistence Flow

```
User runs: kb-rgb color ea6962
    │
    ▼
apply("ea6962", 100)
    │
    ├── hw_set_color("ea6962")      → writes to /proc/acpi/call
    ├── hw_set_brightness(100)      → writes to /proc/acpi/call
    └── save_state("ea6962", 100)   → writes to ~/.local/stattooe/kb-rgb/state
```

### Critical: `off` must save state

When you run `kb-rgb off`, brightness `0` **must** be persisted. If it isn't, the glow restore logic will read the old brightness (e.g., `100`) and turn the keyboard back on after a notification flash.

```bash
off|0) fx_stop 2>/dev/null; hw_set_brightness 0; save_state "$(get_color)" 0 ;;
#                                                             ^^^^^^^^^^^^^ ^^^
#                                                  color preserved, brightness zeroed
```

### SUDO_USER Resolution

When invoked as `sudo kb-rgb`, `$HOME` becomes root's home (`/root`). State must live in the **real user's** home, not root's.

```bash
readonly REAL_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
```

- If running as root via sudo: `$SUDO_USER` = `kali` → home = `/home/kali`
- If running as root directly: `$USER` = `root` → home = `/root`
- If running as user: `$USER` = `kali` → home = `/home/kali`

---

## 5. Effect Engine

### Design

Effects are **infinite loops running in a detached background subshell**. The script starts an effect and exits immediately — no blocking.

```
kb-rgb breathe
    │
    ├── fx_stop()           ← kill any running effect first
    ├── hw_set_color(...)   ← set color (synchronous, in parent)
    ├── ( while loop ) &    ← fork background subshell
    └── fx_register(pid)    ← write PID to state file
         exit 0             ← parent exits, KB keeps looping
```

### Effect PID Management

```bash
fx_register() {
    printf '%d' "$pid" > "$EFFECT_PID"
    printf '%s'  "$name" > "$EFFECT_NAME"
}

fx_stop() {
    pid=$(< "$EFFECT_PID")
    pkill -P "$pid"   # kill children first (nested sleeps)
    kill "$pid"       # kill the loop itself
    sleep "$EC_SETTLE"  # let EC settle before next write
    rm -f "$EFFECT_PID" "$EFFECT_NAME"
}
```

**Why kill children first?** Each iteration of a loop does `sleep X`. The `sleep` is a child process. If you kill the loop without killing `sleep` first, the orphaned `sleep` can continue and race against a new effect's writes to `/proc/acpi/call`.

### Speed → Delay Conversion

```bash
speed_to_delay() {
    local base_ms=$1 speed=${2:-5}
    awk "BEGIN {
        d = ($base_ms / 1000.0) * (10.0 / ($speed * 2.0))
        if (d < $EC_SETTLE) d = $EC_SETTLE
        printf \"%.3f\", d
    }"
}
```

The formula: `delay = (base_ms / 1000) × (10 / (speed × 2))`

| speed | factor | base=40ms | result |
|-------|--------|-----------|--------|
| 1 | 5.0× | 40ms | 200ms |
| 5 | 1.0× | 40ms | 40ms |
| 10 | 0.5× | 40ms | 20ms → clamped to 35ms |

The floor clamping to `EC_SETTLE` (35ms) prevents hardware glitches at maximum speed.

### Color Interpolation (for Wave/Fade)

```bash
fade_colors() {
    local from="$1" to="$2" steps="$3" delay="$4"
    # Decompose hexcolors into R/G/B integers
    fr=$((16#${from:0:2}))  fg=$((16#${from:2:2}))  fb=$((16#${from:4:2}))
    tr=$((16#${to:0:2}))    tg=$((16#${to:2:2}))    tb=$((16#${to:4:2}))

    for (( i = 0; i <= steps; i++ )); do
        cr=$(( fr + (tr - fr) * i / steps ))  # linear interpolation
        cg=$(( fg + (tg - fg) * i / steps ))
        cb=$(( fb + (tb - fb) * i / steps ))
        hw_set_color "$(printf '%02X%02X%02X' cr cg cb)"
        sleep "$delay"
    done
}
```

This is **linear interpolation in RGB space** — not perceptually uniform (that would require LAB colorspace), but visually acceptable for keyboard backlighting and avoids any external dependencies.

---

## 6. Notification Glow

### Event Chain

```
dunst receives notification
    │
    └── dunst script rule fires (from dunstrc)
            │
            └── dunst/scripts/kb-rgb-glow
                    │
                    ├── check $XDG_STATE_HOME/kb-rgb/glow_enabled == "1"
                    │   (early-exit if glow disabled, avoids sudo fork)
                    │
                    └── exec sudo /path/to/kb-rgb glow-flash URGENCY
                                │
                                └── glow_flash()
                                        │
                                        ├── acquire_lock()      ← prevent concurrent writes
                                        ├── SIGSTOP effect      ← pause any running effect
                                        ├── flash pattern       ← urgency-specific animation
                                        └── restore state       ← resume effect OR restore saved state
```

### Urgency Patterns

| Urgency | Color | Pattern | Duration |
|---------|-------|---------|----------|
| `low` | Gruvbox Aqua `#89b482` | Gentle fade up → hold → fade down | ~800ms |
| `normal` | Yellow→Orange | Pulse up to peak, fade out | ~900ms |
| `critical` | Gruvbox Red `#ea6962` | Triple double-flash | ~750ms |

**All patterns end at brightness `0`** before the restore step. This is critical for correct state restoration.

### SIGSTOP/SIGCONT for Effects

When a notification arrives during an active effect (e.g., breathing):

```
Effect subshell (RUNNING)
    │
    ├── SIGSTOP → suspend loop + all child sleep processes
    │
    ├── [flash animation runs here — owns the hardware]
    │
    └── SIGCONT → resume loop from where it left off
```

This avoids killing and restarting the effect. The subshell simply freezes mid-loop and continues after the flash completes.

### Concurrency Protection (filelock)

```bash
acquire_lock() {
    local fd
    exec {fd}>"$LOCK_FILE"
    flock -w 2 "$fd" 2>/dev/null || return 1
}
```

`flock -w 2` waits up to 2 seconds for the lock. If another `glow-flash` is already running (e.g., burst of notifications), the second call is **skipped** (`return 1`). This prevents two concurrent writes to `/proc/acpi/call` which would corrupt the EC state.

---

## 7. Preset System

### Three Palettes

| Palette | Array | Count | Philosophy |
|---------|-------|-------|------------|
| `GRV` | `declare -rA GRV` | 9 colors | Gruvbox Material — muted, warm, good for long sessions |
| `PURE` | `declare -rA PURE` | 10 colors | Saturated RGB — vivid, high contrast |
| `AMBIENT` | `declare -rA AMBIENT` | 12 colors | Themed moods — lava, ocean, hacker |

### Resolution Chain

```
kb-rgb preset "ocean"
    │
    └── resolve_preset("ocean")
            │
            ├── check GRV["ocean"]    → not found
            ├── check PURE["ocean"]   → not found
            └── check AMBIENT["ocean"] → "006994" ✓
```

Short aliases also exist for common Gruvbox colors: `gred`, `ggrn`, `gyel`, `gblu`, `gpur`, `gaqua`, `gorg`, `gfg`, `ggray`.

### Cycle List

`CYCLE_COLORS` is a curated ordered array (all 9 Gruvbox + 6 pure basics). The `cycle` command increments the index modulo array length and persists it to `cycle_index`. `$mod+F9` triggers this directly without entering any mode.

---

## 8. i3 Integration

### Entry Points

| Binding | Action |
|---------|--------|
| `$mod+backslash` | Enter `kb-rgb` mode |
| `$mod+F9` | Quick cycle (no mode) |
| `$mod+Shift+F9` | Quick off (no mode) |

### Mode Tree

```
kb-rgb mode (via $mod+\)
│
├── Color presets
│   ├── r/g/b/w/c/m/y/o/p/i/h     → pure colors
│   └── Shift+r/g/y/b/p/a/o/f     → gruvbox colors
│
├── Brightness
│   ├── Up    → 100%
│   └── Down  → 50%
│
├── Power
│   ├── 0     → off (saves state)
│   └── 1     → on  (restores last color)
│
├── d          → rofi/dmenu color picker
├── space      → cycle (same as $mod+F9)
├── n          → toggle notification glow
│
└── e          → enter kb-fx sub-mode
    │
    ├── b/B    → breathe speed 5/8
    ├── w/W    → wave speed 5/8
    ├── s/S    → strobe speed 5/8
    ├── c/C    → candle speed 5/8
    ├── p      → pulse (one-shot)
    ├── o/O    → police speed 5/8
    ├── d/D    → disco speed 5/8
    ├── h/H    → heartbeat speed 5/8
    ├── q/0    → stop effect
    └── BackSpace → back to kb-rgb mode
```

### Variable Binding

```
# keyboard-rgb.conf
set $kb /home/kali/work/config/bin/kb-rgb
```

This variable is machine-specific (path changes per clone location). `update-paths.sh` patches this with `sed` using the realpath of the current machine:

```bash
sed -i "s|set \$kb .*|set \$kb $KB_REAL|" "$KB_I3CONF"
```

---

## 9. Setup & Recovery

### First Install (fresh machine)

`restore-dotfiles.sh` handles everything:

1. Symlinks `bin/kb-rgb` to `~/.local/bin/kb-rgb`
2. Sets ownership `root:root` + mode `0755` on the canonical path
3. Generates `/etc/sudoers.d/kb-rgb` with the correct realpath
4. Patches `dunst/scripts/kb-rgb-glow` with the correct absolute path
5. Patches `i3/config.d/keyboard-rgb.conf` `$kb` variable

### Subsequent Machines (already set up, different path)

```bash
cd ~/path/to/config/setup-recovery
bash update-paths.sh
```

This script runs steps 2–5 without a full reinstall.

### What Breaks When Path Changes

| Item | Symptom | Fix |
|------|---------|-----|
| `/etc/sudoers.d/kb-rgb` has old path | `sudo kb-rgb` asks for password | `update-paths.sh` |
| `dunst/scripts/kb-rgb-glow` has old path | Notifications don't flash | `update-paths.sh` |
| `i3/config.d/keyboard-rgb.conf` `$kb` | i3 bindings fail silently | `update-paths.sh` |
| `bin/kb-rgb` is user-owned | Security model broken (but functional) | `update-paths.sh` |

### Manual Security Hardening

If you need to manually apply the security model:

```bash
sudo chown root:root ~/work/config/bin/kb-rgb
sudo chmod 0755 ~/work/config/bin/kb-rgb
```

Verify:
```bash
stat ~/work/config/bin/kb-rgb
# Should show: Uid: (0/root) Gid: (0/root) Access: (0755/-rwxr-xr-x)
```

---

## 10. Full Command Reference

```
COLORS:
  kb-rgb color RRGGBB           Set hex color (e.g., kb-rgb color ea6962)
  kb-rgb color R G B            Set decimal per-channel (0–255 each)
  kb-rgb preset NAME            Named preset
  kb-rgb presets                List all presets with hex values
  kb-rgb pick                   Interactive rofi/dmenu picker
  kb-rgb cycle                  Advance to next color in cycle list

BRIGHTNESS & POWER:
  kb-rgb brightness 0-100       Set brightness percentage
  kb-rgb off                    Backlight off (saves brightness=0 to state)
  kb-rgb on                     Restore last saved color + brightness

EFFECTS (speed 1–10, default 5):
  kb-rgb breathe [COLOR] [SPD]  Breathing pulse (brightness oscillation)
  kb-rgb wave C1 C2 [SPD]       Smooth fade between two colors (loops)
  kb-rgb strobe [COLOR] [SPD]   Rapid on/off flash
  kb-rgb candle [SPD]           Warm random flicker (simulates flame)
  kb-rgb pulse [COLOR] [SPD]    Single brightness throb (one-shot, non-looping)
  kb-rgb police [SPD]           Alternating red/blue double-flash
  kb-rgb disco [SPD]            Random RGB per tick
  kb-rgb heartbeat [CLR] [SPD]  Lub-dub two-beat pattern
  kb-rgb fade HEX1 HEX2 [N]    One-shot linear interpolation (N steps, default 20)
  kb-rgb stop                   Kill running effect, do not change color

NOTIFICATIONS (dunst integration):
  kb-rgb glow-toggle            Toggle notification flash on/off
  kb-rgb glow-flash URGENCY     Fire flash for urgency (low|normal|critical)
  kb-rgb glow-test              Demo all three urgency patterns in sequence

INFO:
  kb-rgb status                 Show current color, brightness, glow state, effect
```

---

## 11. Troubleshooting

### `acpi_call write failed — is acpi_call module loaded?`

```bash
# Check if module is loaded
lsmod | grep acpi_call

# Load manually
sudo modprobe acpi_call

# Verify it will load on boot (should be in /etc/modules-load.d/ or handled by acpi_call-dkms)
ls /etc/modules-load.d/
```

### `sudo kb-rgb` asks for password

The sudoers path doesn't match the canonical realpath of the file.

```bash
# Check what sudoers expects
sudo cat /etc/sudoers.d/kb-rgb

# Check actual realpath
realpath ~/work/config/bin/kb-rgb

# If they differ, regenerate
cd ~/work/config/setup-recovery && bash update-paths.sh
```

### Keyboard stays on after notification when it was off

The `state` file has wrong brightness value. Inspect and fix:

```bash
cat ~/.local/state/kb-rgb/state
# Expected: RRGGBB\n0\n  (second line = brightness)

# If second line is non-zero, fix:
sudo kb-rgb off
cat ~/.local/state/kb-rgb/state  # should now show 0
```

### Effect doesn't stop when starting a new one

Stale PID file — the previous effect's PID was reused by another process.

```bash
# Manual cleanup
rm -f ~/.local/state/kb-rgb/effect.pid ~/.local/state/kb-rgb/effect.name
sudo kb-rgb stop
```

### Colors look wrong (wrong hue)

Verify BRG byte order. If you set `red` and get blue, the byte order is inverted. This is correct behavior — the EC uses BRG not RGB. The `hw_set_color` function handles the swap:

```bash
# Trace a color write
bash -x ~/work/config/bin/kb-rgb color FF0000 2>&1 | grep wmi_write
# Should show: 0xF0000000FF00  (B=00, R=FF, G=00 → BRG)
```
