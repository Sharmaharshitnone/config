# Setup-Recovery Technical Audit
**Principal System Architect Review**  
**Module Version:** 2.0  
**Audit Date:** 2026-01-31

---

## Phase 1: Deep Documentation

### 1. Architecture: Data Flow Analysis

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         BOOTSTRAP-YAY.SH (Entry Point)                      │
│                                                                             │
│  User invokes: sudo ./bootstrap-yay.sh                                      │
│                           │                                                 │
│                           ▼                                                 │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │ 1. YAY INSTALLATION (if missing)                                   │    │
│  │    • Clone from AUR → /tmp → makepkg -si                           │    │
│  │    • Trap cleanup on EXIT                                          │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│                           │                                                 │
│                           ▼                                                 │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │ 2. PACMAN OPTIMIZATION                                             │    │
│  │    • Enable ParallelDownloads in /etc/pacman.conf                  │    │
│  │    • Run reflector (if available) → /etc/pacman.d/mirrorlist       │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│                           │                                                 │
│                           ▼                                                 │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │ 3. PACKAGE INSTALLATION (install-packages.sh)                      │    │
│  │    • 111 pacman packages → sudo pacman -S --needed                 │    │
│  │    • 15 AUR packages → yay -S --needed                             │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│                           │                                                 │
│                           ▼                                                 │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │ 4. DOTFILE RESTORATION (restore-dotfiles.sh)                       │    │
│  │    • 18 config directories → $HOME/.config (symlinks)              │    │
│  │    • 8 dotfiles → $HOME (symlinks)                                 │    │
│  │    • System configs → /etc/* (requires root)                       │    │
│  │    • TPM installation (git clone)                                  │    │
│  │    • Sheldon plugin installation                                   │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│                           │                                                 │
│                           ▼                                                 │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │ 5. OPTIONAL INTERACTIVE PROMPTS (y/n for each)                     │    │
│  │    ├── Performance Optimization (zRAM + ccache)                    │    │
│  │    ├── Secure Boot Setup (secure-boot-setup.sh)                    │    │
│  │    ├── Service Enablement (enable-services.sh)                     │    │
│  │    ├── Piper Voice Download (download-piper-voice.sh)              │    │
│  │    └── Boot Optimization (boot-optimization.sh)                    │    │
│  └────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### Script Dependency Graph

```
bootstrap-yay.sh
├── install-packages.sh (mandatory call)
├── restore-dotfiles.sh (mandatory call)
├── secure-boot-setup.sh (optional, interactive)
├── enable-services.sh (optional, interactive)
├── download-piper-voice.sh (optional, interactive)
└── boot-optimization.sh (optional, interactive)
```

#### Filesystem Touchpoints

| Script | Reads | Writes |
|--------|-------|--------|
| `bootstrap-yay.sh` | `/etc/pacman.conf`, env vars | `/tmp` (yay clone), `/etc/pacman.conf`, `/etc/pacman.d/mirrorlist` |
| `install-packages.sh` | Package databases | System-wide packages |
| `restore-dotfiles.sh` | `$PARENT_CONFIG_DIR/*` | `$HOME/.config/*`, `$HOME/.*`, `/etc/speech-dispatcher/*`, `/etc/X11/xorg.conf.d/*`, `/usr/bin/xterm` |
| `secure-boot-setup.sh` | `/usr/lib/systemd/boot/efi/*`, `/boot/EFI/Linux/*` | `/usr/share/secureboot/keys/*`, UEFI firmware keys, `/boot/*` |
| `boot-optimization.sh` | `/etc/mkinitcpio.conf`, `/etc/kernel/cmdline` | Same files (modified), UKI images |
| `enable-services.sh` | systemd unit files | `~/.local/share/mpd/*`, `/tmp/mpd.fifo`, systemd user units |
| `download-piper-voice.sh` | Network (huggingface.co) | `$HOME/.local/share/piper-voices/*` |
| `setup-ly-greeter.sh` | `$CONFIG_SOURCE_DIR/ly-configs/*` | `/etc/systemd/system/*`, `/etc/pam.d/*`, `/etc/vconsole.conf`, `/etc/doas.conf` |
| `setup-input-config.sh` | Existing i3/sway configs | `$HOME/.config/sway/config.d/*`, `$HOME/.config/i3/config` |

---

### 2. Dependencies: System Touchpoints

#### External Tool Dependencies

| Script | Required Tools | Optional Tools |
|--------|---------------|----------------|
| `bootstrap-yay.sh` | `bash`, `pacman`, `git`, `makepkg`, `sudo` | `reflector`, `yay` |
| `install-packages.sh` | `pacman`, `yay`, `sudo` | — |
| `restore-dotfiles.sh` | `bash`, `ln`, `mkdir`, `chmod`, `readlink`, `mv`, `find` | `zsh`, `sheldon`, `kitty`, `git` (TPM), `pacman` |
| `secure-boot-setup.sh` | `sbctl`, `jq`, `bootctl`, `pacman`, `sudo` | — |
| `boot-optimization.sh` | `systemd-analyze`, `sed`, `grep`, `bootctl`, `mkinitcpio`, `sudo` | — |
| `enable-services.sh` | `systemctl`, `mkdir`, `mkfifo`, `rm` | — |
| `download-piper-voice.sh` | `wget`, `mkdir` | — |
| `setup-ly-greeter.sh` | `pacman`, `systemctl`, `ln`, `mkdir`, `rm`, `sudo` | — |
| `setup-input-config.sh` | `cat`, `grep` | `xinput` |

#### System Service Dependencies

```
User Services (systemctl --user):
  ├── mpd.service
  ├── mpd-mpris.service
  └── gdrive.service (rclone mount)

System Services (systemctl):
  ├── speech-dispatcher.service
  ├── ly@tty2.service (display manager)
  └── zram0 (via zram-generator)
```

#### Network Dependencies

| Script | External URL | Purpose |
|--------|--------------|---------|
| `bootstrap-yay.sh` | `https://aur.archlinux.org/yay.git` | AUR helper installation |
| `restore-dotfiles.sh` | `https://github.com/tmux-plugins/tpm` | Tmux plugin manager |
| `download-piper-voice.sh` | `https://huggingface.co/rhasspy/piper-voices/...` | TTS voice model |
| `install-packages.sh` | Arch mirrors, AUR | Package downloads |

---

### 3. Hidden Complexity: Magic Numbers, Unclear Logic, Side Effects

#### 3.1 Magic Numbers & Hardcoded Values

| File | Line | Value | Problem |
|------|------|-------|---------|
| `bootstrap-yay.sh` | 113-119 | `zram-size = min(ram / 2, 4096)` | Hardcoded 4GB max assumes 16GB+ RAM systems |
| `bootstrap-yay.sh` | 129 | `ccache -M 50G` | Arbitrary 50GB cache size, no disk space check |
| `boot-optimization.sh` | 63 | `HOOKS=(systemd autodetect modconf kms keyboard sd-vconsole block filesystems fsck)` | Hardcoded HOOKS override destroys custom configurations |
| `boot-optimization.sh` | 69 | `COMPRESSION="lz4"` | Assumes lz4 is available, no fallback |
| `boot-optimization.sh` | 114 | `bootctl set-timeout 0` | Zero timeout prevents boot menu access for troubleshooting |
| `secure-boot-setup.sh` | 35-38 | UKI paths `/boot/EFI/Linux/arch-linux*.efi` | Hardcoded paths fail on non-standard ESP layouts |
| `enable-services.sh` | 39 | `chmod 644 /tmp/mpd.fifo` | World-readable FIFO is a minor security concern |
| `restore-dotfiles.sh` | 191 | Regex `/etc/passwd` check | Unreliable shell detection method |

#### 3.2 Unclear Logic / Code Smells

**bootstrap-yay.sh:211-224** — Misleading prompt text:
```bash
read -p "Download Piper TTS voice model? (y/n) " -n 1 -r
# Comment says "Boot Time Optimization" but prompt asks about Piper voice
# This is confusing and error-prone
```

**enable-services.sh:111** — Typo causes script failure:
```bash
if [ $EqNABLED_COUNT -gt 0 ]; then  # Should be $ENABLED_COUNT
```

**restore-dotfiles.sh:191-193** — Incorrect shell detection:
```bash
if ! grep -q "^$USER:.*:$ZSH_PATH" /etc/passwd; then
    chsh -s "$ZSH_PATH" "$USER"
# This regex is broken - it won't match most /etc/passwd formats
# Correct: grep "^$USER:" /etc/passwd | grep -q "$ZSH_PATH$"
```

**secure-boot-setup.sh:129-134** — Random seed permissions race:
```bash
sudo chown root:root /boot/loader/random-seed
sudo chmod 600 /boot/loader/random-seed
# This file may not exist on fresh installs, causing script failure
```

#### 3.3 Side Effects & Dangerous Operations

| Script | Line | Side Effect | Risk Level |
|--------|------|-------------|------------|
| `restore-dotfiles.sh` | 391-407 | Removes `xterm` package and creates symlink to `kitty` | **HIGH** — Breaks systems that depend on xterm |
| `boot-optimization.sh` | 63 | Overwrites HOOKS in mkinitcpio.conf | **HIGH** — Can brick system if critical hooks are removed |
| `boot-optimization.sh` | 123-132 | Disables `cups.service` | **MEDIUM** — Breaks printing without warning |
| `secure-boot-setup.sh` | 89 | Runs `bootctl install` | **MEDIUM** — Can overwrite custom bootloader configs |
| `setup-ly-greeter.sh` | 59-63 | Overwrites systemd service symlinks unconditionally | **MEDIUM** — No backup of existing configs |
| `restore-dotfiles.sh` | 299-305 | Writes to `/etc/speech-dispatcher/` with sudo | **MEDIUM** — System-wide config changes |
| `bootstrap-yay.sh` | 67-70 | Modifies `/etc/pacman.conf` with sed | **MEDIUM** — Can corrupt config on edge cases |

#### 3.4 Error Handling Gaps

| Script | Issue |
|--------|-------|
| `install-packages.sh` | Uses `set -uo pipefail` but NOT `set -e`, allowing partial failures to cascade |
| `boot-optimization.sh` | `mkinitcpio -P` failure message is shown, but backup restoration is not automatic |
| `secure-boot-setup.sh` | No validation that UEFI variables are writable before key enrollment |
| `restore-dotfiles.sh` | TPM clone failure is logged but doesn't stop the script |
| `enable-services.sh` | Typo `$EqNABLED_COUNT` will cause unbound variable error |

---

## Phase 2: Gap Analysis & Optimization

### 1. Performance Issues

#### 1.1 O(n) Inefficiencies (Not O(n²), but still suboptimal)

**install-packages.sh:21-43** — Multiple `sudo pacman -S` calls:
```bash
# CURRENT: 23 separate pacman invocations
sudo pacman -S --needed --noconfirm 7zip act adw-gtk-theme...
sudo pacman -S --needed --noconfirm base base-devel bat bc...
# ... 21 more lines

# IMPACT: Each call re-reads package database, re-validates dependencies
# SOLUTION: Single invocation with all packages
```

**Proposed Fix:**
```bash
# Use a single pacman call with all packages
PACMAN_PACKAGES=(
    7zip act adw-gtk-theme alsa-utils android-tools android-udev
    base base-devel bat bc bemenu bemenu-wayland blueman bluez bluez-utils
    # ... all packages
)
sudo pacman -S --needed --noconfirm "${PACMAN_PACKAGES[@]}"
```

#### 1.2 Unnecessary Disk I/O

**restore-dotfiles.sh:415-420** — `find` + `chmod` on every run:
```bash
# CURRENT: Scans entire config tree on every execution
find "$PARENT_CONFIG_DIR" -type f \( -name "*.sh" -o -name "*.py" \) | while read -r script; do
    if [[ -f "$script" && ! -x "$script" ]]; then
        chmod +x "$script"
# IMPACT: ~500+ file stat() calls on typical config repo
# SOLUTION: Only chmod on first run or use git hooks
```

**Proposed Fix:**
```bash
# Only run if a marker file doesn't exist
CHMOD_MARKER="$PARENT_CONFIG_DIR/.scripts_executable"
if [[ ! -f "$CHMOD_MARKER" ]]; then
    find "$PARENT_CONFIG_DIR" -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} +
    touch "$CHMOD_MARKER"
fi
```

#### 1.3 Blocking Network I/O

**restore-dotfiles.sh:131-134** — TPM git clone blocks script:
```bash
# CURRENT: Synchronous git clone
git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
# IMPACT: 5-30 second block depending on network

# SOLUTION: Background with timeout or skip if already cloned
```

---

### 2. Safety Issues

#### 2.1 Critical Bugs

**enable-services.sh:111** — Typo causes unbound variable crash:
```bash
# BUG: $EqNABLED_COUNT is undefined (typo)
if [ $EqNABLED_COUNT -gt 0 ]; then

# FIX:
if [ $ENABLED_COUNT -gt 0 ]; then
```

**restore-dotfiles.sh:191** — Broken shell detection:
```bash
# BUG: Regex doesn't match standard /etc/passwd format
if ! grep -q "^$USER:.*:$ZSH_PATH" /etc/passwd; then

# FIX: Use getent for reliable shell detection
CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
if [[ "$CURRENT_SHELL" != "$ZSH_PATH" ]]; then
```

#### 2.2 Race Conditions

**enable-services.sh:35-39** — FIFO creation race:
```bash
# CURRENT: Remove then create (non-atomic)
if [ -e /tmp/mpd.fifo ]; then
    rm -f /tmp/mpd.fifo
fi
mkfifo /tmp/mpd.fifo

# RISK: Another process could create /tmp/mpd.fifo between rm and mkfifo
# FIX: Use atomic operation
rm -f /tmp/mpd.fifo && mkfifo /tmp/mpd.fifo
```

**secure-boot-setup.sh:129-134** — Random seed file may not exist:
```bash
# CURRENT: Assumes file exists
sudo chown root:root /boot/loader/random-seed
sudo chmod 600 /boot/loader/random-seed

# FIX: Check existence first
if [[ -f /boot/loader/random-seed ]]; then
    sudo chown root:root /boot/loader/random-seed
    sudo chmod 600 /boot/loader/random-seed
fi
```

#### 2.3 Privilege Escalation Concerns

**restore-dotfiles.sh:406** — Symlink to kitty as xterm:
```bash
# CURRENT: Creates symlink in /usr/bin as root
sudo ln -sf "$KITTY_PATH" "$XTERM_LINK"

# RISK: If $KITTY_PATH is controlled by non-root user, this is a privilege escalation vector
# FIX: Validate kitty path is system-owned
if [[ "$KITTY_PATH" == /usr/bin/* ]]; then
    sudo ln -sf "$KITTY_PATH" "$XTERM_LINK"
else
    log_warn "Refusing to symlink non-system kitty path: $KITTY_PATH"
fi
```

#### 2.4 Data Loss Risks

**boot-optimization.sh:63** — HOOKS override destroys custom configs:
```bash
# CURRENT: Unconditional sed replacement
sed -i 's/^HOOKS=.*/HOOKS=(systemd autodetect modconf kms keyboard sd-vconsole block filesystems fsck)/'

