# Deep Technical Audit: bin Scripts

**Audit Date:** 2026-01-31  
**Auditor Role:** Principal System Architect  
**Repository:** Sharmaharshitnone/config  

---

## Phase 1: Deep Documentation

---

### 1. Architecture Overview

These nine shell scripts are user-facing utilities for an Arch Linux/i3wm desktop environment. They handle:
- **Terminal session management** (tmux integration)
- **Package management** (pacman/yay wrappers)
- **Clipboard/input automation** (character picker)
- **File browsing** (image viewer integration)

#### Data Flow Diagram

```
┌──────────────────────────────────────────────────────────────────────┐
│                          USER INPUT                                   │
└─────────┬───────────────────────┬─────────────────────────┬──────────┘
          │                       │                         │
          ▼                       ▼                         ▼
┌─────────────────┐   ┌───────────────────┐    ┌───────────────────────┐
│  charpicker     │   │ tmux-sessionizer  │    │  pacman-fzf-install   │
│  chars (data)   │   │ i3-tmux-launcher  │    │  yay-fzf-install      │
│                 │   │                   │    │  yay-fzf-remove       │
└────────┬────────┘   └─────────┬─────────┘    └───────────┬───────────┘
         │                      │                          │
         ▼                      ▼                          ▼
┌─────────────────┐   ┌───────────────────┐    ┌───────────────────────┐
│  fzf (picker)   │   │ tmux (sessions)   │    │ fzf → pacman/yay      │
│  xsel/xdotool   │   │ kitty (terminal)  │    │ (sudo escalation)     │
└────────┬────────┘   └─────────┬─────────┘    └───────────┬───────────┘
         │                      │                          │
         ▼                      ▼                          ▼
┌─────────────────┐   ┌───────────────────┐    ┌───────────────────────┐
│  Clipboard      │   │  i3wm (window     │    │ System packages       │
│  (X selection)  │   │  focus/switch)    │    │ (filesystem changes)  │
└─────────────────┘   └───────────────────┘    └───────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│                     AUXILIARY SCRIPTS                                 │
├─────────────────────────────┬────────────────────────────────────────┤
│  nsxiv-thunar               │  open-term-same-dir                    │
│  - File manager → nsxiv     │  - Window PID → cwd → new terminal     │
│  - Image rotation logic     │  - pstree traversal                    │
└─────────────────────────────┴────────────────────────────────────────┘
```

---

### 2. Script-by-Script Analysis

---

#### 2.1 `charpicker`

**Purpose:** Emoji/character picker that copies to clipboard or types via xdotool.

**Data Flow:**
```
$HOME/.local/bin/chars/emoji → fzf → sed → xsel (clipboard) OR xdotool (type)
```

**External Dependencies:**
| Dependency | Type | Failure Mode |
|------------|------|--------------|
| fzf | Required | Hard exit on cancel |
| xsel | Optional (copy mode) | Silent failure |
| xdotool | Optional (type mode) | Silent failure |
| notify-send | Optional | Silent failure |

**Hidden Complexity:**
- **Magic Path:** `$HOME/.local/bin/chars/emoji` is hardcoded. No validation that file exists.
- **sed Pattern:** `s/ .*//` assumes emoji is first token followed by space. Breaks on multi-codepoint emoji.

---

#### 2.2 `chars`

**Purpose:** Data directory containing emoji file.

**Note:** This is a directory with a single file named `emoji`. It is a data source, not executable logic.

---

#### 2.3 `i3-tmux-launcher`

**Purpose:** Launch or attach to tmux sessions in a dedicated kitty window, with session reuse.

**Data Flow:**
```
Arguments ($1: session, $2: dir, $3: cmd)
    │
    ▼
Check tmux session exists → if not: tmux new-session -d
    │
    ▼
pgrep for "kitty --class main-tmux" → get KITTY_PID
    │
    ▼
If kitty running:
    ├─► i3-msg focus the window
    └─► ps traversal to find tmux client PID
            │
            ▼
        Get TTY from tmux client → tmux switch-client -c $TTY -t $SESSION
                │
                ▼ (fallback)
        Launch new kitty with tmux attach
Else:
    └─► setsid kitty --class main-tmux tmux attach
```

