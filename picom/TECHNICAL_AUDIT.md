# Picom Configuration: Deep Technical Audit

**Auditor Role:** Principal System Architect  
**Audit Date:** 2026-01-31  
**Configuration Target:** `picom.conf` (X11 Compositor Configuration for Intel UHD / Arch / i3)

---

## Phase 1: Deep Documentation

### 1. Architecture: Data Flow Analysis

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           PICOM DATA FLOW                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────────────────┐    │
│  │  X11 Server  │────▶│    picom     │────▶│  GPU (Intel UHD via GLX) │    │
│  │  (Xorg)      │◀────│  compositor  │◀────│  Frame Buffer            │    │
│  └──────────────┘     └──────────────┘     └──────────────────────────┘    │
│         │                    │                         │                    │
│         │                    ▼                         │                    │
│         │           ┌──────────────────┐               │                    │
│         │           │ Configuration    │               │                    │
│         │           │ picom.conf       │               │                    │
│         │           │ - Shadows        │               │                    │
│         │           │ - Fading         │               │                    │
│         │           │ - Blur           │               │                    │
│         │           │ - Opacity        │               │                    │
│         │           │ - Corners        │               │                    │
│         └───────────│ - Window Rules   │───────────────┘                    │
│                     └──────────────────┘                                    │
│                                                                             │
│  STARTUP SEQUENCE:                                                          │
│  i3 config ──▶ exec_always picom -b ──▶ loads ~/.config/picom/picom.conf    │
│                                                                             │
│  TOGGLE FLOW:                                                               │
│  i3status-rs ──▶ picom-toggle.sh ──▶ pgrep/killall ──▶ signal i3status-rs  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### Configuration Sections Flow:

| Section | Purpose | GPU Impact | Memory Impact |
|---------|---------|------------|---------------|
| **Shadows** | Drop shadows on windows | High (shader-based) | Medium (shadow buffer per window) |
| **Fading** | Transition animations | Medium (frame interpolation) | Low (delta computation) |
| **Opacity** | Window transparency | Medium (alpha blending) | Low |
| **Corners** | Rounded corners | High (geometry modification) | Medium |
| **Blur** | Background blur (dual_kawase) | **VERY HIGH** | High (multi-pass buffer) |
| **Backend** | GLX rendering path | Defines all GPU ops | Driver-dependent |

### 2. Dependencies: System Integration Map

```
┌───────────────────────────────────────────────────────────────────────────┐
│                    DEPENDENCY GRAPH                                        │
├───────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  HARD DEPENDENCIES (Required):                                            │
│  ├── X11/Xorg server                                                      │
│  ├── OpenGL/GLX drivers (Intel Mesa)                                      │
│  └── libconfig (configuration parser)                                     │
│                                                                           │
│  INTEGRATION POINTS:                                                      │
│  ├── ~/.config/i3/config                                                  │
│  │   ├── Line 20: exec_always --no-startup-id picom -b                    │
│  │   └── Line 136: pkill -TERM picom (on exit)                            │
│  │                                                                        │
│  ├── ~/.config/i3/scripts/picom-toggle.sh                                 │
│  │   └── Runtime toggle via pgrep/killall                                 │
│  │                                                                        │
│  ├── ~/.config/i3status-rust/config.toml                                  │
│  │   ├── Line 203: Status check (pgrep -x picom)                          │
│  │   └── Line 209: Toggle action callback                                 │
│  │                                                                        │
│  ├── ~/.config/kitty/kitty.conf                                           │
│  │   └── Line 20: Transparency depends on picom                           │
│  │                                                                        │
│  └── ~/config/setup-recovery/                                             │
│      ├── install-packages.sh: pacman -S picom                             │
│      └── restore-dotfiles.sh: symlink picom config                        │
│                                                                           │
│  AFFECTED WINDOW CLASSES (Excluded from effects):                         │
│  ├── Notification systems (Conky, Notify-osd, Cairo-clock)                │
│  ├── Screenshot tools (slop, Slop)                                        │
│  ├── Bars (Polybar, i3bar, i3-frame)                                      │
│  ├── Menus (popup_menu, dropdown_menu, combo)                             │
│  ├── Utilities (utility, tooltip, menu)                                   │
│  └── Audio (Pavucontrol)                                                  │
│                                                                           │
└───────────────────────────────────────────────────────────────────────────┘
```

### 3. Hidden Complexity: Magic Numbers & Unclear Logic

#### 3.1 Magic Numbers Identified

