#!/bin/bash

if pgrep -x "picom" > /dev/null; then
    killall picom
else
    picom -b
fi
pkill -RTMIN+12 i3status-rs