# RISK: User may have critical hooks like 'encrypt', 'lvm2', 'resume'
# FIX: Merge hooks instead of replacing, or require explicit confirmation
```

**Proposed Fix:**
```bash
# Read current HOOKS, warn if critical hooks would be removed
CURRENT_HOOKS=$(grep "^HOOKS=" "$MKINITCPIO_CONF" | sed 's/HOOKS=(\(.*\))/\1/')
CRITICAL_HOOKS=(encrypt lvm2 resume plymouth)
for hook in "${CRITICAL_HOOKS[@]}"; do
    if [[ "$CURRENT_HOOKS" == *"$hook"* ]]; then
        warn "Current config contains critical hook: $hook"
        warn "This hook will be REMOVED. Press Ctrl+C to abort, Enter to continue."
        read -r
    fi
done
```

---

### 3. Refactoring Suggestions

#### 3.1 Strategy Pattern for Package Installation

**Current Problem:** `install-packages.sh` has hardcoded package lists that are difficult to maintain.

**Proposed Pattern:**
```bash
# packages.d/base.txt
base
base-devel
git

# packages.d/desktop.txt
i3-wm
kitty
dunst

# install-packages.sh refactored
install_package_group() {
    local group_file="$1"
    local packages=()
    while IFS= read -r pkg || [[ -n "$pkg" ]]; do
        [[ "$pkg" =~ ^#.*$ || -z "$pkg" ]] && continue
        packages+=("$pkg")
    done < "$group_file"
    sudo pacman -S --needed --noconfirm "${packages[@]}"
}

for group in "$SCRIPT_DIR/packages.d"/*.txt; do
    install_package_group "$group"
done
```

#### 3.2 Factory Pattern for Service Configuration

**Current Problem:** `enable-services.sh` has hardcoded service definitions.

**Proposed Pattern:**
```bash
# services.d/mpd.conf
name=mpd
description=Music Player Daemon
type=user
prereqs=~/.local/share/mpd/playlists,~/Music
fifo=/tmp/mpd.fifo

# enable-services.sh refactored
configure_service() {
    local config_file="$1"
    source "$config_file"
    
    # Create prerequisites
    for prereq in ${prereqs//,/ }; do
        mkdir -p "$prereq"
    done
    
    # Create FIFO if specified
    [[ -n "$fifo" ]] && { rm -f "$fifo"; mkfifo "$fifo"; }
    
    # Enable service
    if [[ "$type" == "user" ]]; then
        systemctl --user enable --now "$name.service"
    else
        sudo systemctl enable --now "$name.service"
    fi
}
```

#### 3.3 Template Method for Backup/Restore Operations

**Current Problem:** Backup logic is duplicated across multiple scripts.

**Proposed Pattern:**
```bash
# lib/backup.sh
backup_file() {
    local file="$1"
    local backup_dir="${2:-$HOME/.config-backups}"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    mkdir -p "$backup_dir"
    if [[ -e "$file" && ! -L "$file" ]]; then
        cp -a "$file" "$backup_dir/$(basename "$file").$timestamp"
        echo "$backup_dir/$(basename "$file").$timestamp"
    fi
}

restore_backup() {
    local backup_file="$1"
    local target="$2"
    
    if [[ -f "$backup_file" ]]; then
        cp -a "$backup_file" "$target"
        return 0
    fi
    return 1
}
```

#### 3.4 Dependency Injection for Testing

**Current Problem:** Scripts directly call system commands, making testing impossible.

**Proposed Pattern:**
```bash
# lib/commands.sh
: "${PACMAN:=pacman}"
: "${SYSTEMCTL:=systemctl}"
: "${GIT:=git}"

# In scripts:
source "$SCRIPT_DIR/lib/commands.sh"
$PACMAN -S --needed --noconfirm "${packages[@]}"

# In tests:
PACMAN="echo MOCK_PACMAN" ./install-packages.sh
```

---

### 4. Missing Tests & Edge Cases

#### 4.1 Unhandled Edge Cases

| Script | Edge Case | Current Behavior | Expected Behavior |
|--------|-----------|------------------|-------------------|
| `bootstrap-yay.sh` | Disk full during yay clone | Script fails mid-clone, leaves partial clone | Clean up temp dir, show meaningful error |
| `restore-dotfiles.sh` | Symlink target doesn't exist | Creates broken symlink | Warn user, skip or fail gracefully |
| `restore-dotfiles.sh` | Running as root (not sudo) | Creates symlinks owned by root in user home | Detect and abort or use `$SUDO_USER` |
| `secure-boot-setup.sh` | BIOS (non-UEFI) system | Fails at sbctl commands | Detect early and abort with clear message |
| `boot-optimization.sh` | Non-systemd-boot bootloader (GRUB) | Modifies wrong files | Detect bootloader type first |
| `enable-services.sh` | MPD not installed | Tries to enable non-existent service | Check package installation first |
| `install-packages.sh` | Package no longer in repos | Entire pacman call fails | Retry without missing package |
| `download-piper-voice.sh` | Network timeout | wget hangs indefinitely | Add `--timeout=30` |

#### 4.2 Proposed Test Cases

```bash
# test/test_restore_dotfiles.sh

test_symlink_creation() {
    # Setup
    export HOME=$(mktemp -d)
    export PARENT_CONFIG_DIR=$(mktemp -d)
    mkdir -p "$PARENT_CONFIG_DIR/nvim"
    
    # Execute
    ./restore-dotfiles.sh
    
    # Assert
    [[ -L "$HOME/.config/nvim" ]] || fail "Symlink not created"
    [[ "$(readlink -f "$HOME/.config/nvim")" == "$PARENT_CONFIG_DIR/nvim" ]] || fail "Symlink points to wrong target"
}

test_backup_on_existing_config() {
    # Setup
    export HOME=$(mktemp -d)
    mkdir -p "$HOME/.config/nvim"
    echo "existing" > "$HOME/.config/nvim/init.lua"
    
    # Execute
    ./restore-dotfiles.sh
    
    # Assert
    [[ -d "$HOME/.config/nvim_backup_"* ]] || fail "Backup not created"
    [[ -L "$HOME/.config/nvim" ]] || fail "Symlink not created after backup"
}

test_handles_broken_symlink() {
    # Setup
    export HOME=$(mktemp -d)
    ln -s /nonexistent "$HOME/.config/nvim"
    
    # Execute
    ./restore-dotfiles.sh
    
    # Assert
    [[ -L "$HOME/.config/nvim" ]] || fail "Broken symlink not replaced"
}

test_detects_non_uefi_system() {
    # Setup (mock non-UEFI)
    export PACMAN="echo"
    
    # Execute
    output=$(./secure-boot-setup.sh 2>&1) || true
    
    # Assert
    [[ "$output" == *"UEFI"* ]] || fail "Should warn about non-UEFI system"
}
```

#### 4.3 Integration Test Scenarios

```bash
# test/integration/full_recovery.sh

test_full_recovery_fresh_install() {
    # Requires: Clean Arch container
    # 1. Run bootstrap-yay.sh non-interactively
    # 2. Verify yay installed
    # 3. Verify packages installed (spot check)
    # 4. Verify symlinks created
    # 5. Verify services can be enabled
}

test_idempotency() {
    # Run bootstrap-yay.sh twice
    # Verify no errors on second run
    # Verify no duplicate backups created
    # Verify symlinks unchanged
}

test_rollback() {
    # 1. Create known state
    # 2. Run restore-dotfiles.sh
    # 3. Restore from backups
    # 4. Verify original state restored
}
```

---

## Summary of Critical Issues

### Must Fix (Blocking)

1. **enable-services.sh:111** — `$EqNABLED_COUNT` typo causes script crash
2. **restore-dotfiles.sh:191** — Broken shell detection regex
3. **secure-boot-setup.sh:129-134** — Random seed file may not exist

### Should Fix (High Priority)

4. **boot-optimization.sh:63** — HOOKS replacement destroys critical hooks (encrypt, lvm2)
5. **install-packages.sh** — 23 separate pacman calls instead of one
6. **bootstrap-yay.sh:211-224** — Misleading prompt text (Boot Optimization vs Piper)

### Nice to Have (Low Priority)

7. Implement Strategy pattern for package management
8. Add comprehensive test suite
9. Create shared library for backup/restore operations

---

## Proposed Fix: Critical Bug in enable-services.sh

```bash
# Line 111 - BEFORE (BROKEN):
if [ $EqNABLED_COUNT -gt 0 ]; then

# Line 111 - AFTER (FIXED):
if [ $ENABLED_COUNT -gt 0 ]; then
```

---

## Proposed Fix: Shell Detection in restore-dotfiles.sh

```bash
# Lines 189-199 - BEFORE (BROKEN):
if command -v zsh &>/dev/null; then
    ZSH_PATH="$(command -v zsh)"
    if ! grep -q "^$USER:.*:$ZSH_PATH" /etc/passwd; then
        log_info "Setting zsh as default shell..."
        chsh -s "$ZSH_PATH" "$USER" || log_warn "Could not set zsh as default (may need sudo)"
    else
        log_info "✓ zsh is already the default shell"
    fi

# Lines 189-199 - AFTER (FIXED):
if command -v zsh &>/dev/null; then
    ZSH_PATH="$(command -v zsh)"
    CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
    if [[ "$CURRENT_SHELL" != "$ZSH_PATH" ]]; then
        log_info "Setting zsh as default shell..."
        chsh -s "$ZSH_PATH" "$USER" || log_warn "Could not set zsh as default (may need sudo)"
    else
        log_info "✓ zsh is already the default shell"
    fi
```

---

## Proposed Fix: Random Seed Check in secure-boot-setup.sh

```bash
# Lines 129-134 - BEFORE:
log "Setting /boot permissions to remove random seed warnings..."
sudo chown root:root /boot
sudo chmod 700 /boot             
sudo chown root:root /boot/loader/random-seed
sudo chmod 600 /boot/loader/random-seed
success "Boot permissions secured."

# Lines 129-134 - AFTER:
log "Setting /boot permissions to remove random seed warnings..."
sudo chown root:root /boot
sudo chmod 700 /boot
if [[ -f /boot/loader/random-seed ]]; then
    sudo chown root:root /boot/loader/random-seed
    sudo chmod 600 /boot/loader/random-seed
    success "Boot permissions secured."
else
    warn "Random seed file not found (normal for fresh installs)"
fi
```

---

**Audit Complete.**  
**Auditor:** Principal System Architect (Claude)  
**Findings:** 3 Critical, 3 High, 3 Low Priority Issues
