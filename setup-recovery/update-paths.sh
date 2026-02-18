#!/usr/bin/env bash
# update-paths.sh — Fix machine-specific paths after cloning to a new location.
#
# Use this when:
#   • You already have everything installed on another machine.
#   • The dotfiles are cloned to a DIFFERENT directory than the original machine.
#   • You just need to update sudoers + config paths — no full reinstall.
#
# What it does:
#   1. Regenerates /etc/sudoers.d/kb-rgb and /etc/sudoers.d/warp using the
#      canonical realpath of the scripts in THIS clone location.
#   2. Patches the hardcoded kb-rgb path in dunst/scripts/kb-rgb-glow.
#   3. Patches the hardcoded kb-rgb path in i3/config.d/keyboard-rgb.conf.
#   4. Symlinks bin/ contents to ~/.local/bin/ (idempotent).
#
# Usage:
#   cd /path/to/this/config/setup-recovery
#   bash update-paths.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
die()   { echo -e "${RED}[ERR]${NC}   $*" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"   # the config repo root

info "Config root: $CONFIG_DIR"

# ── 1. Sudoers ────────────────────────────────────────────────────────────────
setup_sudoers() {
    local script="$1" sudoers_file="$2"
    local real_path
    real_path=$(realpath "$script") || die "Cannot resolve realpath of $script"
    [[ -x "$real_path" ]] || warn "$real_path is not executable — chmod +x it"
    local rule="$USER ALL=(ALL) NOPASSWD: $real_path"
    if [[ -f "$sudoers_file" ]] && [[ "$(cat "$sudoers_file")" == "$rule" ]]; then
        info "  ✓ sudoers $(basename "$sudoers_file") already up-to-date"
        return
    fi
    printf '%s\n' "$rule" | sudo tee "$sudoers_file" > /dev/null
    sudo chmod 0440 "$sudoers_file"
    info "  → $(basename "$sudoers_file") → NOPASSWD $real_path"
}

info "Updating sudoers rules..."
setup_sudoers "$CONFIG_DIR/bin/kb-rgb" /etc/sudoers.d/kb-rgb
setup_sudoers "$CONFIG_DIR/bin/warp"   /etc/sudoers.d/warp

# ── 2. Patch dunst glow hook ──────────────────────────────────────────────────
KB_REAL=$(realpath "$CONFIG_DIR/bin/kb-rgb")
GLOW_HOOK="$CONFIG_DIR/dunst/scripts/kb-rgb-glow"
if [[ -f "$GLOW_HOOK" ]]; then
    sed -i "s|exec sudo [^ ]*/kb-rgb glow-flash|exec sudo $KB_REAL glow-flash|g" "$GLOW_HOOK"
    info "Patched dunst glow hook → $KB_REAL"
else
    warn "dunst glow hook not found: $GLOW_HOOK (skipping)"
fi

# ── 3. Patch i3 keyboard-rgb.conf ────────────────────────────────────────────
KB_I3CONF="$CONFIG_DIR/i3/config.d/keyboard-rgb.conf"
if [[ -f "$KB_I3CONF" ]]; then
    sed -i "s|set \\\$kb .*|set \$kb $KB_REAL|" "$KB_I3CONF"
    info "Patched i3 config \$kb → $KB_REAL"
else
    warn "i3 keyboard-rgb.conf not found: $KB_I3CONF (skipping)"
fi

# ── 4. Symlink bin/ → ~/.local/bin ───────────────────────────────────────────
BIN_SOURCE="$CONFIG_DIR/bin"
BIN_TARGET="$HOME/.local/bin"
mkdir -p "$BIN_TARGET"
info "Symlinking bin/ → $BIN_TARGET ..."
for item in "$BIN_SOURCE"/*; do
    item_name=$(basename "$item")
    target="$BIN_TARGET/$item_name"
    [[ -e "$item" ]] || continue
    if [[ -e "$target" ]] && [[ "$(readlink -f "$target")" == "$item" ]]; then
        info "  ✓ $item_name already linked"
        continue
    fi
    [[ -e "$target" ]] && mv "$target" "${target}.bak_$(date +%Y%m%d_%H%M%S)"
    ln -s "$item" "$target"
    [[ -f "$item" ]] && chmod +x "$item" 2>/dev/null || true
    info "  → $item_name"
done

info ""
info "Done. Next steps:"
info "  1. Reload i3:   \$mod+Shift+r"
info "  2. Reload dunst: pkill dunst && dunst &"
info "  3. Test:         warp status   (no password prompt)"
info "               sudo kb-rgb status"
