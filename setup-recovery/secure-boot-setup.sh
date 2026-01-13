#!/bin/bash

# ==============================================================================
# ARCH LINUX SECURE BOOT SETUP (Elite Method v2.0)
# Features: JSON Parsing, Source Signing, Full Sync, Enrollment Safety
# Context: systemd-boot + UKI + sbctl
# ==============================================================================

set -e # Exit immediately on error

# --- Colors ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# --- 1. Prerequisites Check ---
if [ "$EUID" -ne 0 ]; then
    error "This script must be run as root (sudo)."
fi

# Ensure essential tools are installed
if ! command -v sbctl &> /dev/null || ! command -v jq &> /dev/null; then
    log "Missing dependencies. Installing sbctl and jq..."
    pacman -S --needed --noconfirm sbctl jq
fi

# --- Configuration Paths ---
BOOTLOADER_SRC="/usr/lib/systemd/boot/efi/systemd-bootx64.efi"
BOOTLOADER_SIGNED="/usr/lib/systemd/boot/efi/systemd-bootx64.efi.signed"
UKI_MAIN="/boot/EFI/Linux/arch-linux.efi"
UKI_FALLBACK="/boot/EFI/Linux/arch-linux-fallback.efi"

echo "========================================================"
echo "      INITIALIZING SECURE BOOT SETUP (v2.0)             "
echo "========================================================"

# --- 2. Initialize Keys ---
# Check if keys exist in /usr/share/secureboot/keys
if [ ! -f /usr/share/secureboot/keys/PK/PK.key ]; then
    log "Creating custom Secure Boot keys..."
    sbctl create-keys
    success "Keys created."
else
    log "Keys already exist. Skipping creation (Idempotent)."
fi

# --- 3. Sign Bootloader Source ---
# Signs the master copy so updates via pacman are automatically re-signed
log "Signing systemd-boot source binary..."
if [ -f "$BOOTLOADER_SRC" ]; then
    sbctl sign -s -o "$BOOTLOADER_SIGNED" "$BOOTLOADER_SRC"
    success "Bootloader source signed and saved to database."
else
    error "Bootloader source not found at $BOOTLOADER_SRC"
fi

# --- 4. Sign UKIs ---
log "Signing Unified Kernel Images..."
if [ -f "$UKI_MAIN" ]; then
    sbctl sign -s "$UKI_MAIN"
    success "Main UKI signed."
else
    warn "Main UKI not found at $UKI_MAIN"
fi

if [ -f "$UKI_FALLBACK" ]; then
    sbctl sign -s "$UKI_FALLBACK"
    success "Fallback UKI signed."
else
    warn "Fallback UKI not found at $UKI_FALLBACK"
fi

# --- 5. Sync Database ---
# Catch-all: Ensure everything in the sbctl db is actually signed on disk
log "Syncing all file signatures..."
sbctl sign-all
success "Database synchronized."

# --- 6. Install Bootloader ---
# Push the signed binary from /usr/lib to the EFI partition
log "Deploying signed bootloader to EFI partition..."
bootctl install
success "Bootloader updated on ESP."

# --- 7. Enroll Keys (JSON Logic) ---
log "Checking Firmware Status..."
STATUS_JSON=$(sbctl status --json)

SETUP_MODE=$(echo "$STATUS_JSON" | jq -r '.setup_mode')
SECURE_BOOT=$(echo "$STATUS_JSON" | jq -r '.secure_boot')

if [ "$SETUP_MODE" == "true" ]; then
    log "System is in Setup Mode. Enrolling keys (including Microsoft)..."
    sbctl enroll-keys -m
    success "Keys enrolled. System should now be in User Mode."
elif [ "$SECURE_BOOT" == "true" ]; then
    success "Secure Boot is ALREADY ENABLED. No action needed."
else
    warn "System is NOT in Setup Mode and Secure Boot is DISABLED."
    warn "You must reboot into BIOS and select 'Clear Secure Boot Keys' or 'Reset to Setup Mode'."
fi

# --- 8. Final Verification ---
echo ""
echo "========================================================"
echo "                SETUP COMPLETE - NEXT STEPS             "
echo "========================================================"
echo -e "1. ${YELLOW}Reboot your computer.${NC}"
echo -e "2. Enter BIOS/UEFI Setup."
echo -e "3. Change Secure Boot to '${GREEN}Enabled${NC}' (if not auto-switched)."
echo -e "4. Boot into Arch."
echo -e "5. Run ${BLUE}sbctl status${NC} to confirm."
echo ""
echo -e "${YELLOW}IMPORTANT NOTE ON UKI:${NC}"
echo -e "Since the kernel command line is baked into the UKI signature,"
echo -e "if you modify /etc/kernel/cmdline, you MUST run:"
echo -e "   ${BLUE}sudo mkinitcpio -P${NC}"
echo -e "before rebooting to re-generate and re-sign the kernel."
echo "========================================================"

# --- 9. Fix /boot Permissions (Remove Random Seed Warnings) ---
log "Setting /boot permissions to remove random seed warnings..."
sudo chown root:root /boot
sudo chmod 700 /boot             
sudo chown root:root /boot/loader/random-seed
sudo chmod 600 /boot/loader/random-seed
success "Boot permissions secured."
