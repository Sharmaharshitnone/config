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
log_debug() { echo -e "${BLUE}[DEBUG]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_FILE="${SCRIPT_DIR}/installed-packages.txt"

if [[ ! -f "$PACKAGES_FILE" ]]; then
    log_error "Package list not found: $PACKAGES_FILE"
    exit 1
fi

log_info "System Recovery Mode - EXPLICIT PACKAGES ONLY"
TOTAL_PKGS=$(wc -l < "$PACKAGES_FILE")
log_info "Total explicit packages to install: $TOTAL_PKGS"
log_debug "Dependencies will be auto-resolved by pacman/yay"
log_info "(vs 1429 total with auto-dependencies)"

# Create temp files for native and AUR packages
NATIVE_PKGS=$(mktemp)
AUR_PKGS=$(mktemp)

trap "rm -f $NATIVE_PKGS $AUR_PKGS" EXIT

log_info "Separating native and AUR packages..."
NATIVE_COUNT=0
AUR_COUNT=0

while read -r pkg_name; do
    [[ -z "$pkg_name" ]] && continue
    
    # Check if package is in official repos (native)
    if pacman -Si "$pkg_name" &>/dev/null 2>&1; then
        echo "$pkg_name" >> "$NATIVE_PKGS"
        ((NATIVE_COUNT++))
    else
        echo "$pkg_name" >> "$AUR_PKGS"
        ((AUR_COUNT++))
    fi
done < "$PACKAGES_FILE"

log_info "Found: $NATIVE_COUNT native packages, $AUR_COUNT AUR packages"

# Install native packages
if [[ $NATIVE_COUNT -gt 0 ]]; then
    log_info "Installing native packages (pacman resolves dependencies)..."
    if cat "$NATIVE_PKGS" | xargs sudo pacman -S --needed 2>&1; then
        log_info "✓ Native packages installed"
    else
        log_warn "Some native packages failed to install"
    fi
fi

# Install AUR packages with yay
if [[ $AUR_COUNT -gt 0 ]]; then
    log_info "Installing AUR packages with yay (yay resolves dependencies)..."
    if cat "$AUR_PKGS" | xargs yay -S --needed 2>&1; then
        log_info "✓ AUR packages installed"
    else
        log_warn "Some AUR packages failed to install"
    fi
fi

log_info "✓ Installation complete!"
log_info "Future updates: pacman -Syu && yay -Syu"
