# `warp` — Cloudflare WARP Toggle

> Complete reference: architecture, security model, DNS protection, setup, and
> debugging.

---

## TL;DR

`warp` is a root-owned bash script that toggles Cloudflare WARP on/off,
protects DNS with `chattr +i` (immutable bit), and manages the `warp-svc`
systemd unit. It self-escalates to root via `sudo` using a NOPASSWD sudoers
rule — no password prompt, ever.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)  
2. [Execution Flow](#execution-flow)  
3. [Security Model](#security-model)  
4. [DNS Immutable Lock](#dns-immutable-lock)  
5. [Symlink / Path Portability](#symlink--path-portability)  
6. [Setup (New Machine)](#setup-new-machine)  
7. [Shell Integration — `wstat()`](#shell-integration--wstat)  
8. [Configuration Knobs](#configuration-knobs)  
9. [Commands Reference](#commands-reference)  
10. [How Toggle Logic Works](#how-toggle-logic-works)  
11. [Debugging](#debugging)  

---

## Architecture Overview

```
~/.local/bin/warp          ← symlink (in $PATH)
        │
        └──► ~/work/config/bin/warp   ← real script (root:root 0755)
                    │
                    └──► exec sudo <real_path> "$@"
                                    │
                            /etc/sudoers.d/warp
                            NOPASSWD: <real_path>
```

**Three-layer design:**

| Layer | What it is | Why |
|---|---|---|
| `~/.local/bin/warp` | Symlink | User-facing; lives in `$PATH`; pointing to dotfiles |
| `~/work/config/bin/warp` | Real script | Root-owned; this is what sudoers allows |
| `/etc/sudoers.d/warp` | NOPASSWD rule | Allows passwordless `sudo` for exactly this file |

The critical invariant: **the path in sudoers must match the canonical
(realpath-resolved) path of the script.** The symlink is transparent to the
user; the sudo call always uses the real path.

---

## Execution Flow

When you type `warp` in a terminal:

```
1. zsh finds ~/.local/bin/warp (symlink in $PATH)
2. Script starts as EUID=kali (not root)
3. EUID check fires:
       _SELF=$(realpath "${BASH_SOURCE[0]}")
       # _SELF = /home/kali/work/config/bin/warp  ← real path
       exec sudo "$_SELF" "$@"
4. sudo checks /etc/sudoers.d/warp:
       NOPASSWD: /home/kali/work/config/bin/warp  ← MATCHES
5. sudo re-executes the script as root, passing all args
6. EUID=0 now → skips escalation block
7. Dispatch → cmd_toggle / cmd_status / cmd_help
```

**Why `BASH_SOURCE[0]` instead of `$0`?**  
`$0` in bash is the invocation path — it equals the symlink path
`~/.local/bin/warp` when called via symlink. `BASH_SOURCE[0]` is the same
here, BUT `realpath` resolves both to the canonical path. The critical
function is `realpath`, not the choice between `$0` and `BASH_SOURCE[0]`.
Using `BASH_SOURCE[0]` is a defensive convention: it behaves correctly even
if the script is sourced.`

---

## Security Model

```
Ownership:  root:root
Mode:       0755  (world-executable, root-writable only)
```

**Why root-owned?**  
The script calls `chattr` (sets immutable bit on `/etc/resolv.conf`) and
`systemctl start/stop warp-svc`. Both need root. Making the file root-owned
means only root can tamper with the escalation logic — a non-root attacker
cannot modify `bin/warp` to inject arbitrary code that runs as root via the
NOPASSWD rule.

**Threat model satisfied:**
- Privilege escalation path is an allow-listed file (sudoers)  
- File is immutable to non-root (ownership)  
- No SUID bit — cleaner and auditable  

**What `chattr +i` protects against:**  
Even as root via WARP's own daemon, DNS cannot be overwritten when the
immutable bit is set. `chattr +i` survives `sudo`, survives `rm -f`,
survives any process — only `chattr -i` (which also needs root) can unset it.

---

## DNS Immutable Lock

```
State:   WARP OFF → /etc/resolv.conf is immutable (+i)
State:   WARP ON  → /etc/resolv.conf is mutable (WARP manages it)
```

**Lock lifecycle:**

```bash
# Connecting (warp ON):
chattr -i /etc/resolv.conf    # unlock so WARP daemon can write DNS
warp-cli connect

# Disconnecting (warp OFF):
warp-cli disconnect
sleep 1                        # wait for WARP's DNS cleanup
printf '%s' "$CLEARNET_DNS" > /etc/resolv.conf   # atomic overwrite
chattr +i /etc/resolv.conf    # re-lock
```

**Why the 1-second sleep before DNS overwrite?**  
`warp-cli disconnect` is async. WARP's daemon may still be rewriting
`resolv.conf` for ~500ms after disconnect returns. Without the sleep, a race
condition causes WARP DNS (162.159.36.x) to survive into clearnet mode —
a DNS leak. The sleep makes the overwrite win.

**Clearnet DNS (hardcoded in script):**
```
nameserver 8.8.8.8    # Google
nameserver 8.8.4.4    # Google secondary
nameserver 1.1.1.1    # Cloudflare (non-WARP)
```
To change these, edit `CLEARNET_DNS` near the top of `bin/warp`.

---

## Symlink / Path Portability

**The core problem with naive `exec sudo "$0"`:**  

```
Invocation path:  ~/.local/bin/warp        (symlink)
Sudoers entry:    /home/kali/work/config/bin/warp  (real path)
sudo sees:        ~/.local/bin/warp        ≠ sudoers path
Result:           PASSWORD PROMPT
```

**The fix (`realpath`):**

```bash
_SELF=$(realpath "${BASH_SOURCE[0]}")
exec sudo "$_SELF" "$@"
# _SELF always = the canonical real path, regardless of how script was called
```

`realpath` is part of GNU coreutils, present on every Linux distro. On macOS
you need `coreutils` from Homebrew (`brew install coreutils`). Both provide
`realpath`.

**This works for any invocation method:**

| How called | `$0` | `realpath "$0"` |
|---|---|---|
| Direct: `~/work/config/bin/warp` | real path | real path |
| Symlink: `~/.local/bin/warp` | symlink path | real path |
| `PATH` lookup: `warp` | symlink path | real path |
| Tab-completed absolute symlink | symlink path | real path |

---

## Setup (New Machine)

These steps are handled by `setup-recovery/restore-dotfiles.sh`, but
documented here explicitly:

### 1. Clone dotfiles

```bash
git clone <your-repo> ~/work/config
```

### 2. Make script root-owned

```bash
sudo chown root:root ~/work/config/bin/warp
sudo chmod 0755 ~/work/config/bin/warp
```

> **Why root-owned in dotfiles?**  
> `git` stores ownership by UID. On a new machine with a different user,
> the file will be owned by that user after `git clone`. Step 2 must be
> run explicitly. This is the minimal required setup step you cannot avoid.

### 3. Install sudoers rule

```bash
# Get the real path first
WARP_REAL=$(realpath ~/work/config/bin/warp)

sudo tee /etc/sudoers.d/warp << EOF
$(whoami) ALL=(ALL) NOPASSWD: ${WARP_REAL}
EOF

sudo chmod 440 /etc/sudoers.d/warp
```

This is the only machine-specific step. The path `WARP_REAL` will differ
per machine if your home directory or dotfiles location differs.

### 4. Create symlink in PATH

```bash
ln -sf ~/work/config/bin/warp ~/.local/bin/warp
```

`restore-dotfiles.sh` does this for all `bin/` files automatically.

### 5. Source `warp.zsh`

`warp.zsh` is auto-sourced by `.zshrc` via glob:
```zsh
for config_file in "${ZDOTDIR:-$HOME/.config/zsh}"/*.zsh(N); do
    source "$config_file"
done
```
No manual step needed if your zsh config is already linked.

---

## Shell Integration — `wstat()`

Defined in `zsh/warp.zsh`:

```bash
wstat() {
    systemctl is-active --quiet warp-svc || {
        echo "Service: stopped"
        return 0
    }
    warp-cli status 2>/dev/null || echo "[!] Daemon running but CLI unresponsive"
}
```

**`wstat` vs `warp status`:**

| | `wstat` | `warp status` |
|---|---|---|
| Needs sudo | No | Yes (re-execs via sudo) |
| Speed | Instant | ~100ms sudo overhead |
| Use case | Status bar, quick checks | Scripting with consistent interface |
| Source | zsh function (shell) | Root-owned binary |

Use `wstat` in scripts/prompts where you want zero latency. Use
`warp status` when you want a single consistent interface or are writing
scripts that don't have a shell function available.

---

## Configuration Knobs

Near the top of `bin/warp`:

```bash
# DNS written to /etc/resolv.conf when WARP is OFF
readonly CLEARNET_DNS='# Custom DNS configuration
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1'

# Stop warp-svc daemon on disconnect to save ~30MB RAM.
# false = daemon stays running for faster reconnects.
readonly STOP_SERVICE_ON_DISCONNECT=true
```

**`STOP_SERVICE_ON_DISCONNECT` tradeoff:**

| Setting | RAM when WARP off | Reconnect speed |
|---|---|---|
| `true` | Saves ~30MB | Slow (~2s daemon start) |
| `false` | Wastes ~30MB | Instant |

---

## Commands Reference

```
warp              Toggle WARP on/off (main use)
warp status       Show daemon state and connection info
warp help         Print usage
wstat             Quick status (no sudo, shell function)
```

---

## How Toggle Logic Works

```
warp (toggle)
├── ensure_daemon()       — start warp-svc if stopped
├── detect_state()        — parse `warp-cli status` output
│       ├── "connected"   → do_disconnect()
│       └── "disconnected" / "connecting" → do_connect()
│
├── do_disconnect()
│   ├── warp-cli disconnect
│   ├── sleep 1  (wait for async DNS cleanup — prevents leak)
│   ├── unlock /etc/resolv.conf
│   ├── write CLEARNET_DNS atomically
│   ├── re-lock /etc/resolv.conf (chattr +i)
│   └── optionally stop warp-svc (STOP_SERVICE_ON_DISCONNECT)
│
└── do_connect()
    ├── chattr -i /etc/resolv.conf  (unlock for WARP)
    ├── warp-cli connect
    ├── sleep 1.5  (wait for handshake)
    └── curl https://www.cloudflare.com/cdn-cgi/trace
        └── verify warp=on in response → print exit IP + datacenter
```

---

## Debugging

**warp prompts for password:**
```bash
# Check what path sudo is seeing:
sudo -n warp status 2>&1
# Should see "NOPASSWD OK", not a password prompt.

# Check the real path:
realpath ~/.local/bin/warp

# Check sudoers entry:
sudo cat /etc/sudoers.d/warp
# The path there must EXACTLY MATCH realpath output above.
```

**warp-svc won't start:**
```bash
systemctl status warp-svc
journalctl -u warp-svc -n 50
```

**DNS not restoring after disconnect:**
```bash
lsattr /etc/resolv.conf   # should show ----i---- when WARP off
cat /etc/resolv.conf
# If locked but wrong content: sudo chattr -i /etc/resolv.conf && warp
```

**WARP connected but traffic not routing:**
```bash
curl https://www.cloudflare.com/cdn-cgi/trace | grep warp
# warp=on = tunneled correctly
# warp=off = connected but traffic not routed (WARP account issue)
```

**Check immutable bit manually:**
```bash
lsattr /etc/resolv.conf
# ----i--------e-- /etc/resolv.conf  ← locked (WARP off)
# -------------e-- /etc/resolv.conf  ← unlocked (WARP active)
```
