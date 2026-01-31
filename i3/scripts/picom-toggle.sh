#!/bin/bash
# Picom toggle script - Audit-fixed race condition
# Uses pkill's atomic check-and-kill to prevent race between pgrep and killall

if ! pkill -x picom 2>/dev/null; then
    # pkill returns 1 if no process matched, so picom wasn't running - start it
    picom -b
fi
pkill -RTMIN+13 i3status-rs
