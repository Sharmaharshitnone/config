#!/usr/bin/env bash
# Restore dotfiles via symlinks (not copies) from parent config directory
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
    "gtk-3.0"
    "gtk-4.0"
    "mpd"
    "wallust"
    "speech-dispatcher"
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
    ".xinitrc"
    ".Xresources"
    ".zshenv"
    ".zshrc"
    ".p10k.zsh"
    ".gitconfig"
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

# === TMUX PLUGIN MANAGER (TPM) ===
log_info "Setting up Tmux Plugin Manager (TPM)..."
TPM_DIR="$HOME/.tmux/plugins/tpm"

if [[ ! -d "$TPM_DIR" ]]; then
    log_info "Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR" || {
        log_error "Failed to clone TPM repository"
    }
    log_info "✓ TPM installed to $TPM_DIR"
    log_info "  To install plugins, run: tmux (then press Ctrl+a + I)"
else
    log_info "✓ TPM is already installed"
    log_info "  To update plugins, run: tmux (then press Ctrl+a + U)"
fi

# === BIN SCRIPTS (symlink to ~/.local/bin) ===
BIN_SOURCE="$PARENT_CONFIG_DIR/bin"
BIN_TARGET="$HOME/.local/bin"

if [[ -d "$BIN_SOURCE" ]]; then
    log_info "Creating symlinks for bin scripts..."
    mkdir -p "$BIN_TARGET"
    
    # Symlink individual executables from bin/ to ~/.local/bin
    for script in "$BIN_SOURCE"/*; do
        if [[ -f "$script" && -x "$script" ]]; then
            script_name=$(basename "$script")
            target="$BIN_TARGET/$script_name"
            
            # Safety: Check if already correctly linked
            if [[ -e "$target" ]]; then
                if [[ "$(readlink -f "$target")" == "$script" ]]; then
                    log_info "  ✓ $script_name is already correctly linked"
                    continue
                fi
                
                # Wrong link or real file. Back it up.
                BACKUP_NAME="${target}.backup_$(date +%Y%m%d_%H%M%S)"
                log_warn "  ! Existing script found. Backing up to $BACKUP_NAME"
                mv "$target" "$BACKUP_NAME"
            fi
            
            log_info "  → $BIN_TARGET/$script_name (symlink)"
            ln -s "$script" "$target"
        fi
    done
    
    log_info "✓ Bin scripts symlinked to ~/.local/bin"
else
    log_warn "  Bin directory not found (skipping)"
fi

# === SET ZSH AS DEFAULT SHELL ===
if command -v zsh &>/dev/null; then
    ZSH_PATH="$(command -v zsh)"
    if ! grep -q "^$USER:.*:$ZSH_PATH" /etc/passwd; then
        log_info "Setting zsh as default shell..."
        chsh -s "$ZSH_PATH" "$USER" || log_warn "Could not set zsh as default (may need sudo)"
    else
        log_info "✓ zsh is already the default shell"
    fi
else
    log_warn "zsh not found in PATH (skipping shell change)"
fi

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

# === SYSTEM CONFIG: SPEECH-DISPATCHER ===
SPEECHD_CONF_SOURCE="$PARENT_CONFIG_DIR/speech-dispatcher"
SPEECHD_CONF_TARGET="/etc/speech-dispatcher"

if [[ -d "$SPEECHD_CONF_SOURCE" ]]; then
    # Check if we can write to /etc/speech-dispatcher (requires sudo)
    if [[ ! -w "$SPEECHD_CONF_TARGET" ]]; then
        log_warn "⚠ /etc/speech-dispatcher is not writable (requires sudo)"
        log_warn "  Run: sudo restore-dotfiles.sh (to install Speech Dispatcher system configs)"
    else
        log_info "Creating symlinks for Speech Dispatcher system configs..."
        mkdir -p "$SPEECHD_CONF_TARGET"
        
        # Symlink speechd.conf if it exists in our config
        if [[ -f "$PARENT_CONFIG_DIR/speechd.conf" ]]; then
            target="$SPEECHD_CONF_TARGET/speechd.conf"
            
            # Safety: Check if already correctly linked
            if [[ -e "$target" ]]; then
                if [[ "$(readlink -f "$target")" == "$PARENT_CONFIG_DIR/speechd.conf" ]]; then
                    log_info "  ✓ speechd.conf is already correctly linked"
                else
                    # Wrong link or real file. Back it up.
                    BACKUP_NAME="${target}.backup_$(date +%Y%m%d_%H%M%S)"
                    log_warn "  ! Existing config found. Backing up to $BACKUP_NAME"
                    sudo mv "$target" "$BACKUP_NAME"
                    sudo ln -s "$PARENT_CONFIG_DIR/speechd.conf" "$target"
                    log_info "  → $SPEECHD_CONF_TARGET/speechd.conf (symlink)"
                fi
            else
                sudo ln -s "$PARENT_CONFIG_DIR/speechd.conf" "$target"
                log_info "  → $SPEECHD_CONF_TARGET/speechd.conf (symlink)"
            fi
        fi
        
        # Symlink modules directory
        if [[ -d "$SPEECHD_CONF_SOURCE/modules" ]]; then
            modules_target="$SPEECHD_CONF_TARGET/modules"
            
            if [[ -e "$modules_target" ]]; then
                if [[ "$(readlink -f "$modules_target")" == "$SPEECHD_CONF_SOURCE/modules" ]]; then
                    log_info "  ✓ modules directory is already correctly linked"
                else
                    BACKUP_NAME="${modules_target}.backup_$(date +%Y%m%d_%H%M%S)"
                    log_warn "  ! Existing modules found. Backing up to $BACKUP_NAME"
                    sudo mv "$modules_target" "$BACKUP_NAME"
                    sudo ln -s "$SPEECHD_CONF_SOURCE/modules" "$modules_target"
                    log_info "  → $SPEECHD_CONF_TARGET/modules (symlink)"
                fi
            else
                sudo ln -s "$SPEECHD_CONF_SOURCE/modules" "$modules_target"
                log_info "  → $SPEECHD_CONF_TARGET/modules (symlink)"
            fi
        fi
        
        log_info "✓ Speech Dispatcher system configs symlinked"
    fi
else
    log_warn "  Speech Dispatcher source not found (skipping)"
fi

# === XORG CONFIGURATION (System-wide - /etc/X11/xorg.conf.d) ===
XORG_CONF_DIR="/etc/X11/xorg.conf.d"
XORG_CONF_SOURCE="$PARENT_CONFIG_DIR/xorg.conf.d"

if [[ -d "$XORG_CONF_SOURCE" ]]; then
    log_info "Creating symlinks for Xorg configs..."
    
    # Check if we can write to /etc/X11/xorg.conf.d (requires sudo)
    if [[ ! -w "$XORG_CONF_DIR" ]]; then
        log_warn "⚠ /etc/X11/xorg.conf.d is not writable (requires sudo)"
        log_warn "  Run: sudo restore-dotfiles.sh (to install Xorg configs)"
    else
        mkdir -p "$XORG_CONF_DIR"
        
        for conf_file in "$XORG_CONF_SOURCE"/*.conf; do
            if [[ -f "$conf_file" ]]; then
                conf_name=$(basename "$conf_file")
                target="$XORG_CONF_DIR/$conf_name"
                
                # Safety: Check if already correctly linked
                if [[ -e "$target" ]]; then
                    if [[ "$(readlink -f "$target")" == "$conf_file" ]]; then
                        log_info "  ✓ $conf_name is already correctly linked"
                        continue
                    fi
                    
                    # Wrong link or real file. Back it up.
                    BACKUP_NAME="${target}.backup_$(date +%Y%m%d_%H%M%S)"
                    log_warn "  ! Existing config found. Backing up to $BACKUP_NAME"
                    sudo mv "$target" "$BACKUP_NAME"
                fi
                
                log_info "  → $XORG_CONF_DIR/$conf_name (symlink)"
                sudo ln -s "$conf_file" "$target"
            fi
        done
        
        log_info "✓ Xorg configs symlinked"
    fi
else
    log_warn "  Xorg config source not found (skipping)"
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
