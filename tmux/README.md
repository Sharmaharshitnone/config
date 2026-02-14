# tmux Configuration — Cheatsheet & Reference

> Prefix: **`C-a`** (Ctrl+a), or just tap **Right Alt** once (keyd remaps it to C-a).

---

## 1. Sessions

| Action | Keys | Notes |
|---|---|---|
| New session | `prefix S` | Prompts for name |
| Rename session | `prefix R` | Pre-fills current name |
| Kill session | `prefix X` | Confirms before killing |
| Switch session | `prefix C-s` | Tree view (zoom) |
| Detach | `prefix d` | Leave session running |
| Last session | `prefix )` / `prefix (` | Cycle next/prev |
| Sessionizer | `prefix f` | fzf project picker → auto-creates/attaches |
| List sessions | `tmux ls` | From shell |

### Sessionizer Workflow

`prefix f` opens `tmux-sessionizer`: an fzf picker over your project dirs.
Pick a project → tmux creates (or switches to) a session named after that project.
This is the **fastest** way to context-switch between projects.

```
# How it works internally:
1. fzf scans ~/work, ~/projects, etc.
2. You pick a directory
3. tmux new-session -s <dirname> -c <path>  (or switch if exists)
```

---

## 2. Windows (Tabs)

| Action | Keys | Notes |
|---|---|---|
| New window | `prefix c` | Opens in current path |
| Kill window | `prefix &` | Confirms |
| Next window | `prefix ]` | Repeatable (`-r`) |
| Prev window | `prefix [` | Repeatable |
| Last window | `prefix Tab` | **Quick toggle** between 2 windows |
| Go to window N | `prefix 1-9` | Direct jump |
| Rename window | `prefix ,` | Change tab name |
| Move window left | `prefix <` | Swap with previous position |
| Move window right | `prefix >` | Swap with next position |

**Pro tip:** `prefix Tab` is the single most useful bind — it's Alt-Tab for tmux.

---

## 3. Panes (Splits)

| Action | Keys | Notes |
|---|---|---|
| Split horizontal | `prefix \|` | Side by side (preserves path) |
| Split vertical | `prefix -` | Top/bottom (preserves path) |
| Kill pane | `prefix x` | No confirmation |
| Navigate | `prefix h/j/k/l` | Vim-style |
| Resize 5 cells | `prefix H/J/K/L` | Repeatable (hold prefix once) |
| Zoom toggle | `prefix z` | Fullscreen one pane, press again to restore |
| Break pane → window | `prefix b` | Detaches pane into its own window |
| Merge pane | `prefix m` | Prompts for source window, joins it here |

### Repeatable Keys (`-r` flag)

When a key is repeatable, you press prefix **once**, then hit the key multiple times within 500ms:
```
prefix H H H H    →  resize left 20 cells (5 × 4)
prefix ] ] ] ]     →  skip 4 windows forward
```

---

## 4. Copy Mode (vi)

Enter copy mode: `prefix [` (then you're in vi-navigation)

| Action | Keys | Notes |
|---|---|---|
| Enter copy mode | `prefix [` | Scrollback buffer |
| Start selection | `v` | Like vi visual mode |
| Rectangle select | `C-v` | Block selection |
| Copy to clipboard | `y` | Uses xclip, exits copy mode |
| Search forward | `/` | Regex search |
| Search backward | `?` | Regex search |
| Page up/down | `C-u` / `C-d` | Half-page scroll |
| Go to top | `g` | Beginning of scrollback |
| Go to bottom | `G` | End of scrollback |
| Quit copy mode | `q` or `Escape` | |

**Pro tip:** `history-limit` is set to 50,000 lines. You can scroll back very far.

---

## 5. Session Management Patterns

### Pattern 1: Project-Per-Session
```bash
# Create a session per project
tmux new -s dotfiles -c ~/work/config
tmux new -s rust-proj -c ~/work/rust/myproject

# Switch between them
prefix C-s    # tree picker
prefix f      # sessionizer (fzf)
```

### Pattern 2: Scratchpad Session
Your i3 config creates a persistent `scratchpad` tmux session with tools:
- `$mod+o m` → rmpc (music)
- `$mod+o n` → nvtop (GPU monitor)
- `$mod+o y` → yazi (file manager)

These run as windows in a single tmux session, toggled via i3 scratchpad.

### Pattern 3: Development Layout
```bash
# Typical dev workflow in one session:
# Window 1: nvim (editor)
# Window 2: build/run (split into 2 panes)
# Window 3: git (lazygit)
# Window 4: misc shell

prefix c          # new window
prefix |          # split for build + run
prefix -          # add another pane for logs
```

---

## 6. keyd Integration

Your keyd config makes tmux ergonomic:

| Physical Keys | What Happens | Result |
|---|---|---|
| `Right Alt` + `c` | Sends `C-a c` | New tmux window |
| `Right Alt` + `-` | Sends `C-a -` | Vertical split |
| `Right Alt` + `\|` | Sends `C-a \|` | Horizontal split |
| `Right Alt` + `h` | Sends `C-a h` | Focus pane left |
| `Right Alt` + `Tab` | Sends `C-a Tab` | Last window |
| `Right Alt` + `f` | Sends `C-a f` | Sessionizer |

**You never need to physically press `Ctrl+a`.** Right Alt alone sends the prefix.

---

## 7. Plugins

| Plugin | Purpose |
|---|---|
| `tpm` | Plugin manager. `prefix I` to install, `prefix U` to update |
| `tmux-sensible` | Sane defaults (utf8, history, escape-time, etc.) |
| `tmux-yank` | System clipboard integration for copy mode |
| `tmux-fzf` | `prefix F` → fzf interface for sessions/windows/panes |

### Installing Plugins
```bash
# First time setup:
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Then inside tmux:
prefix I    # Install all plugins listed in .tmux.conf
prefix U    # Update all plugins
```

---

## 8. Quick Command Reference

```bash
# Outside tmux
tmux                        # Start new session
tmux new -s name            # Named session
tmux attach -t name         # Reattach
tmux ls                     # List sessions
tmux kill-session -t name   # Kill specific session
tmux kill-server            # Nuclear option

# Inside tmux (prefix required)
:new-window -n build        # Named window via command mode
:swap-pane -D               # Swap pane downward
:select-layout even-horizontal  # Equalize pane widths
:select-layout tiled        # Grid layout
:setw synchronize-panes on  # Type in ALL panes simultaneously
```

---

## 9. Status Bar Layout

```
┌─────────────────────────────────────────────────────────────┐
│  session_name          1:zsh  2:nvim  3:build     12:34 │
└─────────────────────────────────────────────────────────────┘
 ↑ left (#S)             ↑ windows (right-justified)    ↑ clock
 gray #888888            dim=#666666 / active=#d4d4d4   gray
```

Transparent background (`bg=default`) — inherits from kitty's 80% opacity + picom blur.

---

## 10. Muscle Memory Drills

Practice these 5 combos until they're instant:

1. **Split + navigate:** `prefix |` → `prefix l` → `prefix h` (split, move right, move left)
2. **Window cycling:** `prefix c` → `prefix c` → `prefix Tab` (create 2, toggle between them)
3. **Resize flow:** `prefix H H H` (resize left 15 cells — repeatable)
4. **Copy text:** `prefix [` → navigate → `v` → move → `y` (enter copy, select, yank)
5. **Session switch:** `prefix f` → pick project (the sessionizer workflow)

---
