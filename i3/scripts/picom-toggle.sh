#!/bin/bash

if ! pkill -x picom 2>/dev/null; then
    picom -b
fi
pkill -RTMIN+13 i3status-rs
