#!/bin/bash

# Read input (actions) from dunst
# Dunst sends actions separated by newlines. We generally want to execute 'default' or the first one.
read -r first_action

# debug
# echo "App: $DUNST_APP_NAME" >> /tmp/dunst_click.log

# Focus the app in i3
if [ -n "$DUNST_APP_NAME" ]; then
    # Log with rotation (keep last 100 lines)
    log_file="/tmp/dunst_click.log"
    echo "--- $(date) ---" >> "$log_file"
    echo "App: $DUNST_APP_NAME" >> "$log_file"
    echo "Summary: $DUNST_SUMMARY" >> "$log_file"
    
    # Rotate log if > 200 lines (keep last 100)
    if [ -f "$log_file" ] && [ $(wc -l < "$log_file") -gt 200 ]; then
        tail -n 100 "$log_file" > "${log_file}.tmp" && mv "${log_file}.tmp" "$log_file"
    fi

    # Convert to lowercase for class matching (e.g. Firefox -> firefox)
    app_lower="${DUNST_APP_NAME,,}"

    # Strategy 1: Smart Keyword Match
    # Extract the first significant word from the summary (e.g. "WhatsApp Message" -> "WhatsApp")
    # This helps catch "WhatsApp - Mozilla Firefox" windows even if the summary has extra text.
    if [ -n "$DUNST_SUMMARY" ]; then
        keyword=$(echo "$DUNST_SUMMARY" | awk '{print $1}')
        
        # Only use if keyword is meaningful (len > 2)
        if [ ${#keyword} -gt 2 ]; then
            if i3-msg "[title=\"(?i)$keyword\"] focus" > /dev/null 2>&1; then
                echo "Focused via keyword match: $keyword" >> "$log_file"
                matched="yes"
            fi
        fi
    fi

    # Strategy 2: Match title using App Name (e.g. "Firefox" title check)
    if [ -z "$matched" ] && i3-msg "[title=\"(?i)$DUNST_APP_NAME\"] focus" > /dev/null 2>&1; then
        echo "Focused via app title: $DUNST_APP_NAME" >> "$log_file"
        matched="yes"
    fi

    # Strategy 3: Exact class match (lowercase: Firefox -> firefox)
    if [ -z "$matched" ] && i3-msg "[class=\"^$app_lower$\"] focus" > /dev/null 2>&1; then
        echo "Focused via lowercase class: $app_lower" >> "$log_file"
        matched="yes"
    fi

    # Strategy 4: Exact class match (original)
    if [ -z "$matched" ] && i3-msg "[class=\"^$DUNST_APP_NAME$\"] focus" > /dev/null 2>&1; then
        echo "Focused via exact class: $DUNST_APP_NAME" >> "$log_file"
        matched="yes"
    fi
    
    if [ -z "$matched" ]; then
        echo "Failed to find window." >> "$log_file"
    fi
fi

# Return the action to dunst so it can proceed (e.g., executing the default action usually associated with clicking)
# If 'default' is in the list, returning it triggers the default action (like opening a URL).
if [ -n "$first_action" ]; then
    echo "$first_action"
else
    echo "default"
fi
