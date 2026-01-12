#!/usr/bin/env bash
# Restore dotfiles via symlinks (not copies) from parent /home/kali/work/config directory
# Creates symbolic links to avoid duplication
# Auto-detects and makes scripts executable

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
PARENT_CONFIG_DIR="$(cd "$(dirname "$SCRIPT_DIR")" && pwd)"  # Convert to absolute path

# Verify parent directory exists
if [[ ! -d "$PARENT_CONFIG_DIR" ]]; then
    log_error "Parent config directory not found: $PARENT_CONFIG_DIR"
    exit 1
fi

log_info "Restoring dotfiles via symlinks from: $PARENT_CONFIG_DIR"
log_info "Target config home: $CONFIG_HOME"

# Create necessary directories
mkdir -p "$CONFIG_HOME"
mkdir -p "$HOME"

# === CONFIG FILES (XDG_CONFIG_HOME) ===
CONFIG_DIRS=(
    "nvim"
    "kitty"
    "zsh"
    "i3"
    "i3status-rust"
    "sway"
    "dunst"
    "picom"
    "cava"
    "zathura"
    "rmpc"
    "nsxiv"
    "mpd"
)

log_info "Creating symlinks for config directories..."
for dir in "${CONFIG_DIRS[@]}"; do
    if [[ -d "$PARENT_CONFIG_DIR/$dir" ]]; then
        # Safety: Check if already correctly linked before removing
        if [[ -e "$CONFIG_HOME/$dir" ]]; then
            # Check if it is already a symlink to the correct place
            if [[ "$(readlink -f "$CONFIG_HOME/$dir")" == "$PARENT_CONFIG_DIR/$dir" ]]; then
                log_info "  ✓ $dir is already correctly linked"
                continue
            fi
            
            # It's a real directory or wrong link. Back it up (never delete user data)
            BACKUP_NAME="${CONFIG_HOME}/${dir}_backup_$(date +%Y%m%d_%H%M%S)"
            log_warn "  ! Existing config found. Backing up to $BACKUP_NAME"
            mv "$CONFIG_HOME/$dir" "$BACKUP_NAME" || {
                log_error "Failed to backup $CONFIG_HOME/$dir"
                continue
            }
        fi
        
        log_info "  → $CONFIG_HOME/$dir (symlink to ../)"
        ln -s "$PARENT_CONFIG_DIR/$dir" "$CONFIG_HOME/$dir"
        
        # Make scripts executable
        if [[ -d "$PARENT_CONFIG_DIR/$dir/scripts" ]]; then
            chmod +x "$PARENT_CONFIG_DIR/$dir/scripts"/*.sh 2>/dev/null || true
            log_info "     ✓ Made scripts executable"
        fi
    else
        log_warn "  ✗ $dir not found (skipping)"
    fi
done

# === DOTFILES (HOME) ===
DOTFILES=(
    ".tmux.conf"
    ".xprofile"
    ".Xresources"
)

log_info "Creating symlinks for dotfiles..."
for file in "${DOTFILES[@]}"; do
    if [[ -f "$PARENT_CONFIG_DIR/$file" ]]; then
        # Safety: Check if already correctly linked before removing
        if [[ -e "$HOME/$file" ]]; then
            if [[ "$(readlink -f "$HOME/$file")" == "$PARENT_CONFIG_DIR/$file" ]]; then
                log_info "  ✓ $file is already correctly linked"
                continue
            fi
            
            # Wrong link or real file. Back it up.
            BACKUP_NAME="${HOME}/${file}_backup_$(date +%Y%m%d_%H%M%S)"
            log_warn "  ! Existing dotfile found. Backing up to $BACKUP_NAME"
            mv "$HOME/$file" "$BACKUP_NAME"
        fi
        
        log_info "  → $HOME/$file (symlink to ../)"
        ln -s "$PARENT_CONFIG_DIR/$file" "$HOME/$file"
    else
        log_warn "  ✗ $file not found (skipping)"
    fi
done

# === USER SYSTEMD SERVICES ===
SYSTEMD_USER_DIR="$CONFIG_HOME/systemd/user"
USER_SERVICES_DIR="$PARENT_CONFIG_DIR/systemd/user"

if [[ -d "$USER_SERVICES_DIR" ]]; then
    log_info "Creating symlinks for user systemd services..."
    mkdir -p "$SYSTEMD_USER_DIR"
    
    for service_file in "$USER_SERVICES_DIR"/*.service; do
        if [[ -f "$service_file" ]]; then
            service_name=$(basename "$service_file")
            target="$SYSTEMD_USER_DIR/$service_name"
            
            # Safety: Check if already correctly linked
            if [[ -e "$target" ]]; then
                if [[ "$(readlink -f "$target")" == "$service_file" ]]; then
                    log_info "  ✓ $service_name is already correctly linked"
                    continue
                fi
                
                # Wrong link or real file. Back it up.
                BACKUP_NAME="${target}_backup_$(date +%Y%m%d_%H%M%S)"
                log_warn "  ! Existing service found. Backing up to $BACKUP_NAME"
                mv "$target" "$BACKUP_NAME"
            fi
            
            log_info "  → $SYSTEMD_USER_DIR/$service_name (symlink)"
            ln -s "$service_file" "$target"
        fi
    done
    
    log_info "✓ User systemd services symlinked"
    log_info "  Run: systemctl --user daemon-reload"
else
    log_warn "  User systemd services directory not found (skipping)"
fi

# === Make all shell scripts executable ===
log_info "Making all shell scripts executable..."
find "$PARENT_CONFIG_DIR" -type f \( -name "*.sh" -o -name "*.py" \) 2>/dev/null | while read -r script; do
    if [[ -f "$script" && ! -x "$script" ]]; then
        chmod +x "$script"
        log_info "  ✓ chmod +x: $(basename "$script")"
    fi
done

log_info "✓ Dotfile restoration complete!"
log_info ""
log_info "Symlink mapping:"
log_info "  $PARENT_CONFIG_DIR/* → $CONFIG_HOME/*"
log_info "  $PARENT_CONFIG_DIR/.* → $HOME/*"
log_info ""
log_info "Verify symlinks:"
log_info "  ls -la $CONFIG_HOME/"
log_info "  ls -la $HOME/.tmux.conf"
log_info ""
log_info "Next steps:"
log_info "  1. Reload shell: source \$HOME/.zshrc"
log_info "  2. Test: nvim, kitty, i3 keybinds, etc."
log_info "  3. If needed, restart i3/sway: \$mod+Shift+r"