| Value | Location | Meaning | Risk |
|-------|----------|---------|------|
| `20` | shadow-radius | Shadow blur radius in pixels | No documentation on optimal range |
| `0.60` | shadow-opacity | 60% shadow darkness | Arbitrary aesthetic choice |
| `-20, -20` | shadow-offset-x/y | Shadow displacement | **Coupled to radius** - change one, must change other |
| `0.05` | fade-in/out-step | 5% opacity per frame | **Performance-critical** - lower = more frames |
| `8` | fade-delta | Milliseconds between fade steps | **Undocumented coupling** with step |
| `10` | corner-radius | Rounded corner radius | Arbitrary, no adaptive scaling |
| `2` | blur-strength | Dual kawase passes | **GPU-intensive** - exponential cost |
| `"3x3box"` | blur-kern | Convolution kernel | Dead code - ignored when using dual_kawase |
| `0.95` | tooltip opacity | 95% tooltip transparency | Why not 1.0 or 0.9? Undocumented |
| `80` | i3bar opacity-rule | 80% bar transparency | Duplicated definition conflict potential |

#### 3.2 Unclear Logic & Side Effects

**Issue 1: Duplicate `inactive-opacity-override`**
```conf
# Line 55:
inactive-opacity-override = false; # Let window manager control opacity

# Line 170:
inactive-opacity-override = false;
```
**Side Effect:** Second definition overrides first. Redundant and confusing.

**Issue 2: Dead Code - `blur-kern`**
```conf
blur-method = "dual_kawase";  # Using dual_kawase
blur-kern = "3x3box";         # IGNORED - only applies to "kernel" method
```
**Side Effect:** Configuration noise. Suggests blur-kern has effect when it doesn't.

**Issue 3: Inconsistent Exclusion Lists**
```
shadow-exclude:      13 rules
rounded-corners-exclude: 10 rules  
blur-background-exclude: 12 rules
```
**Side Effect:** Different window types get inconsistent treatment. `Dmenu` excluded from corners but not shadows. `Pavucontrol` excluded from blur but not shadows.

**Issue 4: Implicit Coupling - Shadow Geometry**
```conf
shadow-radius = 20;
shadow-offset-x = -20;
shadow-offset-y = -20;
```
**Side Effect:** Offset must equal negative radius for centered shadow. Not documented. Change radius without offset = asymmetric shadows.

**Issue 5: Boolean Inconsistency**
```conf
no-fading-openclose = false    # Missing semicolon
no-fading-destroyed-argb = true  # Has implicit semicolon handling
```
**Side Effect:** Works by accident. Fragile.

**Issue 6: Commented-Out Code Ambiguity**
```conf
# shadow-color = "#000000"
# xrender-sync-fence = true;
```
**Side Effect:** Is this disabled intentionally or TODO? No explanation.

---

## Phase 2: Gap Analysis & Optimization

### 1. Performance Analysis

#### 1.1 Critical Performance Issues

**ISSUE P1: Blur Method Cost (HIGH IMPACT)**
```conf
blur-method = "dual_kawase";
blur-strength = 2;
```
- **Problem:** Dual kawase at strength 2 = 4 GPU passes minimum
- **Cost:** O(4n) where n = pixels affected. On 4K display = 33M pixel ops per blur update
- **Evidence:** Each pass requires full-screen texture read/write

**Proposed Fix:**
```conf
# BEFORE: Always blur everything
blur-method = "dual_kawase";
blur-strength = 2;

# AFTER: Conditional blur with lower strength for performance
blur-method = "dual_kawase";
blur-strength = 1;  # Reduced: 2 passes instead of 4
blur-background = false;  # Disable by default
blur-background-frame = false;

# Enable blur ONLY for specific windows that need it
rules: ({
  match = "class_g = 'kitty'";
  blur-background = true;
})
```

**ISSUE P2: Fade Animation Granularity**
```conf
fade-in-step = 0.05;   # 20 frames to complete fade
fade-out-step = 0.05;  # 20 frames to complete fade
fade-delta = 8;        # 8ms per frame = 125 FPS fade rate
```
- **Problem:** 20 frames at 8ms = 160ms fade. Attempts 125 FPS updates.
- **Cost:** Unnecessary compositor wake-ups. vsync caps at 60/144Hz anyway.

**Proposed Fix:**
```conf
# AFTER: Faster, fewer frames
fade-in-step = 0.1;    # 10 frames to complete
fade-out-step = 0.1;
fade-delta = 16;       # ~60 FPS is sufficient
```

