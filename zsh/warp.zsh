# --- WARP shortcuts (logic in ~/work/config/bin/warp) ---
# The actual script is root-owned at bin/warp with sudoers NOPASSWD.
# 'warp' is already in PATH via ~/.local/bin symlink.

# Quick status alias (avoids sudo overhead for read-only check)
wstat() {
    systemctl is-active --quiet warp-svc || {
        echo "Service: stopped"
        return 0
    }
    warp-cli status 2>/dev/null || echo "[!] Daemon running but CLI unresponsive"
}