**External Dependencies:**
| Dependency | Type | Critical |
|------------|------|----------|
| tmux | Required | Yes |
| kitty | Required | Yes |
| i3-msg | Required | Yes |
| pgrep | Required | Yes |
| ps | Required | Yes |

**Hidden Complexity:**

1. **Process Tree Traversal (Lines 30-43):**
   ```bash
   TMUX_CLIENT_PID=$(ps --ppid "$KITTY_PID" -o pid= 2>/dev/null | while read child; do
   ```
   - This nested loop is O(n²) in the worst case (many processes under kitty).
   - Uses subshell pipeline which cannot `break` properly to outer scope.
   - The inner `while read` creates a subshell, so `echo "$child"` writes to pipe, but the outer `break` only exits the inner loop.

2. **Magic Window Class:** `main-tmux` is hardcoded in 4 places. Should be a constant.

3. **Race Condition:** Between `pgrep` and `ps --ppid`, the kitty process could die, causing silent failures.

4. **Fallback Cascade:** Three identical fallback paths (lines 53, 57, 61, 66) violate DRY.

---

#### 2.4 `nsxiv-thunar`

**Purpose:** Open images in nsxiv from Thunar file manager, rotating directory contents to start at selected file.

**Data Flow:**
```
Arguments ($@: files)
    │
    ▼
If single file:
    ├─► cd to file's directory
    ├─► find all image files (hardcoded extensions)
    ├─► awk rotation logic
    └─► pipe absolute paths to nsxiv -i
Else:
    └─► exec nsxiv $@
```

**External Dependencies:**
| Dependency | Type | Critical |
|------------|------|----------|
| nsxiv | Required | Yes |
| find | Required | Yes |
| awk | Required | Yes |
| sort | Required | Yes |

**Hidden Complexity:**

1. **Image Extensions (Line 32):** Hardcoded list misses:
   - `.svg` (vector)
   - `.avif` (modern format)
   - `.heic` / `.heif` (Apple format)
   - Case sensitivity handled by `-iname`

2. **Rotation AWK (Lines 40-59):** 
   - Complex state machine in awk. If `BASE` file not found, outputs `buf` anyway (entire list).
   - Edge case: If filename contains special awk characters (e.g., `[`, `]`), comparison `$0 == BASE` may fail.

3. **Unused ROTDIR:** Line 8 defines `ROTDIR="$HOME/.local/bin/rotdir"` but never uses it.

4. **find -printf:** Not POSIX-compliant. Will break on BSD systems.

---

#### 2.5 `open-term-same-dir`

**Purpose:** Open terminal in same directory as focused window.

**Data Flow:**
```
xprop -root → get _NET_ACTIVE_WINDOW
    │
    ▼
xprop -id → get _NET_WM_PID
    │
    ▼
pstree -lpATna → extract all descendant PIDs
    │
    ▼
For each PID (reversed/tac):
    ├─► Skip known patterns (lf -server, git)
    ├─► readlink /proc/$PID/cwd
    ├─► Validate cwd exists and is not ~ or /
    └─► Break on first valid
    │
    ▼
Open terminal with --working-directory
```

**External Dependencies:**
| Dependency | Type | Critical |
|------------|------|----------|
| xprop | Required | Yes |
| pstree | Optional | Fallback to single PID |
| ps | Required | Yes |
| readlink | Required | Yes |
| Terminal (any) | Required | Yes |

**Hidden Complexity:**

1. **pstree Output Parsing (Line 42):**
   ```bash
   PIDlist=$(pstree -lpATna "$win_pid" 2>/dev/null | sed -En 's/.*,([0-9]+).*/\1/p' | tac || true)
   ```
   - Fragile regex. Assumes pstree outputs `,PID` format. Different pstree versions may vary.

2. **Hardcoded Skip Patterns (Lines 61-63):**
   ```bash
   case "$cmdline" in
     'lf -server') continue ;;
   ```
   - `lf` file manager specific. Poorly documented why.

3. **Terminal Detection Loop (Lines 10-16):** O(n) iteration through terminal list on every invocation.

4. **X11-Only:** Won't work on Wayland. No `wlroots` or `sway` support path.

