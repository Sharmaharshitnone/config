#!/usr/bin/env bash

# ==============================================================================
# ARCH LINUX BOOT TIME OPTIMIZATION (Elite Method v1.0)
# Context: i7-13620H | systemd-boot + UKI | Target: < 4 seconds boot
# ==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

if [ "$EUID" -ne 0 ]; then
    error "This script must be run as root (sudo)."
fi

echo "========================================================"
echo "      BOOT TIME OPTIMIZATION (Elite Method)"
echo "========================================================"

# === STEP 1: Diagnostics ===
log "Collecting boot diagnostics..."
echo ""
echo "--- OVERALL BOOT TIME ---"
systemd-analyze || true
echo ""
echo "--- TOP 10 SLOWEST SERVICES ---"
systemd-analyze blame | head -10 || true
echo ""
echo "--- CRITICAL DEPENDENCY CHAIN ---"
systemd-analyze critical-chain || true
echo ""

# Offer to generate SVG plot
read -p "Generate visual boot plot? (SVG) (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    systemd-analyze plot > /tmp/boot_plot.svg
    log "Boot plot saved to: /tmp/boot_plot.svg"
fi

# === STEP 2: Initramfs Optimization ===
log "Optimizing initramfs (mkinitcpio.conf)..."

MKINITCPIO_CONF="/etc/mkinitcpio.conf"

# Backup original
if [ ! -f "${MKINITCPIO_CONF}.bak" ]; then
    cp "$MKINITCPIO_CONF" "${MKINITCPIO_CONF}.bak"
    success "Backed up: ${MKINITCPIO_CONF}.bak"
fi

# Update HOOKS to systemd-based (parallel loading)
if grep -q "^HOOKS=" "$MKINITCPIO_CONF"; then
    sed -i 's/^HOOKS=.*/HOOKS=(systemd autodetect modconf kms keyboard sd-vconsole block filesystems fsck)/' "$MKINITCPIO_CONF"
    success "Updated HOOKS to systemd-based (allows parallel initialization)"
fi

# Update COMPRESSION to lz4 (faster decompression)
if grep -q "^COMPRESSION=" "$MKINITCPIO_CONF"; then
    sed -i 's/^COMPRESSION=.*/COMPRESSION="lz4"/' "$MKINITCPIO_CONF"
    success "Updated COMPRESSION to lz4 (faster decompression)"
fi

# === STEP 3: Kernel Parameters ===
log "Optimizing kernel command line..."

KERNEL_CMDLINE="/etc/kernel/cmdline"

if [ -f "$KERNEL_CMDLINE" ]; then
    # Backup original
    if [ ! -f "${KERNEL_CMDLINE}.bak" ]; then
        cp "$KERNEL_CMDLINE" "${KERNEL_CMDLINE}.bak"
        success "Backed up: ${KERNEL_CMDLINE}.bak"
    fi
    
    # Read current cmdline
    CURRENT_CMDLINE=$(cat "$KERNEL_CMDLINE")
    
    # Add boot parameters if not present
    if ! echo "$CURRENT_CMDLINE" | grep -q "quiet"; then
        CURRENT_CMDLINE="$CURRENT_CMDLINE quiet"
    fi
    if ! echo "$CURRENT_CMDLINE" | grep -q "loglevel="; then
        CURRENT_CMDLINE="$CURRENT_CMDLINE loglevel=3"
    fi
    if ! echo "$CURRENT_CMDLINE" | grep -q "nowatchdog"; then
        CURRENT_CMDLINE="$CURRENT_CMDLINE nowatchdog"
    fi
    if ! echo "$CURRENT_CMDLINE" | grep -q "fastboot"; then
        CURRENT_CMDLINE="$CURRENT_CMDLINE fastboot"
    fi
    
    echo "$CURRENT_CMDLINE" > "$KERNEL_CMDLINE"
    success "Updated kernel cmdline with: quiet loglevel=3 nowatchdog fastboot"
    log "New cmdline: $CURRENT_CMDLINE"
else
    warn "Kernel cmdline not found at $KERNEL_CMDLINE"
fi

# === STEP 4: Boot Timeout ===
log "Setting boot menu timeout..."

if command -v bootctl &>/dev/null; then
    bootctl set-timeout 0
    success "Set bootctl timeout to 0 (instant boot)"
else
    warn "bootctl not found (systemd-boot may not be installed)"
fi

# === STEP 5: Service Optimization ===
log "Disabling slow/unnecessary services..."

# Services to disable
declare -a SERVICES_TO_DISABLE=(
    "systemd-networkd-wait-online.service"
    "NetworkManager-wait-online.service"
    "cups.service"
)

for service in "${SERVICES_TO_DISABLE[@]}"; do
    if systemctl is-enabled "$service" &>/dev/null 2>&1; then
        systemctl disable "$service" 2>/dev/null && success "Disabled: $service" || true
    fi
done

# === STEP 6: Rebuild UKI ===
log "Rebuilding Unified Kernel Image (applying all changes)..."
if mkinitcpio -P; then
    success "UKI rebuilt successfully"
else
    error "UKI rebuild failed. Check logs above."
fi

echo ""
echo "========================================================"
echo "                OPTIMIZATION COMPLETE"
echo "========================================================"
echo ""
echo "Changes Made:"
echo "  ✓ Initramfs: Switched to systemd hooks (parallel loading)"
echo "  ✓ Compression: Changed to lz4 (faster decompression)"
echo "  ✓ Kernel params: quiet + loglevel=3 + nowatchdog + fastboot"
echo "  ✓ Boot timeout: Set to 0 (instant boot menu)"
echo "  ✓ Services: Disabled wait-online, cups"
echo ""
echo "Next Steps:"
echo "  1. Reboot your system: sudo reboot"
echo "  2. After reboot, check new boot time: systemd-analyze"
echo "  3. Compare with baseline (see diagnostics above)"
echo ""
echo "Expected Improvements:"
echo "  • Initrd time: -40-60% (systemd hooks + lz4)"
echo "  • Userspace time: -1-2s (disabled wait-online)"
echo "  • Target: Kernel + Userspace < 4 seconds"
echo ""
echo "Backups (if needed to revert):"
echo "  • ${MKINITCPIO_CONF}.bak"
echo "  • ${KERNEL_CMDLINE}.bak"
echo "========================================================"