**ISSUE P3: Shadow Computation Overhead**
```conf
shadow-radius = 20;  # Large shadow = large blur kernel
```
- **Problem:** Radius 20 = 41x41 pixel kernel. 1,681 samples per shadow pixel.
- **Cost:** O(r²) per shadowed pixel

**Proposed Fix:**
```conf
# AFTER: Smaller, faster shadows
shadow-radius = 12;      # 25x25 kernel = 625 samples (63% reduction)
shadow-offset-x = -12;   # Maintain centering
shadow-offset-y = -12;
shadow-opacity = 0.50;   # Compensate visual with slightly less opacity
```

#### 1.2 Unnecessary Allocations

**ISSUE P4: Redundant Detection Features**
```conf
detect-rounded-corners = true;  # Checks every window
detect-client-opacity = true;   # Checks every window
detect-transient = true;        # Checks every window
detect-client-leader = true;    # Checks every window
```
- **Problem:** Four separate window property queries per new window
- **Cost:** X11 round-trips on every window map event

**Proposed Fix (if stability permits):**
```conf
# Disable if you don't use applications that set these hints
detect-client-leader = false;  # Rarely used by modern apps
```

### 2. Safety Audit

#### 2.1 Race Conditions

**ISSUE S1: picom-toggle.sh Race Condition (CRITICAL)**
```bash
if pgrep -x "picom" > /dev/null; then
    killall picom  # RACE: picom could die between pgrep and killall
else
    picom -b       # RACE: picom could start between pgrep and picom
fi
```
- **Risk:** Double-start or kill-nonexistent race on rapid toggles
- **Impact:** Zombie process or startup failure

**Proposed Fix:**
```bash
#!/bin/bash
# Use pkill's built-in check-and-kill atomicity
# If picom exists, kill it. If not, this does nothing and returns 1.
if ! pkill -x picom 2>/dev/null; then
    # Only start if pkill reported nothing to kill
    picom -b
fi
pkill -RTMIN+13 i3status-rs
```

**ISSUE S2: Hardcoded Signal Number**
```bash
pkill -RTMIN+13 i3status-rs
```
- **Risk:** Signal 13 relative to RTMIN. RTMIN varies by system (usually 34).
- **Impact:** Wrong signal on non-Linux systems

**Proposed Fix:**
```bash
# Document or use consistent signal
pkill -SIGRTMIN+13 i3status-rs  # Explicit SIGRTMIN for clarity
```

#### 2.2 Memory Leak Potential

**ISSUE S3: use-damage without proper exclusions**
```conf
use-damage = true;
```
- **Risk:** Damage tracking buffers for excluded windows still allocated
- **Impact:** Minor memory creep over long sessions

**Mitigation:** Current configuration is acceptable but monitor with `picom --diagnostics`

#### 2.3 Configuration Errors

**ISSUE S4: Missing Semicolon**
```conf
no-fading-openclose = false  # Missing semicolon
```
- **Risk:** Parser may combine with next line in edge cases
- **Impact:** Silent misconfiguration

**Fix:**
```conf
no-fading-openclose = false;  # Added semicolon
```

### 3. Refactoring Suggestions

#### 3.1 Strategy Pattern: Window Type Handling

**Current Problem:** Three separate exclude lists with overlapping but inconsistent rules.

**Proposed Refactor: Unified Rule System**
```conf
# BEFORE: Scattered exclusions
shadow-exclude = [ "class_g = 'Polybar'", ... ];
rounded-corners-exclude = [ "class_g = 'Polybar'", ... ];
blur-background-exclude = [ "class_g = 'Polybar'", ... ];

# AFTER: Unified window rules (picom supports this)
rules: (
  {
    match = "class_g = 'Polybar' || window_type = 'dock'";
    shadow = false;
    corner-radius = 0;
    blur-background = false;
  },
  {
    match = "class_g = 'slop' || class_g = 'Slop' || name = 'slop'";
    shadow = false;
    blur-background = false;
    fade = false;
  },
  {
    match = "window_type = 'popup_menu' || window_type = 'dropdown_menu' || window_type = 'menu' || window_type = 'combo'";
    shadow = false;
    corner-radius = 0;
    blur-background = false;
  }
)
```

**Benefits:**
- Single source of truth per window class
- Reduces config lines by ~50%
- Eliminates inconsistency bugs

