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
    "Thunar"
    "atuin"
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
    log_info "Creating symlinks for bin contents..."
    mkdir -p "$BIN_TARGET"
    
    # Symlink ALL items (files and directories) from bin/ to ~/.local/bin
    for item in "$BIN_SOURCE"/*; do
        item_name=$(basename "$item")
        target="$BIN_TARGET/$item_name"
        
        # Skip if item doesn't exist
        [[ -e "$item" ]] || continue
        
        # Safety: Check if already correctly linked
        if [[ -e "$target" ]]; then
            if [[ "$(readlink -f "$target")" == "$item" ]]; then
                log_info "  ✓ $item_name is already correctly linked"
                continue
            fi
            
            # Wrong link or real item. Back it up.
            BACKUP_NAME="${target}.backup_$(date +%Y%m%d_%H%M%S)"
            log_warn "  ! Existing item found. Backing up to $BACKUP_NAME"
            mv "$target" "$BACKUP_NAME"
        fi
        
        # Create symlink for files or directories
        if [[ -d "$item" ]]; then
            log_info "  → $BIN_TARGET/$item_name/ (symlink)"
        else
            log_info "  → $BIN_TARGET/$item_name (symlink)"
        fi
        ln -s "$item" "$target"
        
        # Make executable if it's a file
        [[ -f "$item" ]] && chmod +x "$item" 2>/dev/null || true
    done
    
    log_info "✓ Bin contents symlinked to ~/.local/bin"
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

# === SHELDON (Zsh Plugin Manager) ===
if command -v sheldon &>/dev/null; then
    log_info "Installing Sheldon plugins..."
    
    # Set config directory to match .zshrc setup
    SHELDON_CONFIG="$CONFIG_HOME/zsh/plugins.toml"
    
    if [[ -f "$SHELDON_CONFIG" ]]; then
        log_info "  Found plugins.toml at $SHELDON_CONFIG"
        
        # Lock and install plugins (creates lockfile + downloads plugins)
        # Use SHELDON_CONFIG_DIR to match the .zshrc eval line
        if SHELDON_CONFIG_DIR="$CONFIG_HOME/zsh" sheldon lock --update 2>&1 | tee /tmp/sheldon-install.log; then
            log_info "✓ Sheldon plugins installed successfully"
            
            # Show what was installed
            PLUGIN_COUNT=$(grep -c "^\[plugins\." "$SHELDON_CONFIG" 2>/dev/null || echo "0")
            log_info "  Installed $PLUGIN_COUNT plugin(s) from config"
            
            # Check lockfile was created
            LOCKFILE="$HOME/.local/share/sheldon/plugins.lock"
            if [[ -f "$LOCKFILE" ]]; then
                log_info "  ✓ Lockfile generated: $LOCKFILE"
            fi
        else
            log_warn "Sheldon plugin installation encountered issues (check /tmp/sheldon-install.log)"
        fi
    else
        log_warn "  plugins.toml not found at $SHELDON_CONFIG"
        log_warn "  Sheldon will install plugins on first shell launch"
    fi
else
    log_warn "sheldon not installed (plugins will auto-install on first zsh launch)"
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

# === KITTY → XTERM SYMLINK (System-wide - /usr/bin) ===
log_info "Creating Kitty→xterm symlink..."

# Check if kitty is installed
if command -v kitty &>/dev/null; then
    KITTY_PATH="$(command -v kitty)"
    XTERM_LINK="/usr/bin/xterm"
    
    # Check if /usr/bin/xterm already points to kitty
    if [[ -L "$XTERM_LINK" ]] && [[ "$(readlink -f "$XTERM_LINK")" == "$KITTY_PATH" ]]; then
        log_info "  ✓ /usr/bin/xterm already points to kitty"
    else
        # Check if xterm package is installed
        if pacman -Q xterm &>/dev/null; then
            log_info "  → Removing xterm package via pacman..."
            sudo pacman -Rns xterm --noconfirm || {
                log_warn "Failed to remove xterm package (may have dependencies)"
                log_warn "Run manually: sudo pacman -Rns xterm"
                log_warn "Or force: sudo pacman -Rdd xterm --noconfirm"
            }
        fi
        
        # Remove any remaining xterm binary/symlink
        if [[ -e "$XTERM_LINK" ]]; then
            sudo rm -f "$XTERM_LINK"
            log_info "  → Removed existing /usr/bin/xterm"
        fi
        
        # Create the symlink
        sudo ln -sf "$KITTY_PATH" "$XTERM_LINK"
        log_info "  ✓ Created symlink: /usr/bin/xterm → $KITTY_PATH"
    fi
else
    log_warn "  ✗ kitty not installed (cannot create xterm symlink)"
fi

# === KEYD CONFIGURATION (System-wide - /etc/keyd) ===
KEYD_CONF_SOURCE="$PARENT_CONFIG_DIR/keyd"
KEYD_CONF_TARGET="/etc/keyd"

if [[ -d "$KEYD_CONF_SOURCE" ]]; then
    log_info "Creating symlink for keyd config..."
    
    if [[ ! -w "$KEYD_CONF_TARGET" ]] && [[ ! -w "/etc" ]]; then
        log_warn "⚠ /etc/keyd is not writable (requires sudo)"
        log_warn "  Run: sudo ln -sf $KEYD_CONF_SOURCE/default.conf /etc/keyd/default.conf"
    else
        sudo mkdir -p "$KEYD_CONF_TARGET"
        
        for conf_file in "$KEYD_CONF_SOURCE"/*.conf; do
            if [[ -f "$conf_file" ]]; then
                conf_name=$(basename "$conf_file")
                target="$KEYD_CONF_TARGET/$conf_name"
                
                if [[ -e "$target" ]] && [[ "$(readlink -f "$target")" == "$conf_file" ]]; then
                    log_info "  ✓ $conf_name is already correctly linked"
                else
                    [[ -e "$target" ]] && sudo mv "$target" "${target}.backup_$(date +%Y%m%d_%H%M%S)"
                    sudo ln -sf "$conf_file" "$target"
                    log_info "  → /etc/keyd/$conf_name (symlink)"
                fi
            fi
        done
        
        # Reload keyd if running
        if systemctl is-active --quiet keyd; then
            sudo keyd reload
            log_info "  ✓ keyd reloaded"
        fi
    fi
else
    log_warn "  keyd config not found in $KEYD_CONF_SOURCE"
fi

# === Make all shell scripts executable ===
log_info "Making all shell scripts executable..."
find "$PARENT_CONFIG_DIR" -type f \( -name "*.sh" -o -name "*.py" \) 2>/dev/null | while read -r script; do
    if [[ -f "$script" && ! -x "$script" ]]; then
        chmod +x "$script"
        log_info "  ✓ chmod +x: $(basename "$script")"
    fi
done

# === BUILD i3-helper (Rust binary) ===
I3_HELPER_DIR="$PARENT_CONFIG_DIR/i3/scripts/i3-helper"
if [[ -f "$I3_HELPER_DIR/Cargo.toml" ]]; then
    log_info "Building i3-helper (Rust binary for i3wm auto-tiling + workspace icons)..."
    if command -v cargo &>/dev/null; then
        if (cd "$I3_HELPER_DIR" && cargo build --release 2>&1); then
            BINARY="$I3_HELPER_DIR/target/release/i3-helper"
            if [[ -x "$BINARY" ]]; then
                SIZE=$(du -h "$BINARY" | cut -f1)
                log_info "  ✓ i3-helper built successfully ($SIZE)"
            fi
        else
            log_warn "  ✗ i3-helper build failed (check Rust toolchain)"
        fi
    else
        log_warn "  ✗ cargo not found — install Rust toolchain first (rustup)"
        log_warn "    Run: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    fi
else
    log_warn "  i3-helper source not found (skipping build)"
fi

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
log_info "  1. Reload shell: exec zsh (or source \$HOME/.zshrc)"
log_info "  2. Verify plugins loaded: sheldon source (or echo \$ZSH_HIGHLIGHT_STYLES)"
log_info "  3. Test: nvim, kitty, i3 keybinds, etc."
log_info "  4. If needed, restart i3/sway: \$mod+Shift+r"
log_info ""
log_info "Plugin updates (future):"
log_info "  SHELDON_CONFIG_DIR=\$ZDOTDIR sheldon lock --update"
