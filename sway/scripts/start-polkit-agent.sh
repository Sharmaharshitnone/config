#!/usr/bin/env bash
# Start policykit GNOME authentication agent once DBUS session is available.
# Wait for /run/user/$UID/bus and then ensure no agent is already registered.

set -euo pipefail

BUS_SOCKET="/run/user/$(id -u)/bus"
AGENT_BIN="/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"

# Timeout for waiting for DBUS socket (seconds)
WAIT_TIMEOUT=10
WAIT_INTERVAL=0.2

start_time=$(date +%s)
while [ ! -S "$BUS_SOCKET" ]; do
    now=$(date +%s)
    if [ $((now - start_time)) -ge $WAIT_TIMEOUT ]; then
        echo "polkit agent: timeout waiting for DBUS socket $BUS_SOCKET" >&2
        exit 1
    fi
    sleep $WAIT_INTERVAL
done

# If an authentication agent is already registered for this unix-session, exit
if journalctl -b --no-pager | rg -q "Registered Authentication Agent for unix-session"; then
    # There may already be an agent registered; try to detect if it's for this user
    # and avoid starting a second one.
    echo "polkit agent: an authentication agent is already registered; skipping start" >&2
    exit 0
fi

# Start agent if binary exists
if [ -x "$AGENT_BIN" ]; then
    nohup "$AGENT_BIN" >/dev/null 2>&1 &
    disown
    echo "polkit agent: started $AGENT_BIN" >&2
    exit 0
else
    echo "polkit agent: binary not found at $AGENT_BIN" >&2
    exit 2
fi