---

#### 2.6 `pacman-fzf-install`

**Purpose:** Interactive pacman package installer with fzf multi-select.

**Data Flow:**
```
pacman -Slq (list all sync packages)
    │
    ▼
fzf (multi-select with preview: pacman -Si)
    │
    ▼
mapfile to array
    │
    ▼
sudo pacman -S --needed "${pkg_array[@]}"
```

**External Dependencies:**
| Dependency | Type | Critical |
|------------|------|----------|
| pacman | Required | Yes |
| fzf | Required | Yes |
| sudo | Required | Yes |

**Hidden Complexity:**

1. **Blocking I/O (Line 36):**
   ```bash
   selected_packages=$(pacman -Slq | fzf "${fzf_args[@]}")
   ```
   - `pacman -Slq` is synchronous and can take several seconds on slow mirrors or large repos.
   - No spinner/loading indication beyond the echo on line 35.

2. **No Input Sanitization:** Package names piped directly to sudo command. While pacman itself validates, there's no shell-level escaping.

---

#### 2.7 `tmux-sessionizer`

**Purpose:** Fuzzy directory picker that creates/attaches tmux sessions.

**Data Flow:**
```
Config: ~/.config/tmux-sessionizer/tmux-sessionizer.conf
    │
    ▼
Parse TS_SEARCH_PATHS, TS_EXTRA_SEARCH_PATHS, TS_MAX_DEPTH
    │
    ▼
find_dirs():
    ├─► List existing tmux sessions
    └─► For each path in TS_SEARCH_PATHS:
            find -mindepth 1 -maxdepth $depth -type d
    │
    ▼
fzf selection → session_name = basename | tr . _
    │
    ▼
tmux new-session -ds "$selected_name" -c "$selected"
    │
    ▼
hydrate() → source .tmux-sessionizer if exists
    │
    ▼
switch_to() → attach or switch-client
```

**External Dependencies:**
| Dependency | Type | Critical |
|------------|------|----------|
| tmux | Required | Yes |
| fzf | Required | Yes |
| find | Required | Yes |
| basename | Required | Yes |

**Hidden Complexity:**

1. **Config Sourcing (Line 21):**
   ```bash
   source "$CONFIG_FILE"
   ```
   - **Code Injection Risk:** If config file contains malicious code, it runs with user privileges.
   - No validation of config file contents.

2. **has_session Grep Pattern (Lines 81-83):**
   ```bash
   tmux list-sessions | grep -q "^$1:"
   ```
   - If `$1` contains regex metacharacters (e.g., `.`, `*`), grep may match unintended sessions.

3. **Path Depth Parsing (Lines 126-131):**
   ```bash
   if [[ "$entry" =~ ^([^:]+):([0-9]+)$ ]]; then
   ```
   - Paths with colons (valid on Unix) will be parsed incorrectly (e.g., network paths).

4. **Hydrate Function (Lines 85-96):**
   - `c-M` is sent to execute command. If `tmux send-keys` fails (session died), no error handling.
   - `[[ ! -z $workspace ]]` should be `[[ -n $workspace ]]` for clarity.

5. **Duplicate Session Creation (Lines 162-170):**
   ```bash
   if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
       tmux new-session -ds "$selected_name" -c "$selected"
       hydrate "$selected_name" "$selected"
   fi

   if ! has_session "$selected_name"; then
       tmux new-session -ds "$selected_name" -c "$selected"
       hydrate "$selected_name" "$selected"
   fi
   ```
   - Creates session twice in some cases (first block creates, second block re-checks). Redundant.

---

#### 2.8 `yay-fzf-install`

**Purpose:** Interactive AUR package installer with fzf.

**Data Flow:** (Same pattern as pacman-fzf-install)
```
yay -Slqa → fzf → mapfile → yay -S --needed
```

**Hidden Complexity:**

1. **updatedb Call (Lines 56-58):**
   ```bash
   if command -v updatedb >/dev/null 2>&1; then
       sudo updatedb
   ```
   - Unexpected side effect. Installing a package shouldn't update locate database.
   - Runs with sudo, extending privilege scope.

