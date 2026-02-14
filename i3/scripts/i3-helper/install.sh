#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
BOLD='\033[1m'
RESET='\033[0m'

# Check Rust toolchain
if ! command -v cargo &>/dev/null; then
    echo -e "${RED}${BOLD}Error:${RESET} cargo not found. Install with: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    exit 1
fi

echo -e "${BOLD}Building i3-helper (release)...${RESET}"
cargo build --release 2>&1

BINARY="$SCRIPT_DIR/target/release/i3-helper"

if [[ ! -f "$BINARY" ]]; then
    echo -e "${RED}${BOLD}Build failed.${RESET}"
    exit 1
fi

SIZE=$(du -h "$BINARY" | cut -f1)
echo -e "${GREEN}${BOLD}✓ Built:${RESET} $BINARY ($SIZE)"

# Ensure symlink exists: ~/.config/i3 -> ~/work/config/i3
I3_CONFIG_DIR="$HOME/.config/i3"
WORK_I3_DIR="$HOME/work/config/i3"
if [[ -L "$I3_CONFIG_DIR" ]]; then
    echo -e "${GREEN}✓${RESET} Symlink exists: $I3_CONFIG_DIR -> $(readlink "$I3_CONFIG_DIR")"
elif [[ ! -e "$I3_CONFIG_DIR" ]]; then
    ln -s "$WORK_I3_DIR" "$I3_CONFIG_DIR"
    echo -e "${GREEN}✓${RESET} Created symlink: $I3_CONFIG_DIR -> $WORK_I3_DIR"
else
    echo -e "${RED}Warning:${RESET} $I3_CONFIG_DIR exists and is not a symlink. Manage manually."
fi

# Kill existing Python daemons and old helper
pkill -f 'alternating_layouts.py' 2>/dev/null || true
pkill -f 'workspace-names.py' 2>/dev/null || true
pkill -x 'i3-helper' 2>/dev/null || true
sleep 0.2

# Start the new daemon
"$BINARY" &
disown

echo -e "${GREEN}${BOLD}✓ i3-helper started (pid=$!)${RESET}"
echo ""
echo "i3 config already updated. Reload i3 with \$mod+Shift+r"
echo ""
echo "Keybindings:"
echo "  \$mod+'         → goto mark"
echo "  \$mod+Shift+'   → set mark"
echo "  \$mod+Ctrl+'    → swap with mark"
echo "  \$mod+t         → cycle tiling mode (alt/vert/horiz)"
echo "  \$mod+Shift+u   → unmark focused"