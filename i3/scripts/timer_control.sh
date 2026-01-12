#!/usr/bin/env bash

STATE_FILE="/tmp/i3_timer.state"

# Initialize state if missing
if [ ! -f "$STATE_FILE" ]; then
    echo "STOPPED 0 0" > "$STATE_FILE" # Status StartTime AccumulatedTime
fi

read -r STATUS START_TIME ACC_TIME < "$STATE_FILE"
NOW=$(date +%s)

case "$1" in
    "toggle")
        if [ "$STATUS" = "RUNNING" ]; then
            # Pause: Add elapsed time to accumulator
            ELAPSED=$((NOW - START_TIME))
            NEW_ACC=$((ACC_TIME + ELAPSED))
            echo "STOPPED 0 $NEW_ACC" > "$STATE_FILE"
        else
            # Start: Record start time
            echo "RUNNING $NOW $ACC_TIME" > "$STATE_FILE"
        fi
        ;;
    "reset")
        echo "STOPPED 0 0" > "$STATE_FILE"
        ;;
    "read")
        if [ "$STATUS" = "RUNNING" ]; then
            ELAPSED=$((NOW - START_TIME + ACC_TIME))
            ICON="<span size='large' weight='bold'></span>" # Running icon
            STATE="Info"
        else
            ELAPSED=$ACC_TIME
            ICON="" # Paused icon
            STATE="Idle"
        fi

        # Format time MM:SS
        MIN=$((ELAPSED / 60))
        SEC=$((ELAPSED % 60))
        TIME_STR=$(printf "%02d:%02d" $MIN $SEC)

        # Output JSON for i3status-rust
        # Combine icon and text for better compatibility
        echo "{\"text\": \"$ICON <span rise='1000'>$TIME_STR</span>\", \"state\": \"$STATE\"}"
        ;;
esac