2. **PKGBUILD Preview (Line 33):**
   ```bash
   --bind 'alt-b:change-preview:yay -Gp {1} | bat ...'
   ```
   - `yay -Gp` downloads PKGBUILD on every preview toggle. Network I/O in preview is slow and may rate-limit.

---

#### 2.9 `yay-fzf-remove`

**Purpose:** Interactive package removal with fzf.

**Data Flow:**
```
yay -Qqe (list explicitly installed) → fzf → mapfile → yay -Rns
```

**Hidden Complexity:**

1. **Dangerous Default:** `-Rns` recursively removes dependencies. Could break system if user removes core package.

2. **No Confirmation Override:** Relies entirely on yay's prompt. Script provides no additional safeguard.

---

### 3. Dependency Matrix

| Script | tmux | fzf | pacman | yay | xdotool | xsel | kitty | i3 | X11 |
|--------|------|-----|--------|-----|---------|------|-------|-----|-----|
| charpicker | | ✓ | | | ○ | ○ | | | ✓ |
| i3-tmux-launcher | ✓ | | | | | | ✓ | ✓ | ✓ |
| nsxiv-thunar | | | | | | | | | |
| open-term-same-dir | | | | | | | | | ✓ |
| pacman-fzf-install | | ✓ | ✓ | | | | | | |
| tmux-sessionizer | ✓ | ✓ | | | | | | | |
| yay-fzf-install | | ✓ | | ✓ | | | | | |
| yay-fzf-remove | | ✓ | | ✓ | | | | | |

✓ = Required, ○ = Optional

---

## Phase 2: Gap Analysis & Optimization

---

### 1. Performance Issues

#### 1.1 O(n²) Process Tree Traversal in `i3-tmux-launcher` (CRITICAL)

**Location:** Lines 30-43

**Problem:**
```bash
TMUX_CLIENT_PID=$(ps --ppid "$KITTY_PID" -o pid= 2>/dev/null | while read child; do
  if ps -p "$child" -o comm= 2>/dev/null | grep -q '^tmux'; then
    echo "$child"; break
  fi
  ps --ppid "$child" -o pid= 2>/dev/null | while read grandchild; do
    if ps -p "$grandchild" -o comm= 2>/dev/null | grep -q '^tmux'; then
      echo "$grandchild"; break
    fi
  done
done | head -n 1)
```

- Spawns `ps` 3-4 times per process in the tree.
- Nested loops iterate all children, then all grandchildren.
- Subshell pipelines prevent early exit.

**Fix:** Single `pstree` call with parsing:

```bash
# O(1) process spawns instead of O(n²)
find_tmux_client() {
    local kitty_pid="$1"
    local tmux_pid
    
    # Get all descendants in one call, find first tmux
    tmux_pid=$(pstree -pTA "$kitty_pid" 2>/dev/null | 
               grep -oP 'tmux[^)]*\(\K[0-9]+' | 
               head -n 1)
    
    [[ -n "$tmux_pid" ]] && echo "$tmux_pid"
}
```

---

#### 1.2 Blocking `pacman -Slq` Without Caching (MODERATE)

**Location:** `pacman-fzf-install` line 36

**Problem:** Every invocation queries sync database. On slow mirrors: 2-5 second delay.

**Fix:** Cache with expiry:

```bash
CACHE_FILE="/tmp/pacman-pkg-cache-$(id -u)"
CACHE_EXPIRY=300  # 5 minutes

if [[ -f "$CACHE_FILE" ]] && 
   [[ $(($(date +%s) - $(stat -c %Y "$CACHE_FILE"))) -lt $CACHE_EXPIRY ]]; then
    selected_packages=$(fzf "${fzf_args[@]}" < "$CACHE_FILE")
else
    pacman -Slq > "$CACHE_FILE"
    selected_packages=$(fzf "${fzf_args[@]}" < "$CACHE_FILE")
fi
```

---

#### 1.3 Redundant `find` Invocations in `tmux-sessionizer` (MODERATE)

**Location:** Lines 124-134

**Problem:** Iterates `TS_SEARCH_PATHS` sequentially. Each `find` is a separate process.

**Fix:** Aggregate paths for single `find` call (where depths are same):

