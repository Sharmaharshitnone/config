#!/usr/bin/env bash
# Setup Recovery Script - Install ONLY explicitly installed packages
# This installs only packages you chose, not auto-dependencies
# Dependencies are resolved automatically by pacman/yay

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
PACKAGES_FILE="${SCRIPT_DIR}/installed-packages.txt"

if [[ ! -f "$PACKAGES_FILE" ]]; then
    log_error "Package list not found: $PACKAGES_FILE"
    exit 1
fi

log_info "System Recovery Mode - Installing Arch Linux packages"
TOTAL_PKGS=$(wc -l < "$PACKAGES_FILE")
log_info "Total packages to install: $TOTAL_PKGS"

# Sync package database first
log_info "Syncing package database..."
sudo pacman -Sy 2>&1 | grep -v "downloading" || true

# Install all packages (pacman will install from repos, yay will handle AUR)
log_info "Installing packages via pacman and yay..."
log_warn "Note: Invalid/missing packages will be skipped by pacman/yay"

# Try to install with pacman first (will catch official repos)
xargs -r sudo pacman -S --needed --noconfirm < "$PACKAGES_FILE" 2>&1 || log_warn "Pacman install finished (some packages may have failed)"

# Then try yay for AUR packages (will skip what's already installed)
log_info "Installing AUR packages with yay..."
xargs -r yay -S --needed --noconfirm < "$PACKAGES_FILE" 2>&1 || log_warn "Yay install finished (some packages may have failed)"

log_info "✓ Installation complete!"
log_info "Future updates: pacman -Syu && yay -Syu"
