#!/bin/bash

# Wrapper to control both auto-cpufreq and TLP
# Requires Polkit rules for passwordless execution

MODE=$1

case "$MODE" in
    "performance")
        pkexec auto-cpufreq --force=performance
        pkexec tlp ac
        notify-send "󱐌 High Performance" "CPU: Performance | TLP: AC Mode" -u critical
        ;;
    "powersave")
        pkexec auto-cpufreq --force=powersave
        pkexec tlp power-saver
        notify-send " Power Saver" "CPU: Powersave | TLP: Battery Mode" -u low
        ;;
    "reset")
        pkexec auto-cpufreq --force=reset
        pkexec tlp start
        notify-send "🤖 Auto Mode" "System returned to automatic management" -u normal
        ;;
    *)
        echo "Usage: $0 {performance|powersave|reset}"
        exit 1
        ;;
esac
