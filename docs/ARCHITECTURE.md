# Deep Technical Architecture Documentation

> **Audit Date:** 2026-01-31  
> **Scope:** Complete dotfiles repository for Arch Linux workstation  
> **Author:** Principal System Architect Audit

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Architecture Diagram](#architecture-diagram)
3. [Data Flow Analysis](#data-flow-analysis)
4. [Component Dependencies](#component-dependencies)
5. [Hidden Complexity & Magic Values](#hidden-complexity--magic-values)
6. [Side Effects & State Management](#side-effects--state-management)

---

## 1. System Overview

This repository is a **production-grade Linux workstation configuration** targeting Arch Linux with dual window manager support (i3/X11 and Sway/Wayland). It consists of:

| Layer | Components | Purpose |
|-------|------------|---------|
| **Shell** | Zsh + Sheldon + P10k | Interactive environment, aliases, functions |
| **Window Manager** | i3 (X11) / Sway (Wayland) | Tiling window management, keybindings |
| **Terminal** | Kitty | GPU-accelerated terminal emulator |
| **Editor** | Neovim + 25+ plugins | Development IDE |
| **Automation** | 20+ Bash scripts, 3 Python daemons | System automation, recording, updates |
| **Services** | systemd user units | Background services (MPD-MPRIS) |

---

## 2. Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              USER SESSION                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐                 │
│  │   i3/Sway    │────▶│   Scripts    │────▶│   Services   │                 │
│  │   (WM IPC)   │     │  (bin/, WM)  │     │  (systemd)   │                 │
│  └──────┬───────┘     └──────┬───────┘     └──────────────┘                 │
│         │                    │                                               │
│         │ IPC Events         │ Exec                                          │
│         ▼                    ▼                                               │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐                 │
│  │   Python     │     │    Bash      │     │   Kitty      │                 │
│  │   Daemons    │     │   Scripts    │     │  Terminal    │                 │
│  │ (workspace,  │     │ (recording,  │     │  (tmux)      │                 │
│  │  autotiling) │     │  power, pkg) │     └──────┬───────┘                 │
│  └──────────────┘     └──────────────┘            │                         │
│                                                    │                         │
│  ┌──────────────────────────────────────────────────────────────────────────┐   │
│  │                          ZSH SESSION                                  │   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐    │   │
│  │  │ P10k    │  │Sheldon  │  │ FZF     │  │ Zoxide  │  │ FNM     │    │   │
│  │  │ Theme   │  │Plugins  │  │ Search  │  │ Nav     │  │ Node    │    │   │
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────┘  └─────────┘    │   │
│  │                                                                       │   │
│  │  ┌─────────────────────────────────────────────────────────────────┐ │   │
│  │  │                    CUSTOM FUNCTIONS                              │ │   │
│  │  │  update_clean()  extract()  cpprun()  cpp_debug()  gitUh()     │ │   │
│  │  └─────────────────────────────────────────────────────────────────┘ │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                           NEOVIM                                      │   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐    │   │
│  │  │ LSP     │  │Telescope│  │ DAP     │  │ Copilot │  │Conform  │    │   │
│  │  │ Server  │  │ Fuzzy   │  │ Debug   │  │ AI      │  │ Format  │    │   │
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────┘  └─────────┘    │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘

EXTERNAL DEPENDENCIES:
├── X11/Wayland Display Server
├── PulseAudio/PipeWire Audio
├── Intel VAAPI (Hardware Video Encoding)
├── NetworkManager, Blueman (Network/Bluetooth)
├── Pass (Password Store)
└── Git (Version Control)
```

---

## 3. Data Flow Analysis

### 3.1 Window Management Event Flow

```
Window Event (open/close/focus/move)
         │
         ▼
    ┌────────────┐
    │  i3/Sway   │
    │    IPC     │
    └─────┬──────┘
          │ UNIX Socket
          ▼
    ┌────────────────────┐
    │ workspace-names.py │
    │ alternating_layouts│
    └─────┬──────────────┘
          │ i3.command()
          ▼
    ┌────────────┐
    │ Rename WS  │──▶ i3bar Update
    │ Split Dir  │
    └────────────┘
```

### 3.2 Recording Pipeline

```
User Keybind ($mod+Ctrl+Shift+Print)
         │
         ▼
    ┌───────────────────────┐
    │ record-with-mic.sh    │
    └─────────┬─────────────┘
              │
    ┌─────────▼─────────┐
    │ Resolution Detect │
    │ xdpyinfo/xrandr   │
    └─────────┬─────────┘
              │
    ┌─────────▼─────────┐
    │ Audio Sink Detect │
    │ pactl             │
    └─────────┬─────────┘
              │
    ┌─────────▼─────────┐
    │ FFmpeg Process    │
    │ - x11grab         │
    │ - pulse (2 inputs)│
    │ - VAAPI h264      │
    │ - amix filter     │
    └─────────┬─────────┘
              │
    ┌─────────▼─────────┐
    │ PID File Storage  │
    │ /tmp/*.pid        │
    └─────────┬─────────┘
              │
              ▼
    ~/Videos/recordings/screen-mic-YYYYMMDD-HHMMSS.mkv
```

### 3.3 Shell Initialization Flow

```
Login Shell
     │
     ▼
┌─────────────┐
│  .zshenv    │──▶ XDG_* vars, PATH, ZDOTDIR
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  .zshrc     │
└──────┬──────┘
       │
       ├──▶ P10k Instant Prompt (cached)
       │
       ├──▶ compinit (24h cache check)
       │
       ├──▶ Sheldon Plugin Load
       │    ├── zsh-defer
       │    ├── P10k theme
       │    ├── autosuggestions
       │    ├── fzf-tab
       │    ├── syntax-highlighting
       │    └── OMZ plugins
       │
       ├──▶ FZF Integration
       │
       ├──▶ Vi-mode Setup
       │
       ├──▶ fnm (Node manager)
       │
       ├──▶ Source *.zsh files
       │    ├── aliases.zsh
       │    ├── upclean.zsh
       │    ├── extract.zsh
       │    ├── docker.zsh
       │    └── github.zsh
       │
       ├──▶ Zoxide Init
       │
       └──▶ P10k Theme Config
```

### 3.4 Terminal-in-Same-Directory Flow

```
Keybind ($mod+Shift+Return)
         │
         ▼
    ┌─────────────────────┐
    │ open-term-same-dir  │
    └─────────┬───────────┘
              │
    ┌─────────▼─────────┐
    │ xprop -root       │──▶ Active Window ID
    └─────────┬─────────┘
              │
    ┌─────────▼─────────┐
    │ xprop -id $win_id │──▶ _NET_WM_PID
    └─────────┬─────────┘
              │
    ┌─────────▼─────────┐
    │ pstree -lpATna    │──▶ Process Tree PIDs
    └─────────┬─────────┘
              │
    ┌─────────▼─────────┐
    │ for PID in tree:  │
    │  readlink /proc/  │
    │    $PID/cwd       │──▶ Working Directory
    └─────────┬─────────┘
              │
    ┌─────────▼─────────┐
    │ Filter Invalid:   │
    │  - lf server      │
    │  - git processes  │
    │  - $HOME or /     │
    └─────────┬─────────┘
              │
              ▼
    $TERMINAL --working-directory "$cwd"
```

---

## 4. Component Dependencies

### 4.1 Dependency Matrix

| Component | Hard Dependencies | Soft Dependencies | Optional |
|-----------|-------------------|-------------------|----------|
| **i3/Sway** | X11/Wayland, i3status-rs | picom, dunst | aw-qt, unclutter |
| **workspace-names.py** | python3, i3ipc | - | - |
| **record-with-mic.sh** | ffmpeg, pactl | notify-send | VAAPI driver |
| **open-term-same-dir** | xprop, readlink | pstree | - |
| **upclean.zsh** | pacman, yay, paccache | - | - |
| **tmux-sessionizer** | tmux, fzf | - | .tmux-sessionizer |
| **i3-tmux-launcher** | tmux, kitty, i3-msg | - | - |
| **Neovim** | nvim 0.9+ | gcc, node, ripgrep | JDTLS, rust-analyzer |
| **Zsh** | zsh, sheldon | fzf, zoxide, fnm | eza |

### 4.2 Inter-Module Dependencies

```
                    ┌─────────────┐
                    │   i3/Sway   │
                    │   Config    │
                    └──────┬──────┘
                           │
          ┌────────────────┼────────────────┐
          │                │                │
          ▼                ▼                ▼
    ┌───────────┐   ┌───────────┐   ┌───────────┐
    │  Scripts  │   │  Picom    │   │  Dunst    │
    │  (bin/)   │   │  (comp)   │   │  (notif)  │
    └─────┬─────┘   └───────────┘   └───────────┘
          │
    ┌─────┴─────┐
    │           │
    ▼           ▼
┌───────┐  ┌───────┐
│ Kitty │  │ Tmux  │
│       │◀─│       │
└───────┘  └───────┘
    │
    ▼
┌───────┐
│  Zsh  │
└───────┘
```

### 4.3 External System Calls

| Script | System Calls | IPC Mechanisms |
|--------|--------------|----------------|
| `workspace-names.py` | `i3.command()` | i3ipc UNIX socket |
| `record-with-mic.sh` | `pactl`, `ffmpeg`, `xdpyinfo` | DBUS (PulseAudio), X11 |
| `open-term-same-dir` | `xprop`, `ps`, `pstree` | X11, /proc filesystem |
| `i3-tmux-launcher` | `pgrep`, `tmux`, `i3-msg` | i3 IPC, tmux socket |
| `upclean.zsh` | `sudo`, `pacman`, `yay`, `paccache` | Pacman libalpm |
| `bg.sh` | `xwallpaper`/`swaymsg` | X11/Wayland IPC |

---

## 5. Hidden Complexity & Magic Values

### 5.1 Magic Numbers

| Location | Value | Purpose | Risk |
|----------|-------|---------|------|
| `record-with-mic.sh:84` | `-qp 20` | VAAPI quality parameter (0-51 scale) | Hardcoded, not tunable |
| `record-with-mic.sh:72` | `60` fps | Fixed framerate | May exceed hardware capability |
| `upclean.zsh:11` | `5242880` | 5MB log rotation threshold | Magic number, not documented |
| `.zshrc:29` | `1000000` | HISTSIZE | Arbitrary, could cause memory issues |
| `i3/config:43` | `20` | Gap size in pixels | Undocumented magic value |
| `picom.conf` | `10` | Corner radius | Hardcoded UI value |
| `workspace-names.py:9` | 100+ icon mappings | App-to-icon dictionary | Maintenance burden |

### 5.2 Unclear Logic

#### 5.2.1 `i3-tmux-launcher` - Process Tree Navigation
```bash
# Lines 30-43: Nested while loops with subprocess calls
TMUX_CLIENT_PID=$(ps --ppid "$KITTY_PID" -o pid= 2>/dev/null | while read child; do
    # Check direct children first
    if ps -p "$child" -o comm= 2>/dev/null | grep -q '^tmux'; then
      echo "$child"
      break
    fi
    # Check grandchildren (kitty -> shell -> tmux pattern)
    ps --ppid "$child" -o pid= 2>/dev/null | while read grandchild; do
      if ps -p "$grandchild" -o comm= 2>/dev/null | grep -q '^tmux'; then
        echo "$grandchild"
        break
      fi
    done
  done | head -n 1)
```
**Issue:** Three levels of nested loops with subprocess spawning per iteration. Intent is clear (find tmux under kitty) but execution is O(n²) in process count.

#### 5.2.2 `open-term-same-dir` - PID Filtering Logic
```bash
# Lines 61-64: Implicit filter rules
case "$cmdline" in
  'lf -server') continue ;;
  "${SHELL##*/}"|'lf'|'lf '*) break ;;
esac
```
**Issue:** `lf` is hardcoded twice. Why is `lf -server` skipped but `lf` stops the search? No documentation.

#### 5.2.3 `workspace-names.py` - Pango Markup in Python
```python
# Line 12-105: 100+ hardcoded XML spans
"firefox": "<span size='x-large' foreground='#fabd2f'> </span>",
```
**Issue:** Mixing data (icon mappings) with presentation (XML/Pango). Each color is a magic hex value. No theme support.

### 5.3 Implicit State

| Location | State | Storage | Lifetime |
|----------|-------|---------|----------|
| `record-with-mic.sh` | Recording PID + path | `/tmp/screen-record-mic.pid` | Until stop/reboot |
| `toggle-redshift.sh` | On/off state | `/tmp/.redshift_on` | Until reboot |
| `picom-toggle.sh` | Compositor running | Process existence | Session |
| `timer_control.sh` | Timer state | File-based | Persistent |
| `compinit` | Completion dump | `~/.cache/zcompdump` | 24 hours |
| `sheldon` | Plugin cache | `~/.local/share/sheldon` | Manual update |

---

## 6. Side Effects & State Management

### 6.1 File System Side Effects

| Script | Files Modified | Directories Created |
|--------|----------------|---------------------|
| `upclean.zsh` | `~/.local/state/upclean/update_history.log` | `~/.local/state/upclean/` |
| `record-with-mic.sh` | `~/Videos/recordings/*.mkv` | `~/Videos/recordings/` |
| `.zshrc` | `~/.cache/zcompdump`, `~/.cache/zsh_history` | - |
| `tmux-sessionizer` | `~/.config/tmux-sessionizer/tmux-sessionizer.conf` | Config dir |

### 6.2 Process Side Effects

| Action | Processes Spawned | Signal Handlers |
|--------|-------------------|-----------------|
| i3 startup | picom, dunst, workspace-names.py, alternating_layouts.py, clipmenud, aw-qt, unclutter, nm-applet, blueman-applet | - |
| Recording start | ffmpeg (background) | SIGINT → graceful stop |
| i3 exit | pkill clipmenud, picom, xsel | Cleanup chain |
| Zsh precmd | None | Hooks for history |

### 6.3 Environment Pollution

| Source | Variables Set | Scope |
|--------|---------------|-------|
| `.zshenv` | `XDG_*`, `EDITOR`, `BROWSER`, `PATH` | Global |
| `.zshrc` | `HISTFILE`, `FZF_DEFAULT_OPTS`, `KEYTIMEOUT` | Interactive |
| `fnm env` | `PATH`, `FNM_*` | Shell session |
| `zoxide init` | `_ZO_*`, `__zoxide_*` functions | Shell session |

### 6.4 Signal Handling

```bash
# record-with-mic.sh stop_record()
kill -INT "$PID" >/dev/null 2>&1 || kill -TERM "$PID" >/dev/null 2>&1 || true
```
**Pattern:** Try SIGINT first (graceful), fall back to SIGTERM. No SIGKILL escalation. May leave orphan processes.

### 6.5 Race Conditions

1. **`i3-tmux-launcher`**: Between `pgrep` and `i3-msg focus`, the window may have closed
2. **`record-with-mic.sh`**: Between `mkdir -p` and writing, directory may be deleted
3. **`compinit` caching**: Two shells starting simultaneously may both regenerate cache
4. **`workspace-names.py`**: Event handler may process stale tree after rapid window operations

---

## Appendix A: File Inventory

```
config/
├── bin/                    # 9 executable scripts
│   ├── i3-tmux-launcher   # 67 lines
│   ├── tmux-sessionizer   # 173 lines
│   ├── open-term-same-dir # 109 lines
│   └── ...
├── i3/
│   ├── config             # 196 lines
│   ├── config.d/          # 13 modular configs
│   └── scripts/           # 12 scripts (Python + Bash)
├── sway/
│   ├── config             # Main config
│   ├── config.d/          # 7 modular configs
│   └── scripts/           # 3 scripts
├── zsh/
│   ├── .zshrc             # 111 lines
│   ├── .zshenv            # Environment
│   ├── aliases.zsh        # 104 lines
│   └── *.zsh              # 10+ helper files
├── nvim/
│   ├── init.lua           # ~1000 lines (estimated)
│   └── lua/               # Plugin configs
├── kitty/                  # Terminal config
├── dunst/                  # Notification config
├── picom/                  # Compositor config
└── systemd/                # User services
```

---

## Appendix B: Technology Stack

| Category | Technology | Version Requirement |
|----------|------------|---------------------|
| OS | Arch Linux | Rolling |
| Shell | Zsh | 5.9+ |
| WM (X11) | i3-gaps | 4.22+ |
| WM (Wayland) | Sway | 1.8+ |
| Terminal | Kitty | 0.31+ |
| Editor | Neovim | 0.9+ |
| Plugin Manager (Zsh) | Sheldon | 0.7+ |
| Plugin Manager (Nvim) | lazy.nvim | Built-in |
| Theme | Catppuccin / Gruvbox | - |
| Font | JetBrainsMono Nerd Font | 3.0+ |
