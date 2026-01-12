#!/usr/bin/env bash
# Bootstrap script - Install yay if missing, then run main installer
# This handles fresh Arch installations where yay doesn't exist yet
# Includes: 205 packages + configs (nvim, kitty, zsh, i3, sway, mpd, etc) + optimizations

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_debug() { echo -e "${BLUE}[DEBUG]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if yay is already installed
if command -v yay &>/dev/null; then
    log_info "✓ yay is already installed"
    log_info "yay version: $(yay --version)"
else
    log_warn "yay not found - installing now..."
    log_info "Step 1: Installing base-devel (required for AUR compilation)"
    
    # Install base-devel if not present (needed for makepkg)
    if ! pacman -Qi base-devel &>/dev/null; then
        log_info "Installing base-devel group..."
        sudo pacman -S --needed base-devel
    else
        log_info "✓ base-devel already installed"
    fi
    
    log_info "Step 2: Cloning yay from AUR..."
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR" EXIT
    
    cd "$TEMP_DIR"
    git clone https://aur.archlinux.org/yay.git
    cd yay
    
    log_info "Step 3: Building and installing yay (this may take a minute)..."
    makepkg -si --noconfirm
    
    log_info "✓ yay installed successfully!"
    log_debug "yay version: $(yay --version)"
    
    cd "$SCRIPT_DIR"
fi

# Verify yay works
log_info "Verifying yay installation..."
if yay --version; then
    log_info "✓ yay is working correctly"
else
    log_error "yay installation failed!"
    exit 1
fi
# === OPTIMIZATION PHASE ===
log_info "Optimizing pacman configuration..."

# Enable Parallel Downloads for faster installation
log_debug "Enabling parallel downloads..."
if ! grep -q "^ParallelDownloads" /etc/pacman.conf; then
    sudo sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
    log_info "✓ Enabled ParallelDownloads in /etc/pacman.conf"
fi

# Refresh mirrors for fastest download speeds
log_debug "Ranking fastest mirrors..."
if command -v reflector &>/dev/null; then
    log_info "Updating mirror list with reflector..."
    sudo reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist 2>/dev/null || log_warn "Reflector update failed (continuing anyway)"
    log_info "✓ Mirror list updated"
else
    log_warn "Reflector not installed (using default mirrors)"
fi
# Now run the main installer (explicit packages only)
log_info "Starting package installation..."
log_info "=================================================="
"$SCRIPT_DIR/install-packages.sh"

# After packages installed, restore dotfiles
log_info "=================================================="
log_info "Packages installed! Now restoring your configs..."
log_info "=================================================="
"$SCRIPT_DIR/restore-dotfiles.sh"

log_info "✓ Full recovery complete!"

# === OPTIONAL: PERFORMANCE OPTIMIZATION ===
log_info ""
log_info "=================================================="
log_info "Optional: System Performance Optimization"
log_info "=================================================="
log_info "This will optimize your system for i7-13620H:"
log_info "  • zRAM: High-performance compressed swap (4GB)"
log_info "  • ccache: Instant C++ re-compilation caching"
log_info ""
read -p "Enable performance optimizations? (y/n) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "Running performance optimization..."
    
    # === 1. zRAM High-Performance Swap ===
    log_info "Installing zRAM with zstd compression..."
    if sudo pacman -S --needed --noconfirm zram-generator &>/dev/null; then
        ZRAM_CONF="/etc/systemd/zram-generator.conf"
        cat << 'ZRAM_EOF' | sudo tee "$ZRAM_CONF" >/dev/null
[zram0]
# High-performance compressed swap for i7-13620H (16GB RAM)
zram-size = min(ram / 2, 4096)
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
ZRAM_EOF
        sudo systemctl daemon-reload
        sudo systemctl start /dev/zram0
        log_info "✓ zRAM configured with zstd compression"
    fi
    
    # === 2. ccache Configuration ===
    log_info "Installing ccache for accelerated builds..."
    if sudo pacman -S --needed --noconfirm ccache &>/dev/null; then
        # Set cache size
        ccache -M 50G
        
        # Enable in makepkg
        MAKEPKG_CONF="/etc/makepkg.conf"
        if grep -q "!ccache" "$MAKEPKG_CONF"; then
            sudo sed -i 's/!ccache/ccache/g' "$MAKEPKG_CONF"
            log_info "✓ Enabled ccache in makepkg.conf"
        fi
        
        # Add to PATH
        PROFILE_SCRIPT="/etc/profile.d/10-ccache.sh"
        echo 'export PATH="/usr/lib/ccache/bin:$PATH"' | sudo tee "$PROFILE_SCRIPT" >/dev/null
        sudo chmod +x "$PROFILE_SCRIPT"
        log_info "✓ ccache configured (50GB cache, PATH updated)"
        
        # Show status
        echo ""
        log_info "Performance Status:"
        if command -v zramctl &>/dev/null; then
            zramctl 2>/dev/null || true
        fi
        ccache -s 2>/dev/null | head -5 || true
        log_info "✓ Performance optimization complete!"
    fi
else
    log_info "Skipping performance optimization"
fi

# === OPTIONAL: SECURE BOOT SETUP ===
log_info ""
log_info "=================================================="
log_info "Optional: Secure Boot Setup (sbctl + UKI)"
log_info "=================================================="
log_info "Configure systemd-boot with Secure Boot signing."
log_info "Note: Requires sbctl installed and UEFI firmware"
log_info ""
read -p "Setup Secure Boot? (y/n) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [[ -x "$SCRIPT_DIR/secure-boot-setup.sh" ]]; then
        log_info "Running Secure Boot setup (v2.0)..."
        sudo "$SCRIPT_DIR/secure-boot-setup.sh"
        log_info "✓ Secure Boot configuration complete!"
    else
        log_error "secure-boot-setup.sh not found or not executable"
    fi
else
    log_info "Skipping Secure Boot setup"
fi

# === OPTIONAL: ENABLE USER SERVICES ===
log_info ""
log_info "=================================================="
log_info "Optional: Enable User Systemd Services"
log_info "=================================================="
log_info "Enables: mpd (Music Player Daemon)"
log_info ""
read -p "Enable user services? (y/n) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [[ -x "$SCRIPT_DIR/enable-services.sh" ]]; then
        log_info "Running service enablement..."
        "$SCRIPT_DIR/enable-services.sh"
        log_info "✓ User services configured!"
    else
        log_error "enable-services.sh not found or not executable"
    fi
else
    log_info "Skipping user service enablement"
fi

# === OPTIONAL: BOOT TIME OPTIMIZATION ===
log_info ""
log_info "=================================================="
log_info "Optional: Boot Time Optimization"
log_info "=================================================="
log_info "Optimize for i7-13620H: systemd initramfs + lz4 compression"
log_info "Target: < 4 seconds total boot time"
log_info ""
read -p "Optimize boot time? (y/n) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [[ -x "$SCRIPT_DIR/boot-optimization.sh" ]]; then
        log_info "Running boot optimization..."
        sudo "$SCRIPT_DIR/boot-optimization.sh"
        log_info "✓ Boot optimization complete!"
        log_info "⚠️  Please reboot to apply changes: sudo reboot"
    else
        log_error "boot-optimization.sh not found or not executable"
    fi
else
    log_info "Skipping boot time optimization"
fi