```bash
# Group paths by depth, then batch find
declare -A depth_paths
for entry in "${TS_SEARCH_PATHS[@]}"; do
    if [[ "$entry" =~ ^([^:]+):([0-9]+)$ ]]; then
        path="${BASH_REMATCH[1]}"
        depth="${BASH_REMATCH[2]}"
    else
        path="$entry"
        depth="${TS_MAX_DEPTH:-1}"
    fi
    [[ -d "$path" ]] && depth_paths[$depth]+="$path "
done

for depth in "${!depth_paths[@]}"; do
    # shellcheck disable=SC2086
    find ${depth_paths[$depth]} -mindepth 1 -maxdepth "$depth" \
         -path '*/.git' -prune -o -type d -print 2>/dev/null
done
```

---

### 2. Safety Issues

#### 2.1 Config File Code Injection in `tmux-sessionizer` (CRITICAL)

**Location:** Line 21

```bash
source "$CONFIG_FILE"
```

**Problem:** Arbitrary code execution if config file is compromised or misconfigured.

**Fix:** Validate config content or use safer parsing:

```bash
# Safer: only allow specific variable assignments
if [[ -f "$CONFIG_FILE" ]]; then
    # Parse known variables only
    while IFS='=' read -r key value; do
        # Strip comments and whitespace
        key="${key%%#*}"
        key="${key// /}"
        case "$key" in
            TS_SEARCH_PATHS|TS_EXTRA_SEARCH_PATHS|TS_MAX_DEPTH|TS_WORKSPACE_COMMAND)
                # Validate value doesn't contain command substitution
                if [[ "$value" =~ [\$\`] ]]; then
                    echo "Warning: Suspicious value in config for $key, skipping" >&2
                    continue
                fi
                declare "$key=$value"
                ;;
        esac
    done < "$CONFIG_FILE"
fi
```

**Alternative:** Use a declarative config format (TOML/INI) with a parser.

---

#### 2.2 Regex Injection in `has_session` (MODERATE)

**Location:** `tmux-sessionizer` line 82

```bash
tmux list-sessions | grep -q "^$1:"
```

**Problem:** Session name with regex metacharacters (`.`, `*`, `[`) causes false matches.

**Fix:** Use `grep -F` (fixed string) or escape:

```bash
has_session() {
    # Use tmux built-in check instead of grep
    tmux has-session -t "=$1" 2>/dev/null
}
```

The `=` prefix forces exact match in tmux.

---

#### 2.3 Race Condition in `i3-tmux-launcher` (MODERATE)

**Location:** Lines 22-26

**Problem:**
```bash
KITTY_PID=$(pgrep -f "kitty --class main-tmux" | head -n 1)
if [[ -n "$KITTY_PID" ]]; then
  # ... kitty could die between pgrep and ps
```

**Fix:** Validate PID before use:

```bash
KITTY_PID=$(pgrep -f "kitty --class main-tmux" | head -n 1)
if [[ -n "$KITTY_PID" ]] && kill -0 "$KITTY_PID" 2>/dev/null; then
    # Process still exists
```

---

#### 2.4 Unsafe Temporary File in Package Cache (LOW)

**Location:** Proposed cache fix for `pacman-fzf-install`

**Problem:** `/tmp/pacman-pkg-cache-*` could be symlink attacked.

**Fix:** Use `mktemp` with proper permissions:

```bash
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/pacman-fzf"
mkdir -p "$CACHE_DIR"
chmod 700 "$CACHE_DIR"
CACHE_FILE="$CACHE_DIR/pkg-cache"
```

---

### 3. Refactoring Recommendations

#### 3.1 Extract Common Pattern: FZF Package Installer (Strategy Pattern)

**Problem:** `pacman-fzf-install`, `yay-fzf-install`, `yay-fzf-remove` share 80% code.

**Solution:** Create abstract installer with strategy:

