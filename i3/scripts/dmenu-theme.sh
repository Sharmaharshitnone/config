# ── Shared dmenu theme (Catppuccin-inspired dark) ─────────────
# Source this in any script: . ~/.config/i3/scripts/dmenu-theme.sh
# Then call: dmenu $DMENU_THEME [extra args...]
#
# Colors: dark bg, light text, light selection bar
DMENU_NB='#000000'
DMENU_NF='#ffffff'
DMENU_SB='#f5f5f5'
DMENU_SF='#1e1e2e'
DMENU_FN='JetBrainsMono Nerd Font:size=11'

# Pre-built argument string for direct use
DMENU_THEME="-nb '$DMENU_NB' -nf '$DMENU_NF' -sb '$DMENU_SB' -sf '$DMENU_SF' -fn '$DMENU_FN'"

# Wrapper function — call instead of bare `dmenu`
# Includes -i for case-insensitive matching by default
dmenu_themed() {
    dmenu -i -nb "$DMENU_NB" -nf "$DMENU_NF" -sb "$DMENU_SB" -sf "$DMENU_SF" -fn "$DMENU_FN" "$@"
}

# Wrapper for dmenu_run
dmenu_run_themed() {
    dmenu_run -nb "$DMENU_NB" -nf "$DMENU_NF" -sb "$DMENU_SB" -sf "$DMENU_SF" -fn "$DMENU_FN" "$@"
}
