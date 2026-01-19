#!/bin/bash

if pgrep -x "picom" > /dev/null; then
    killall picom
else
    picom -b
fi
pkill -RTMIN+13 i3status-rs
