# Cursor Configuration: Complete A-to-Z Guide

> **TL;DR:** On Linux/X11, cursor config is split across 5+ independent layers.
> Each layer covers different apps. You need ALL of them or some windows will show
> a different (usually ugly Adwaita) cursor. This doc explains every layer, how
> they interact, and how to change anything.

---

## Table of Contents

1. [Your Current Config (Baseline)](#1-your-current-config-baseline)
2. [Why So Many Config Files?](#2-why-so-many-config-files)
3. [Layer 1 → Xresources (X11 native)](#3-layer-1--xresources-x11-native)
4. [Layer 2 → Environment Variables (.xprofile)](#4-layer-2--environment-variables-xprofile)
5. [Layer 3 → GTK3 Settings](#5-layer-3--gtk3-settings)
6. [Layer 4 → GTK4 Settings](#6-layer-4--gtk4-settings)
7. [Layer 5 → X11 Icon Theme Fallback (~/.icons/default)](#7-layer-5--x11-icon-theme-fallback-iconsdefault)
8. [Layer 6 → Qt (qt6ct)](#8-layer-6--qt-qt6ct)
9. [Available Cursor Themes on This System](#9-available-cursor-themes-on-this-system)
10. [What Each Setting Controls](#10-what-each-setting-controls)
11. [Standard Size Reference](#11-standard-size-reference)
12. [How to Change the Theme](#12-how-to-change-the-theme)
13. [How to Change the Size](#13-how-to-change-the-size)
14. [How to Change the Color (Bibata Variants)](#14-how-to-change-the-color-bibata-variants)
15. [How Changes Take Effect](#15-how-changes-take-effect)
16. [Troubleshooting: Mismatched Cursor](#16-troubleshooting-mismatched-cursor)
17. [The Bibata Cursor: Technical Details](#17-the-bibata-cursor-technical-details)
18. [Cursor-Adjacent: Text Cursor (Caret/Beam)](#18-cursor-adjacent-text-cursor-caretbeam)
19. [Maintenance Checklist](#19-maintenance-checklist)

---

## 1. Your Current Config (Baseline)

| Layer             | File                                  | Theme              | Size |
|-------------------|---------------------------------------|--------------------|------|
| X11 / Xresources  | `~/.Xresources`                       | Bibata-Modern-Ice  | 22   |
| Session env vars  | `~/.xprofile`                         | Bibata-Modern-Ice  | 22   |
| GTK3              | `~/.config/gtk-3.0/settings.ini`      | Bibata-Modern-Ice  | 24   |
| GTK4              | `~/.config/gtk-4.0/settings.ini`      | Bibata-Modern-Ice  | 24   |
| X11 icon fallback | `~/.icons/default/index.theme`        | → Bibata-Modern-Ice| —    |
| Qt6               | `~/.config/qt6ct/qt6ct.conf`          | (GTK3 style)       | —    |

> **Note:** GTK uses 24, X11 uses 22. This is intentional — GTK renders at a
> slightly larger size to look correct in GTK apps. X11 native windows look better
> at 22 on a 1080p screen. On a HiDPI (2K/4K) screen, both should be 48.

---

## 2. Why So Many Config Files?

Linux has no single cursor authority. Apps use different toolkits:

```
App Type          │ Reads From
──────────────────┼────────────────────────────────────────────────────
GTK3 apps         │ gtk-3.0/settings.ini
  (Thunar, dunst, │
   most desktop)  │
GTK4 apps         │ gtk-4.0/settings.ini
  (newer GNOME)   │
Qt5 apps          │ Xresources → XCURSOR_THEME env → qt5ct
Qt6 apps          │ qt6ct (which applies GTK3 style on this system)
X11 raw           │ Xresources (Xcursor.theme / Xcursor.size)
  (xterm, dmenu,  │
   some old apps) │
Session startup   │ XCURSOR_THEME / XCURSOR_SIZE env vars (from .xprofile)
  (any app that   │ — most reliable, set at display manager login time
   inherits env)  │
Fallback / legacy │ ~/.icons/default/index.theme
  (apps that look │
   at icon dirs)  │
```

The env vars (`XCURSOR_THEME`, `XCURSOR_SIZE`) set via `.xprofile` are the most
broadly effective single setting, because most toolkits ultimately fall back to
checking the environment when their own config is absent.

---

## 3. Layer 1 → Xresources (X11 native)

**File:** `~/.Xresources`  
**Repo location:** `/home/kali/work/config/.Xresources` (NOT a symlink — lives directly in `~`)

```x
! X11 cursor
Xcursor.theme: Bibata-Modern-Ice
Xcursor.size:  22

! Terminal text cursor color (this is the blinking bar/block in xterm, not mouse)
*cursorColor: #D8DEE9
```

### How it's loaded
`.Xresources` is merged at login by your display manager via `xrdb`. It is NOT
auto-reloaded. To apply changes to a running session:
```bash
xrdb -merge ~/.Xresources
```
New windows open after this command will use the updated cursor. Existing windows
keep the old cursor until restarted.

### What `Xcursor.size` affects
Only pure X11 apps (xterm, dmenu, some games, `i3` decorations). GTK/Qt apps
ignore this and use their own settings.

---

## 4. Layer 2 → Environment Variables (.xprofile)

**File:** `~/.xprofile`  
**Repo location:** `/home/kali/work/config/.xprofile` (NOT a symlink — lives directly in `~`)

```bash
export XCURSOR_THEME="Bibata-Modern-Ice"
export XCURSOR_SIZE=22
export QT_QPA_PLATFORMTHEME=qt6ct
```

### How it's loaded
`~/.xprofile` is sourced by the display manager (ly, lightdm, etc.) at session
start — before i3, before any app launches. All child processes inherit these env
vars. This makes `XCURSOR_THEME`/`XCURSOR_SIZE` the most reliable layer.

### Why it's NOT a repo symlink
`.xprofile` also controls `QT_QPA_PLATFORMTHEME` and potentially other
machine-specific session vars. It's treated as a user-local file, not linked from
the repo. To update it on a new machine, copy the values manually or let
`restore-dotfiles.sh` handle it (you can add it to `DOTFILES` array).

### Priority of env vars
```
XCURSOR_THEME/XCURSOR_SIZE env vars
    → override Xresources Xcursor.theme/Xcursor.size
    → override gtk settings.ini on some apps
```
When in doubt, set the env var. It wins almost everywhere.

---

## 5. Layer 3 → GTK3 Settings

**File:** `~/.config/gtk-3.0/settings.ini`  
**Repo location:** `~/work/config/gtk-3.0/settings.ini` (symlinked via restore-dotfiles)

```ini
[Settings]
gtk-cursor-theme-name=Bibata-Modern-Ice
gtk-cursor-theme-size=24
gtk-theme-name=adw-gtk3-dark
gtk-icon-theme-name=Papirus-Dark
gtk-application-prefer-dark-theme=1
```

### What it controls
All GTK3 applications: Thunar, Firefox (partially), dunst notifications,
polkit dialogs, most system GUI tools.

### How changes take effect
GTK3 apps read this at startup. Changes take effect for newly launched apps.
Some apps (Thunar) can be forced to re-read via:
```bash
gsettings set org.gnome.desktop.interface cursor-size 24
# or
gsettings set org.gnome.desktop.interface cursor-theme "Bibata-Modern-Ice"
```
`gsettings` writes to the GNOME/dconf backend; on a non-GNOME system (like i3),
this may or may not be read. The `settings.ini` file is the reliable path here.

---

## 6. Layer 4 → GTK4 Settings

**File:** `~/.config/gtk-4.0/settings.ini`  
**Repo location:** `~/work/config/gtk-4.0/settings.ini` (symlinked via restore-dotfiles)

Identical structure to GTK3. Controls newer GTK4 applications.

---

## 7. Layer 5 → X11 Icon Theme Fallback (~/.icons/default)

**File:** `~/.icons/default/index.theme`  
**Lives in:** `~/.icons/default/index.theme` (created by `restore-dotfiles.sh`, not in the repo itself)

```ini
[Icon Theme]
Name=Default
Comment=X11 cursor theme fallback override
Inherits=Bibata-Modern-Ice
```

### What it does
When an X11 app looks for a cursor and can't find one from the other layers, it
looks in these directories in order:
```
~/.icons/default/     ← user override (our file)
/usr/share/icons/default/  ← system (was: Adwaita on this machine)
```

Without this file, apps that don't read Xresources or env vars would fall back to
Adwaita, showing a mismatched cursor. With it, they inherit Bibata-Modern-Ice.

### The `Inherits=` mechanism
`Inherits=Bibata-Modern-Ice` means: look for cursor files in
`/usr/share/icons/Bibata-Modern-Ice/cursors/`. The icon theme lookup chain
resolves the actual cursor PNG/xcursor files from there.

---

## 8. Layer 6 → Qt (qt6ct)

**File:** `~/.config/qt6ct/qt6ct.conf`  
**Style setting:** `style=Fusion` with `QT_QPA_PLATFORMTHEME=qt6ct`

Qt6 on this system uses `qt6ct` which is configured to use GTK3 dialogs
(`standard_dialogs=gtk3`). This means Qt6 apps inherit the cursor from the GTK3
layer. No separate cursor config needed for Qt on this system.

The `cursor_flash_time=1000` setting in qt6ct controls the **text cursor blink
interval** (in milliseconds) for Qt app text inputs — unrelated to the mouse
pointer cursor.

---

## 9. Available Cursor Themes on This System

All installed in `/usr/share/icons/` via `bibata-cursor-theme-bin` (AUR):

| Theme Name                  | Description                                  |
|-----------------------------|----------------------------------------------|
| `Bibata-Modern-Ice`         | ★ **Current** — white, rounded corners, clean|
| `Bibata-Modern-Classic`     | Black, rounded corners                       |
| `Bibata-Modern-Amber`       | Orange/amber accent, rounded                 |
| `Bibata-Modern-Ice-Right`   | Left-handed version of Ice                   |
| `Bibata-Modern-Classic-Right` | Left-handed version of Classic             |
| `Bibata-Modern-Amber-Right` | Left-handed Amber                            |
| `Bibata-Original-Ice`       | Ice but with sharp/original corners          |
| `Bibata-Original-Classic`   | Classic with original corners                |
| `Bibata-Original-Amber`     | Amber with original corners                  |
| `Bibata-Original-*-Right`   | Left-handed variants of Original series      |

**Modern vs Original:** Modern has smoother, rounder cursor shapes. Original
matches the classic X11 cursor shapes more closely.

**Right variants:** These flip the cursor arrow to point from the right — for
left-handed mouse users.

---

## 10. What Each Setting Controls

```
Setting               │ Controls
──────────────────────┼──────────────────────────────────────────────────────
gtk-cursor-theme-name │ Which cursor image set to use (GTK apps)
gtk-cursor-theme-size │ Size of the cursor bitmap (GTK apps)
Xcursor.theme         │ Cursor image set for X11-native apps
Xcursor.size          │ Pixel size for X11-native apps
XCURSOR_THEME (env)   │ Same as Xcursor.theme but higher priority, broader reach
XCURSOR_SIZE (env)    │ Same as Xcursor.size but env-inherited by all apps
*cursorColor          │ Text cursor (blinking bar/block) color in xterm
cursor_flash_time     │ Text cursor blink speed (ms) in Qt apps
~/.icons/default      │ Cursor fallback for apps that check icon dirs directly
```

---

## 11. Standard Size Reference

| Screen           | Recommended Size | Notes                          |
|------------------|------------------|--------------------------------|
| 1080p (FHD)      | 22–24            | Current setting. Standard.     |
| 1440p (2K)       | 28–32            | Step up for better visibility  |
| 2160p (4K)       | 40–48            | Required to not look tiny      |
| HiDPI (fractional)| 32–40           | Depends on scale factor        |

**Why GTK=24 vs X11=22 on this system:**  
GTK renders cursors through Cairo at slightly different DPI than raw X11.
At 24, GTK cursors *look* the same visual weight as X11 at 22. It's a
calibration, not a mistake.

---

## 12. How to Change the Theme

To switch from `Bibata-Modern-Ice` to, for example, `Bibata-Modern-Classic`:

### Step 1 — Edit the repo files (GTK3/GTK4)
```bash
# In the repo:
sed -i 's/gtk-cursor-theme-name=.*/gtk-cursor-theme-name=Bibata-Modern-Classic/' \
    ~/work/config/gtk-3.0/settings.ini \
    ~/work/config/gtk-4.0/settings.ini
```

### Step 2 — Edit ~/.Xresources
```bash
sed -i 's/Xcursor.theme:.*/Xcursor.theme: Bibata-Modern-Classic/' ~/.Xresources
xrdb -merge ~/.Xresources
```

### Step 3 — Edit ~/.xprofile
```bash
sed -i 's/XCURSOR_THEME=.*/XCURSOR_THEME="Bibata-Modern-Classic"/' ~/.xprofile
```
*(Takes full effect at next login. For the current session, also run:)*
```bash
export XCURSOR_THEME="Bibata-Modern-Classic"
```

### Step 4 — Update ~/.icons/default/index.theme
```bash
sed -i 's/Inherits=.*/Inherits=Bibata-Modern-Classic/' ~/.icons/default/index.theme
```

### Step 5 — Apply to running i3/GTK session
```bash
# GTK3 runtime settings (if GNOME schemas are present):
gsettings set org.gnome.desktop.interface cursor-theme "Bibata-Modern-Classic"
# Restart your WM bar/compositor for full effect:
pkill dunst && dunst &
```

---

## 13. How to Change the Size

### Quick change for testing (current session only):
```bash
# X11 immediate effect (new windows only):
xrdb -merge - <<< "Xcursor.size: 32"
export XCURSOR_SIZE=32
```

### Permanent change (all 4 files):
```bash
NEW_SIZE_X11=32    # for Xresources and xprofile
NEW_SIZE_GTK=32    # for GTK (usually same or +2)

# GTK files (in repo, propagate via symlink):
sed -i "s/gtk-cursor-theme-size=.*/gtk-cursor-theme-size=$NEW_SIZE_GTK/" \
    ~/work/config/gtk-3.0/settings.ini \
    ~/work/config/gtk-4.0/settings.ini

# Xresources (in ~):
sed -i "s/Xcursor.size:.*/Xcursor.size: $NEW_SIZE_X11/" ~/.Xresources
xrdb -merge ~/.Xresources

# xprofile (in ~):
sed -i "s/XCURSOR_SIZE=.*/XCURSOR_SIZE=$NEW_SIZE_X11/" ~/.xprofile
```
Log out and back in for the env var change to take full effect in all apps.

---

## 14. How to Change the Color (Bibata Variants)

Bibata comes in three color families:

| Color  | Dark bg | Light bg | Theme name suffix |
|--------|---------|----------|-------------------|
| Ice    | ✓ great  | OK       | `-Ice`            |
| Classic| ✓ great  | OK       | `-Classic`        |
| Amber  | ✓ great  | OK       | `-Amber`          |

`Ice` = white cursor (best on dark desktops and dark terminal backgrounds)  
`Classic` = black cursor (traditional, best on light backgrounds)  
`Amber` = orange cursor (high-visibility, distinctive)

To switch colors, you're switching the full theme name (see section 12). There is
no way to change *just* the color without switching themes — the colors are baked
into the cursor PNG files inside each theme directory.

---

## 15. How Changes Take Effect

| Change made                        | When it applies                                    |
|------------------------------------|----------------------------------------------------|
| xrdb -merge ~/.Xresources          | New X11 windows immediately                        |
| export XCURSOR_THEME/SIZE          | New processes launched from this shell             |
| ~/.xprofile                        | Next display manager login (full session restart)  |
| gtk settings.ini                   | New GTK app launches                               |
| ~/.icons/default/index.theme       | New X11 app launches (cached by xrdb/session)      |
| gsettings cursor-theme/size        | Active GTK apps that listen to GSettings           |

**The nuclear option (all apps, no logout):**
```bash
# 1. Apply xrdb
xrdb -merge ~/.Xresources
# 2. Set env (for new processes from this shell)
export XCURSOR_THEME="Bibata-Modern-Ice"
export XCURSOR_SIZE=22
# 3. Restart compositor (picom) — forces some wm decorations to reload
pkill picom; picom --daemon
# 4. Reload i3
i3-msg reload
# 5. Restart dunst
pkill dunst; dunst &
# 6. Restart any GTK apps you care about
```
For the absolute cleanest change: log out and back in.

---

## 16. Troubleshooting: Mismatched Cursor

### Symptom: cursor changes when hovering browser window
**Cause:** Firefox or Electron apps bundle their own cursor or use a different
GTK version.  
**Fix:** Set `XCURSOR_THEME` and `XCURSOR_SIZE` env vars (they override
everything):
```bash
# In ~/.xprofile (already done on this system):
export XCURSOR_THEME="Bibata-Modern-Ice"
export XCURSOR_SIZE=22
```

### Symptom: i3 title bar / root window shows wrong cursor
**Cause:** i3's root window cursor is set by X11 Xresources.  
**Fix:** `xrdb -merge ~/.Xresources` and reload i3.

### Symptom: application shows Adwaita cursor
**Cause:** App is not reading env vars, GTK settings, OR icon dir. Could also be
Qt5 app ignoring qt6ct.  
**Fix:** 
1. Verify `~/.icons/default/index.theme` exists and has `Inherits=Bibata-Modern-Ice`
2. For Qt5 specifically: install `qt5ct`, run `qt5ct`, set cursor → 
   or ensure Qt5 env is set: `export QT_QPA_PLATFORMTHEME=qt5ct`

### Symptom: cursor size differs between apps
**Cause:** Different config layers have different sizes (GTK=24, X11=22 on this
system is expected). If the difference is noticeable, normalize all layers to the
same value.  
**Fix:** Set GTK3, GTK4, Xresources, and xprofile to the same size.

### Symptom: cursor works but disappears in games/SDL apps
**Cause:** SDL apps hide their cursor and draw their own. Unrelated to theme.

### Symptom: cursor wrong after suspend/resume
**Cause:** X11 cursor state can be lost. Usually fixes itself.  
**Fix:** `xrdb -merge ~/.Xresources`

---

## 17. The Bibata Cursor: Technical Details

**Package:** `bibata-cursor-theme-bin` (AUR)  
**Install location:** `/usr/share/icons/Bibata-Modern-Ice/`  
**Internal structure:**
```
/usr/share/icons/Bibata-Modern-Ice/
├── cursors/           ← X11 xcursor format binary files (one per cursor type)
│   ├── left_ptr       ← The main arrow cursor
│   ├── text           ← The text/I-beam cursor
│   ├── hand2          ← The hand (link hover) cursor
│   ├── watch          ← Spinning/loading cursor
│   ├── crosshair      ← Crosshair
│   └── ... (~80 total cursor names)
├── index.theme        ← Theme metadata (Name, Comment, Inherits)
└── cursor.theme       ← Simple `[Cursor Theme]` stanza (legacy format)
```

**X11 cursor file format:**  
Each file in `cursors/` is an xcursor binary — it can contain multiple image
sizes (e.g., 22px, 24px, 32px, 48px) so the compositor picks the nearest size to
what's configured. This is why `Xcursor.size: 22` still looks good — there's a
22px embedded in the xcursor file.

**Symlinks in cursors/:**  
X11 cursor names are standardized but apps request cursors by many aliases.
The `cursors/` directory has many symlinks:
```bash
ls -la /usr/share/icons/Bibata-Modern-Ice/cursors/ | grep ' -> '
# e.g.: pointing_hand -> hand2
#       arrow -> left_ptr
```

---

## 18. Cursor-Adjacent: Text Cursor (Caret/Beam)

The "cursor" also refers to the blinking text cursor inside terminal/editor
windows. That's a completely different setting:

### Terminal text cursor color (xterm / Xresources)
```x
*cursorColor: #D8DEE9   ! Color of the text cursor block/bar in xterm
```
Current value is Nord foreground (#D8DEE9, a light grey-blue).

### Kitty text cursor
In `~/work/config/kitty/kitty.conf`:
```conf
cursor #D8DEE9           # text cursor color (matches Nord scheme)
cursor_shape block       # block | beam | underline
cursor_blink_interval 0  # 0 = no blink; positive = seconds between blinks
```

### Qt6 text cursor blink
In `~/.config/qt6ct/qt6ct.conf`:
```ini
[Interface]
cursor_flash_time=1000   # milliseconds; 0 = disable blink
```
1000ms = 1 second cycle (500ms on, 500ms off).

### Neovim cursor
In Neovim config (`lua/`): cursor shape and blink are controlled via
`vim.opt.guicursor`. This is completely independent of Xresources.

---

## 19. Maintenance Checklist

When you change cursor theme/size, verify ALL of these are updated:

```
[ ] ~/work/config/gtk-3.0/settings.ini   → gtk-cursor-theme-name / gtk-cursor-theme-size
[ ] ~/work/config/gtk-4.0/settings.ini   → same
[ ] ~/.Xresources                         → Xcursor.theme / Xcursor.size
[ ] ~/.xprofile                           → XCURSOR_THEME / XCURSOR_SIZE
[ ] ~/.icons/default/index.theme          → Inherits=
[ ] Run: xrdb -merge ~/.Xresources
[ ] Log out and back in for env var change to propagate to all apps
```

When you add a new machine (different display, HiDPI):
```
[ ] Update sizes in GTK settings.ini (GTK=48 for 4K)
[ ] Update ~/.Xresources Xcursor.size
[ ] Update ~/.xprofile XCURSOR_SIZE
[ ] Log out / log in
```

---

*Last verified: February 2026 — Arch Linux, i3wm, X11, Bibata-Modern-Ice*