```bash
#!/bin/bash
# pkg-fzf-base: Base library for package management

# Source this, then define:
#   PKG_COMMAND - The package manager command (pacman, yay)
#   PKG_LIST_CMD - Command to list packages
#   PKG_ACTION_CMD - Command to run on selection (e.g., "-S", "-Rns")
#   PKG_COLORS - fzf color scheme
#   PKG_PROMPT - fzf prompt text

source_pkg_base() {
    # Colors
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    YELLOW='\033[1;33m'
    BOLD='\033[1m'
    RESET='\033[0m'

    # Check dependencies
    for cmd in "$PKG_COMMAND" fzf; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo -e "${RED}${BOLD}Error:${RESET} $cmd is required but not installed."
            exit 1
        fi
    done
}

run_pkg_selection() {
    local fzf_args=(
        --multi
        --preview "$PKG_PREVIEW_CMD"
        --preview-window 'down:65%:wrap'
        --bind 'alt-p:toggle-preview'
        --color "$PKG_COLORS"
        --prompt "$PKG_PROMPT"
    )

    echo -e "${BLUE}${BOLD}::${RESET} $PKG_LOADING_MSG"
    local selected
    selected=$($PKG_LIST_CMD | fzf "${fzf_args[@]}")

    if [[ -n "$selected" ]]; then
        local -a pkg_array
        mapfile -t pkg_array <<< "$selected"
        
        echo -e "\n${BLUE}${BOLD}::${RESET} Running: $PKG_COMMAND $PKG_ACTION_CMD ${pkg_array[*]}"
        
        if $PKG_COMMAND $PKG_ACTION_CMD "${pkg_array[@]}"; then
            echo -e "\n${GREEN}${BOLD}✓ Complete.${RESET}"
        else
            echo -e "\n${RED}${BOLD}✗ Failed or cancelled.${RESET}"
        fi
        
        echo -e "\n${BLUE}Press any key to exit...${RESET}"
        read -n 1 -s -r
    fi
}
```

Then `pacman-fzf-install` becomes:

```bash
#!/bin/bash
PKG_COMMAND="sudo pacman"
PKG_LIST_CMD="pacman -Slq"
PKG_ACTION_CMD="-S --needed --color=always"
PKG_PREVIEW_CMD="pacman -Si {1}"
PKG_COLORS="fg+:blue,bg+:black,hl:yellow,pointer:green"
PKG_PROMPT="Select packages > "
PKG_LOADING_MSG="Loading package list from repositories..."

source "${0%/*}/pkg-fzf-base"
source_pkg_base
run_pkg_selection
```

---

#### 3.2 Constants Extraction in `i3-tmux-launcher`

**Problem:** Magic string `main-tmux` repeated 4 times.

**Fix:**

```bash
readonly KITTY_CLASS="main-tmux"
readonly TERMINAL_CMD="kitty --class $KITTY_CLASS"

# Then use $TERMINAL_CMD everywhere
```

---

#### 3.3 Error Handling: Fail-Fast Pattern

**Problem:** Most scripts silently ignore errors in subcommands.

**Fix:** Add at script top:

```bash
set -euo pipefail
trap 'echo "Error at line $LINENO" >&2' ERR
```

And handle expected failures explicitly:

```bash
if ! output=$(command 2>&1); then
    echo "Command failed: $output" >&2
    exit 1
fi
```

---

### 4. Missing Tests & Unhandled Edge Cases

#### 4.1 `charpicker`

| Edge Case | Current Behavior | Expected Behavior |
|-----------|------------------|-------------------|
| Emoji file missing | `fzf` shows empty, unclear error | Exit with "Emoji file not found: $path" |
| Multi-codepoint emoji (e.g., 👨‍👩‍👧) | `sed "s/ .*//"` truncates | Use tab delimiter or JSON format |
| No X display ($DISPLAY unset) | xsel/xdotool fail silently | Check $DISPLAY, error if unset |
| fzf cancelled (Ctrl-C) | Exit 0 | Already handled, but no message |

---

#### 4.2 `i3-tmux-launcher`

| Edge Case | Current Behavior | Expected Behavior |
|-----------|------------------|-------------------|
| Directory doesn't exist | tmux creates session in `~` | Validate directory, exit with error |
| Session name with spaces | Undefined behavior | Quote properly or sanitize |
| tmux not running | Works | Works |
| Multiple kitty instances | First one wins | Document behavior or allow selection |
| Kitty dies mid-script | Fallback to new kitty | Correct |

---

#### 4.3 `nsxiv-thunar`