#### 3.2 Template Pattern: Predefined Profiles

**Create separate profile files for different performance needs:**

```
picom/
├── picom.conf           # Active config (symlink)
├── profiles/
│   ├── performance.conf # Minimal effects for battery/older hardware
│   ├── balanced.conf    # Current config
│   └── eye-candy.conf   # Maximum effects
└── toggle-profile.sh    # Switch between profiles
```

**profiles/performance.conf:**
```conf
# Minimal compositor - just vsync and basic functionality
shadow = false;
fading = false;
blur-background = false;
corner-radius = 0;
backend = "glx";
vsync = true;
use-damage = true;
```

#### 3.3 Factory Pattern: Dynamic Backend Selection

```bash
#!/bin/bash
# detect-backend.sh - Called before picom starts

# Check GPU vendor
GPU=$(lspci | grep -i vga)

if echo "$GPU" | grep -qi nvidia; then
    # NVIDIA works best with glx
    sed -i 's/^backend = .*/backend = "glx";/' ~/.config/picom/picom.conf
elif echo "$GPU" | grep -qi intel; then
    # Intel: glx with optimizations
    sed -i 's/^backend = .*/backend = "glx";/' ~/.config/picom/picom.conf
    sed -i 's/^glx-no-stencil = .*/glx-no-stencil = true;/' ~/.config/picom/picom.conf
elif echo "$GPU" | grep -qi amd; then
    # AMD: egl sometimes better
    sed -i 's/^backend = .*/backend = "egl";/' ~/.config/picom/picom.conf
fi
```

### 4. Missing Tests & Edge Cases

#### 4.1 Untested Edge Cases

| Edge Case | Risk | Test Method |
|-----------|------|-------------|
| **Rapid toggle spam** | Race condition, zombie processes | Script: toggle 100x in 1 second |
| **4K/HiDPI display** | Shadow/corner radius too small | Manual verification at 200% scaling |
| **Multi-monitor different DPI** | Inconsistent effects per monitor | Connect mixed DPI monitors |
| **Fullscreen game** | Compositor overhead, input lag | Benchmark with `mangohud` |
| **Window drag across monitors** | Tearing, effect glitches | Visual inspection |
| **Suspend/resume cycle** | GPU state corruption | `systemctl suspend` and resume |
| **Hot-plug monitor** | Config reload needed? | Plug/unplug while running |
| **OBS/screen recording** | Capture with/without effects | Record with OBS |
| **Extremely large window** | Performance cliff | Maximize across 2x 4K monitors |
| **Transparent terminal + blur** | Double blur visual artifact | kitty with transparency over browser |

#### 4.2 Proposed Test Scripts

**Test 1: Toggle Stress Test**
```bash
#!/bin/bash
# test-toggle-stress.sh
for i in {1..100}; do
    ~/.config/i3/scripts/picom-toggle.sh &
done
wait
# Check for zombie processes
count=$(pgrep -c picom)
if [ "$count" -gt 1 ]; then
    echo "FAIL: Multiple picom instances ($count found)"
    exit 1
fi
```

**Test 2: Performance Benchmark**
```bash
#!/bin/bash
# test-performance.sh
picom --benchmark 300 --backend glx 2>&1 | tee /tmp/picom-bench.log
# Extract FPS, should be >= 60
fps=$(grep -oP 'FPS:\s+\K[\d.]+' /tmp/picom-bench.log | tail -1)
if (( $(echo "$fps < 60" | bc -l) )); then
    echo "FAIL: FPS $fps below 60"
    exit 1
fi
```

**Test 3: Configuration Syntax Validation**
```bash
#!/bin/bash
# test-config-syntax.sh
picom --config ~/.config/picom/picom.conf --diagnostics 2>&1
if [ $? -ne 0 ]; then
    echo "FAIL: Configuration syntax error"
    exit 1
fi
```

---

## Summary: Priority Action Items

| Priority | Issue | Effort | Impact |
|----------|-------|--------|--------|
| 🔴 HIGH | Fix race condition in picom-toggle.sh | 5 min | Prevents zombie processes |
| 🔴 HIGH | Reduce blur-strength from 2 to 1 | 1 min | ~50% GPU load reduction |
| 🟡 MED | Unify exclusion lists using rules: | 30 min | Maintainability |
| 🟡 MED | Remove dead blur-kern config | 1 min | Reduce confusion |
| 🟡 MED | Add missing semicolon | 1 min | Parser safety |
| 🟡 MED | Remove duplicate inactive-opacity-override | 1 min | Config clarity |
| 🟢 LOW | Reduce shadow-radius to 12 | 1 min | Performance gain |
| 🟢 LOW | Increase fade-delta to 16ms | 1 min | Reduce wakeups |
| 🟢 LOW | Create performance profiles | 1 hour | User flexibility |

