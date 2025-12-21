# NOTE::  Custom function to fully update and clean an Arch Linux system.
# Uses pacman and yay, prioritizing safety and thoroughness.
# Optimized System Update & Maintenance
# Logs to: ~/.local/state/upclean/update_history.log

update_clean() {
    # --- Configuration ---
    local LOG_DIR="$HOME/.local/state/upclean"
    local LOG_FILE="$LOG_DIR/update_history.log"
    local MAX_LOG_SIZE=5242880 # 5MB

    # ANSI Colors for professional output
    local BOLD="\033[1m"
    local GREEN="\033[1;32m"
    local BLUE="\033[1;34m"
    local YELLOW="\033[1;33m"
    local RESET="\033[0m"

    # 0. Safety Check
    if [ "$EUID" -eq 0 ]; then
       echo -e "${YELLOW}[!] Error:${RESET} Do not run this as root. yay will ask for privileges."
       return 1
    fi

    # Create log directory
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR"
    fi

    # Log Rotation
    if [ -f "$LOG_FILE" ] && [ $(stat -c%s "$LOG_FILE") -ge $MAX_LOG_SIZE ]; then
        echo ":: Log file limit reached. Rotating..."
        tail -c $((MAX_LOG_SIZE / 2)) "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
    fi

    # --- Execution Block ---
    {
        echo "----------------------------------------------------------------"
        echo ":: Session Started: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "----------------------------------------------------------------"

        echo -e "${BLUE}::${RESET} ${BOLD}Initializing System Update...${RESET}"

        # 1. Keyring
        echo -e "${BLUE}->${RESET} Refreshing Arch Keyring..."
        sudo pacman -Sy --needed --noconfirm archlinux-keyring

        # 2. Main Update
        echo -e "${BLUE}->${RESET} Syncing Official Repos & AUR..."
        # --noprogressbar keeps logs clean
        yay -Syu --combinedupgrade --noprogressbar || return 1

        echo ""
        echo -e "${BLUE}::${RESET} ${BOLD}System Maintenance${RESET}"

        # 3. Orphans
        echo -e "${BLUE}->${RESET} Pruning orphaned dependencies..."
        yay -Yc --noconfirm

        # 4. Cache
        echo -e "${BLUE}->${RESET} Cleaning package cache (Retaining last 2)..."
        sudo paccache -rk2 2>&1
        sudo paccache -ruk0 2>&1

        # 5. Build Files
        echo -e "${BLUE}->${RESET} Cleaning AUR build headers..."
        yay -Sc --noconfirm

        echo ""
        echo -e "${GREEN}[OK]${RESET} System update and optimization complete."
        echo ":: Session Ended: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "----------------------------------------------------------------"

    } 2>&1 | tee -a "$LOG_FILE"
}

alias upclean='update_clean'
