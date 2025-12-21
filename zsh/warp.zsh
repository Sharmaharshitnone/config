# --- Elite WARP Control (Immutable DNS Protection) ---

warp() {
    local conn_status warp_state exit_ip colo
    
    # Your custom DNS (applied when WARP disconnects)
    local -r CLEARNET_DNS='# Custom DNS configuration
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1'
    # Should we stop the warp-svc system service after a disconnect?
    # true  = stop service (zero RAM when idle, requires sudo on stop/start)
    # false = leave service running for instant reconnects (uses ~30MB RAM)
    local -r STOP_SERVICE_ON_DISCONNECT=true
    
    # 1. Ensure daemon is running
    if ! systemctl is-active --quiet warp-svc; then
        echo ":: Starting WARP daemon..."
        sudo systemctl start warp-svc || {
            echo "[!] Failed to start. Check: sudo systemctl status warp-svc" >&2
            return 1
        }
        
        # Wait for CLI socket
        local i=0
        while ((i++ < 20)); do
            warp-cli status &>/dev/null && break
            sleep 0.1
        done
        
        ((i > 20)) && {
            echo "[!] Daemon unresponsive after 2s" >&2
            return 1
        }
    fi

    # 2. Detect connection state (robust parsing)
    conn_status=$(warp-cli status 2>/dev/null)
    warp_state=$(echo "$conn_status" | awk '
        /Status/ && /Connected/ {print "connected"; exit}
        /Status/ && /Disconnected/ {print "disconnected"; exit}
        /Status/ && /Connecting/ {print "connecting"; exit}
    ')

    case "$warp_state" in
        connected)
            echo "[-] Disconnecting..."
            warp-cli disconnect
            
            # Wait for WARP to finish DNS cleanup (critical timing)
            sleep 1
            
            echo ":: Restoring custom DNS..."
            echo "$CLEARNET_DNS" | sudo tee /etc/resolv.conf >/dev/null

            # Lock file to prevent overwrites
            sudo chattr +i /etc/resolv.conf

            # Optionally stop the service to reclaim RAM. This is safe because
            # we've already asked the daemon to disconnect and restored DNS.
            if [[ "$STOP_SERVICE_ON_DISCONNECT" == "true" ]]; then
                if sudo systemctl is-active --quiet warp-svc; then
                    echo ":: Stopping warp-svc to save RAM (requires sudo)..."
                    sudo systemctl stop warp-svc || echo "[!] Failed to stop warp-svc" >&2
                    # small pause to ensure systemd cleans up sockets
                    sleep 0.1
                fi
            fi

            echo "[OFF] CLEARNET | DNS: 8.8.8.8 (Locked)"
            ;;
            
        disconnected|connecting)
            # Unlock DNS file if protected
            if lsattr /etc/resolv.conf 2>/dev/null | grep -q -- '----i'; then
                echo ":: Unlocking DNS for WARP..."
                sudo chattr -i /etc/resolv.conf
            fi
            
            echo "[+] Establishing tunnel..."
            warp-cli connect || {
                echo "[!] Failed:" >&2
                warp-cli status >&2
                return 1
            }
            
            # Verify tunnel works (wait for full handshake)
            sleep 1.5
            local trace=$(timeout 3 curl -sf https://www.cloudflare.com/cdn-cgi/trace 2>/dev/null)
            
            if [[ -z "$trace" ]]; then
                echo "[!] No response (check captive portal)" >&2
                return 1
            fi
            
            if echo "$trace" | grep -q 'warp=on'; then
                exit_ip=$(echo "$trace" | awk -F= '/^ip=/ {print $2}')
                colo=$(echo "$trace" | awk -F= '/^colo=/ {print $2}')
                echo "[OK] SECURED | ${exit_ip} via ${colo}"
            else
                echo "[WARN] Tunnel established but traffic not routed" >&2
            fi
            ;;
            
        *)
            echo "[?] Unknown state. Raw output:" >&2
            echo "$conn_status" >&2
            return 1
            ;;
    esac
}

# Quick status (no toggle)
wstat() {
    systemctl is-active --quiet warp-svc || {
        echo "Service: stopped"
        return 0
    }
    
    warp-cli status 2>/dev/null || echo "[!] Daemon running but CLI unresponsive"
}
