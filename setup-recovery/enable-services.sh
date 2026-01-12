#!/usr/bin/env bash
# Enable user systemd services (interactive)
# Services enabled: mpd, and other user-level services

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# === User Services to Enable ===
declare -A USER_SERVICES=(
    ["mpd"]="Music Player Daemon (audio playback)"
    ["mpd-mpris"]="MPRIS protocol bridge for MPD (dbus/media control)"
    ["gdrive"]="Rclone mount for Google Drive (auto-mount on login)"
)

echo "========================================================"
echo "      Enabling User Systemd Services"
echo "========================================================"
echo ""
log_info "Available user services:"
echo ""

# Display available services with descriptions
for service in "${!USER_SERVICES[@]}"; do
    echo "  • $service - ${USER_SERVICES[$service]}"
done

echo ""
log_info "Checking installed services..."
echo ""

ENABLED_COUNT=0

# Enable each installed service
for service in "${!USER_SERVICES[@]}"; do
    # Check if service exists for user (systemd looks in ~/.config/systemd/user/)
    if systemctl --user list-unit-files | grep -q "^$service\.service"; then
        echo -n "  [$service] Service found. Enable? (y/n) "
        read -r -n 1 REPLY
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if systemctl --user enable --now "$service.service" 2>/dev/null; then
                log_info "✓ Enabled and started: $service"
                ((ENABLED_COUNT++))
            else
                log_warn "  Could not enable $service (may need to be installed)"
            fi
        else
            log_info "  Skipped: $service"
        fi
    else
        log_warn "  ✗ Not installed: $service"
    fi
done

echo ""
echo "========================================================"
if [ $ENABLED_COUNT -gt 0 ]; then
    log_info "✓ Enabled $ENABLED_COUNT user service(s)"
else
    log_warn "No services were enabled"
fi
echo "========================================================"
echo ""
log_info "To check service status later:"
echo "  systemctl --user status mpd"
echo "  systemctl --user list-units --type=service"
echo ""
log_info "To restart a service:"
echo "  systemctl --user restart mpd"