| Edge Case | Current Behavior | Expected Behavior |
|-----------|------------------|-------------------|
| Filename with spaces | Works (quoted) | Works |
| Filename with newlines | Breaks (find output parsing) | Use `find -print0` and `while read -d ''` |
| Filename with awk special chars `[`, `]` | awk comparison fails | Escape or use different approach |
| Non-image file passed | Opens in nsxiv (may fail) | Check file type first |
| Directory passed | `find` searches it, weird behavior | Validate file type |
| Symlinked images | Works | Works |
| `.WEBP` (uppercase) | Works (`-iname`) | Works |

---

#### 4.4 `open-term-same-dir`

| Edge Case | Current Behavior | Expected Behavior |
|-----------|------------------|-------------------|
| No active window | Falls through to `exec $TERMINAL` | Correct |
| Window without `_NET_WM_PID` | Falls through | Correct |
| Process with deleted cwd | `readlink` returns `(deleted)` | Check if cwd valid before use |
| Very deep process tree | Works but slow | Add depth limit |
| Wayland session | Fails silently | Error: "X11 only, use swaymsg for Wayland" |

---

#### 4.5 `tmux-sessionizer`

| Edge Case | Current Behavior | Expected Behavior |
|-----------|------------------|-------------------|
| Config has syntax error | Bash error, unclear | Wrap source in subshell, catch error |
| Path with `:` in name | Splits incorrectly | Use different delimiter or escape |
| Session already exists | Skips creation | Correct |
| Session name collision | Overwrites | Warn user |
| TS_SEARCH_PATHS path doesn't exist | `find` error (suppressed?) | Skip with warning |
| Empty fzf selection | Exit 0 | Correct |
| `.tmux-sessionizer` has error | Shell error in session | Validate before sourcing |

---

#### 4.6 Package Manager Scripts

| Edge Case | Current Behavior | Expected Behavior |
|-----------|------------------|-------------------|
| No packages selected | Exit | Correct |
| Package name with special chars | Passed to pacman | Pacman handles it |
| Network failure during preview | fzf preview shows error | Acceptable |
| sudo password wrong | pacman fails, script continues | Acceptable (pacman handles) |
| `yay -Rns` on essential package | Yay prompts | Add extra warning |
| Running as root | Works | Warn: "Don't run as root" |

---

### 5. Priority Matrix

| Issue | Impact | Effort | Priority |
|-------|--------|--------|----------|
| O(n²) process traversal in i3-tmux-launcher | High (perf) | Low | **P0** |
| Config file code injection in tmux-sessionizer | High (security) | Medium | **P0** |
| Regex injection in has_session | Medium (correctness) | Low | **P1** |
| DRY violation in package scripts | Medium (maintainability) | Medium | **P1** |
| Hardcoded paths/constants | Low (maintainability) | Low | **P2** |
| Missing image formats in nsxiv-thunar | Low (feature) | Low | **P2** |
| Wayland support in open-term-same-dir | Low (compat) | High | **P3** |

---

### 6. Proposed Refactored File Structure

```
bin/
├── lib/
│   ├── colors.sh        # Shared color definitions
│   ├── fzf-pkg-base.sh  # Package manager base (Strategy)
│   └── process-utils.sh # Process tree utilities
├── charpicker
├── i3-tmux-launcher
├── nsxiv-thunar
├── open-term-same-dir
├── pacman-fzf-install  # Thin wrapper using fzf-pkg-base.sh
├── tmux-sessionizer
├── yay-fzf-install     # Thin wrapper using fzf-pkg-base.sh
└── yay-fzf-remove      # Thin wrapper using fzf-pkg-base.sh
```

---

## Summary

**Critical Issues (Fix Immediately):**
1. Config file sourcing in tmux-sessionizer is a code injection vector
2. O(n²) process traversal in i3-tmux-launcher

**High-Impact Refactors:**
1. Extract common FZF package manager pattern to shared library
2. Add proper error handling with `set -euo pipefail`

**Testing Gaps:**
- No automated tests exist for any script
- Edge cases (special characters in paths/names, missing dependencies) are unhandled
- No CI/CD validation

---

*End of Audit Report*
