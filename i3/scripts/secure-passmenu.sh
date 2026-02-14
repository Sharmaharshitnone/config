#!/bin/bash

# Source shared dmenu theme
. ~/.config/i3/scripts/dmenu-theme.sh

# 1. Temporarily disable clipmenud monitoring
clipctl disable

# 2. Run passmenu with themed dmenu
passmenu -nb "$DMENU_NB" -nf "$DMENU_NF" -sb "$DMENU_SB" -sf "$DMENU_SF" -fn "$DMENU_FN"

# 3. Re-enable clipmenud monitoring
clipctl enable