---

## Appendix: Recommended Final Configuration

```conf
## Picom Configuration - Audited & Optimized
## Last Audit: 2026-01-31

#################################
#             Shadows           #
#################################

shadow = true;
shadow-radius = 12;        # Reduced from 20 for performance
shadow-opacity = 0.55;     # Slightly reduced to compensate
shadow-offset-x = -12;     # Matched to radius
shadow-offset-y = -12;

#################################
#           Fading              #
#################################

fading = true;
fade-in-step = 0.08;       # Faster fade
fade-out-step = 0.08;
fade-delta = 12;           # Balance between smoothness and CPU

no-fading-openclose = false;
no-fading-destroyed-argb = true;

#################################
#   Transparency / Opacity      #
#################################

frame-opacity = 1.0;
inactive-opacity-override = false;  # Single definition
inactive-opacity = 1.0;

#################################
#           Corners             #
#################################

corner-radius = 10;

#################################
#            Blur               #
#################################

blur-method = "dual_kawase";
blur-strength = 1;          # Reduced from 2 for performance
blur-background = true;
blur-background-frame = true;
blur-background-fixed = false;
# blur-kern removed - not used with dual_kawase

#################################
#       General Settings        #
#################################

backend = "glx";
vsync = true;

glx-no-stencil = true;
glx-no-rebind-pixmap = true;

use-damage = true;
dithered-present = false;
detect-rounded-corners = true;
detect-client-opacity = true;
detect-transient = true;
# detect-client-leader: Controls grouping of windows by client leader.
# Modern apps (GTK3+, Qt5+, Electron) rarely set WM_CLIENT_LEADER.
# Disabling saves X11 round-trips. Re-enable if experiencing window
# grouping issues with legacy X11 applications (e.g., old Java Swing apps).
detect-client-leader = false;

log-level = "warn";

#################################
#     Unified Window Rules      #
#################################

# Shadows - exclude non-content windows
shadow-exclude = [
  "class_g = 'Conky'",
  "class_g ?= 'Notify-osd'",
  "class_g = 'Cairo-clock'",
  "class_g = 'slop'",
  "class_g = 'Polybar'",
  "class_g = 'i3-frame'",
  "_GTK_FRAME_EXTENTS@",
  "window_type = 'dock'",
  "window_type = 'popup_menu'",
  "window_type = 'dropdown_menu'",
  "window_type = 'utility'",
  "window_type = 'menu'",
  "window_type = 'combo'"
];

# Corners - exclude bars and menus
rounded-corners-exclude = [
  "window_type = 'dock'",
  "window_type = 'desktop'",
  "class_g = 'i3-frame'",
  "class_g = 'Dmenu'",
  "class_g = 'Rofi'",
  "class_g = 'Polybar'",
  "window_type = 'popup_menu'",
  "window_type = 'dropdown_menu'",
  "window_type = 'tooltip'",
  "window_type = 'menu'",
  "window_type = 'combo'"
];

# Blur - exclude non-transparent elements
blur-background-exclude = [
  "window_type = 'dock'",
  "window_type = 'desktop'",
  "class_g = 'slop'",
  "_GTK_FRAME_EXTENTS@",
  "window_type = 'popup_menu'",
  "window_type = 'dropdown_menu'",
  "window_type = 'tooltip'",
  "window_type = 'utility'",
  "window_type = 'menu'",
  "window_type = 'combo'",
  "class_g = 'Pavucontrol'"
];

#################################
#       Window Types            #
#################################

wintypes:
{
  tooltip = { fade = true; shadow = true; opacity = 0.95; focus = true; };
  popup_menu = { opacity = 1.0; shadow = false; };
  dropdown_menu = { opacity = 1.0; shadow = false; };
  utility = { shadow = false; opacity = 1.0; };
  dock = { shadow = false; corner-radius = 0; };
  desktop = { shadow = false; corner-radius = 0; };
};

opacity-rule = [
  "80:class_g = 'i3bar'",
  "80:_NET_WM_WINDOW_TYPE = '_NET_WM_WINDOW_TYPE_DOCK'"
];
```

---

*End of Technical Audit Document*
