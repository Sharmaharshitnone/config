#!/usr/bin/env bash
# Setup Recovery Script - Configure ly as default greeter
# Copies configuration files from ly-configs/ to system locations and enables the service

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "\n${BLUE}→${NC} $1"; }

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_SOURCE_DIR="$CONFIG_BASE_DIR/ly-configs"

# Verify source directory exists
if [[ ! -d "$CONFIG_SOURCE_DIR" ]]; then
    log_error "Configuration source directory not found: $CONFIG_SOURCE_DIR"
    log_error "Expected: $CONFIG_SOURCE_DIR"
    exit 1
fi

echo "========================================================"
echo "    Configuring Ly as Default Greeter"
echo "========================================================"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root"
    echo "Run: sudo $0"
    exit 1
fi

# Verify ly is installed
if ! pacman -Q ly &>/dev/null; then
    log_error "ly package is not installed"
    log_info "Install it with: pacman -S ly"
    exit 1
fi

log_step "Creating symlinks to configuration files..."

# Create symlink for systemd service
log_info "Linking ly systemd service..."
mkdir -p /etc/systemd/system/multi-user.target.wants
SYSTEMD_LINK="/etc/systemd/system/multi-user.target.wants/ly@tty2.service"
SYSTEMD_SOURCE="$CONFIG_SOURCE_DIR/etc/systemd/system/ly@tty2.service"

# Remove existing symlink/file if it exists
if [[ -e "$SYSTEMD_LINK" || -L "$SYSTEMD_LINK" ]]; then
    rm -f "$SYSTEMD_LINK"
fi
ln -s "$SYSTEMD_SOURCE" "$SYSTEMD_LINK"
log_info "✓ Service symlink created"

# Create symlinks for PAM configurations
log_info "Linking PAM configurations..."
mkdir -p /etc/pam.d

# Link ly PAM config
LY_PAM_LINK="/etc/pam.d/ly"
LY_PAM_SOURCE="$CONFIG_SOURCE_DIR/etc/pam.d/ly"
if [[ -e "$LY_PAM_LINK" || -L "$LY_PAM_LINK" ]]; then
    rm -f "$LY_PAM_LINK"
fi
ln -s "$LY_PAM_SOURCE" "$LY_PAM_LINK"

# Link ly-autologin PAM config
LY_AUTOLOGIN_LINK="/etc/pam.d/ly-autologin"
LY_AUTOLOGIN_SOURCE="$CONFIG_SOURCE_DIR/etc/pam.d/ly-autologin"
if [[ -e "$LY_AUTOLOGIN_LINK" || -L "$LY_AUTOLOGIN_LINK" ]]; then
    rm -f "$LY_AUTOLOGIN_LINK"
fi
ln -s "$LY_AUTOLOGIN_SOURCE" "$LY_AUTOLOGIN_LINK"
log_info "✓ PAM config symlinks created"

# Link doas configuration
log_info "Linking doas configuration..."
DOAS_LINK="/etc/doas.conf"
DOAS_SOURCE="$CONFIG_SOURCE_DIR/etc/doas.conf"

if [[ -e "$DOAS_LINK" || -L "$DOAS_LINK" ]]; then
    rm -f "$DOAS_LINK"
fi
ln -s "$DOAS_SOURCE" "$DOAS_LINK"
log_info "✓ Doas config symlink created"

log_step "Reloading systemd and enabling service..."

# Reload systemd daemon to recognize new service
systemctl daemon-reload
log_info "✓ Systemd daemon reloaded"

# Enable and start the service
if systemctl enable /etc/systemd/system/multi-user.target.wants/ly@tty2.service 2>/dev/null; then
    log_info "✓ Service enabled at boot"
else
    log_warn "Service already enabled"
fi

log_step "Verifying installation..."

# Verify service is installed
if systemctl list-unit-files | grep -q "^ly@tty2.service"; then
    log_info "✓ Service registered: $(systemctl list-unit-files | grep 'ly@tty2')"
else
    log_error "Failed to register service"
    exit 1
fi

# Check current PAM configurations
log_info "✓ PAM configuration verified"

# Display final status
echo ""
echo "========================================================"
log_info "✓ Ly greeter setup complete!"
echo "========================================================"
echo ""
log_info "To start ly immediately on tty2:"
echo "  systemctl start ly@tty2.service"
echo ""
log_info "To check service status:"
echo "  systemctl status ly@tty2.service"
echo ""
log_info "To view ly logs:"
echo "  journalctl -u ly@tty2.service -n 20 -f"
echo ""
log_info "Next reboot will automatically start ly on tty2"
echo ""
