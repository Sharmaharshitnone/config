//! i3-helper: High-performance i3wm event daemon
//!
//! Replaces: alternating_layouts.py + workspace-names.py
//! Single IPC connection, single process, <1ms per-event latency.
//!
//! Usage:
//!   i3-helper                     # Start (default: alternating mode)
//!   i3-helper --mode vertical     # Start with vertical tiling
//!   pkill -SIGUSR1 i3-helper      # Cycle: alt → vert → horiz → alt
//!   pkill -SIGUSR2 i3-helper      # Force refresh workspace names

use anyhow::{Context, Result};
use signal_hook::consts::{SIGUSR1, SIGUSR2};
use signal_hook::iterator::Signals;
use std::collections::HashMap;
use std::fs;
use std::process::Command as Cmd;
use std::sync::atomic::{AtomicBool, AtomicU8, Ordering};
use std::{env, thread};
use swayipc::{Connection, Event, EventType, Node, NodeLayout, NodeType, WindowChange};

// ── Tiling Modes ──────────────────────────────────────────────

const MODE_ALT: u8 = 0;
const MODE_VERT: u8 = 1;
const MODE_HORIZ: u8 = 2;

static TILING_MODE: AtomicU8 = AtomicU8::new(MODE_ALT);
static FORCE_REFRESH: AtomicBool = AtomicBool::new(false);

/// Runtime dir for PID/mode files.
/// `$XDG_RUNTIME_DIR` (portable, per-user, tmpfs on systemd) with `/tmp` fallback.
#[inline]
fn runtime_dir() -> String {
    env::var("XDG_RUNTIME_DIR").unwrap_or_else(|_| "/tmp".into())
}

#[inline]
fn pid_path() -> String {
    format!("{}/i3-helper.pid", runtime_dir())
}

#[inline]
fn mode_path() -> String {
    format!("{}/i3-tiling-mode", runtime_dir())
}

#[inline]
fn request_path() -> String {
    format!("{}/i3-helper.request", runtime_dir())
}

#[inline]
fn parse_mode(s: &str) -> Option<u8> {
    match s {
        "a" | "alternating" => Some(MODE_ALT),
        "v" | "vertical" => Some(MODE_VERT),
        "h" | "horizontal" => Some(MODE_HORIZ),
        _ => None,
    }
}

#[inline]
fn mode_label(m: u8) -> &'static str {
    match m {
        MODE_ALT => "alternating",
        MODE_VERT => "vertical",
        MODE_HORIZ => "horizontal",
        _ => "unknown",
    }
}

#[inline]
fn mode_icon(m: u8) -> &'static str {
    match m {
        MODE_ALT => "⇔ Alternating",
        MODE_VERT => "↕ Vertical",
        MODE_HORIZ => "↔ Horizontal",
        _ => "? Unknown",
    }
}

// ── App Icon Map ──────────────────────────────────────────────
// Pango markup for i3bar workspace rendering.
// Each value is a full <span> tag matching the Python version.

fn build_icon_map() -> HashMap<&'static str, &'static str> {
    HashMap::from([
        // Browsers
        ("firefox",        "<span size='x-large'>\u{E658} </span>"),
        ("google-chrome",  "<span size='x-large'>\u{F268} </span>"),
        // Terminals
        ("alacritty",      "<span size='x-large'>\u{EBCA} </span>"),
        ("kitty",          "<span size='x-large'>\u{EBCA} </span>"),
        ("st",             "<span size='x-large'>\u{EBCA} </span>"),
        // Editors
        ("code",           "<span size='x-large'>\u{F0A1E} </span>"),
        ("code-oss",       "<span size='x-large'>\u{F0A1E} </span>"),
        ("antigravity",    "<span size='x-large'>\u{E887} </span>"),
        ("nvim",           "<span size='x-large'>\u{F36F} </span>"),
        ("vim",            "<span size='x-large'>\u{E7C5} </span>"),
        ("neovide",        "<span size='x-large'>\u{F36F} </span>"),
        ("emacs",          "<span size='x-large'>\u{E632} </span>"),
        // Development
        ("jetbrains-idea",      "<span size='x-large'>\u{E7B5} </span>"),
        ("jetbrains-clion",     "<span size='x-large'>\u{E61D} </span>"),
        ("jetbrains-pycharm",   "<span size='x-large'>\u{E73C} </span>"),
        ("jetbrains-webstorm",  "<span size='x-large'>\u{F06E6} </span>"),
        ("jetbrains-rider",     "<span size='x-large'>\u{F01A7} </span>"),
        ("jetbrains-goland",    "<span size='x-large'>\u{E627} </span>"),
        ("jetbrains-datagrip",  "<span size='x-large'>\u{F1C0} </span>"),
        ("jetbrains-rubymine",  "<span size='x-large'>\u{E739} </span>"),
        ("jetbrains-phpstorm",  "<span size='x-large'>\u{E608} </span>"),
        ("postman",        "<span size='x-large'>\u{F06EE} </span>"),
        ("docker",         "<span size='x-large'>\u{F21F} </span>"),
        ("virt-manager",   "<span size='x-large'>\u{F0894} </span>"),
        ("gnome-boxes",    "<span size='x-large'>\u{F0894} </span>"),
        ("virtualbox",     "<span size='x-large'>\u{F0894} </span>"),
        // Communication
        ("telegramdesktop","<span size='x-large'>\u{F2C6} </span>"),
        ("telegram",       "<span size='x-large'>\u{F2C6} </span>"),
        ("evolution",      "<span size='x-large'>\u{F01F0} </span>"),
        // Media
        ("pavucontrol",    "<span size='x-large'>\u{F057E} </span>"),
        ("vlc",            "<span size='x-large'>\u{F057C} </span>"),
        ("mpv",            "<span size='x-large'>\u{F36E} </span>"),
        ("obs",            "<span size='x-large'>\u{F044B} </span>"),
        ("obs-studio",     "<span size='x-large'>\u{F044B} </span>"),
        ("gimp",           "<span size='x-large'>\u{F338} </span>"),
        ("inkscape",       "<span size='x-large'>\u{F33B} </span>"),
        ("steam",          "<span size='x-large'>\u{F1B6} </span>"),
        // System & Utilities
        ("thunar",         "<span size='x-large'>\u{F07B} </span>"),
        ("yazi",           "<span size='x-large'>\u{F07B} </span>"),
        ("htop",           "<span size='x-large'>\u{F04C5} </span>"),
        ("btop",           "<span size='x-large'>\u{F04C5} </span>"),
        ("gparted",        "<span size='x-large'>\u{F02CA} </span>"),
        ("clock",          "<span size='x-large'>\u{F017} </span>"),
        ("peaclock",       "<span size='x-large'>\u{F017} </span>"),
        ("calc",           "<span size='x-large'>\u{F1EC} </span>"),
        ("calculator",     "<span size='x-large'>\u{F1EC} </span>"),
        ("galculator",     "<span size='x-large'>\u{F1EC} </span>"),
        ("zathura",        "<span size='x-large'>\u{F1C1} </span>"),
        // Custom
        ("scratchpad",     "<span size='large'>\u{F0633} </span>"),
        ("main-tmux",      "<span size='x-large'>\u{EBC8} </span>"),
        ("gemini",         "<span size='x-large'>\u{F06A9} </span>"),
        ("gemini-sc",      "<span size='x-large'>\u{F06A9} </span>"),
        ("task",           "<span size='x-large'>\u{F0AE} </span>"),
        ("tasks",          "<span size='x-large'>\u{F0AE} </span>"),
        ("todo",           "<span size='x-large'>\u{F0AE} </span>"),
    ])
}

// ── Tree Traversal Utilities ──────────────────────────────────

/// Find focused container using i3's `focus` array for O(depth) guided
/// descent instead of O(n) full DFS — typically 4-5 hops vs hundreds of nodes.
fn find_focused(node: &Node) -> Option<&Node> {
    if node.focused && matches!(node.node_type, NodeType::Con | NodeType::FloatingCon) {
        return Some(node);
    }
    // i3's `focus` field lists child IDs in MRU order; first = focused path.
    if let Some(&next_id) = node.focus.first() {
        for child in node.nodes.iter().chain(node.floating_nodes.iter()) {
            if child.id == next_id {
                return find_focused(child);
            }
        }
    }
    None
}

/// Find the tiling parent of a window by searching ONLY through `nodes`.
///
/// Deliberately excludes `floating_nodes`. When a floating window
/// (scratchpad, dialog, etc.) is focused, this returns `None`, which
/// causes `handle_tiling` to skip — no special-casing needed.
#[inline]
fn find_tiling_parent(root: &Node, target_id: i64) -> Option<&Node> {
    for child in &root.nodes {
        if child.id == target_id {
            return Some(root);
        }
        if let Some(found) = find_tiling_parent(child, target_id) {
            return Some(found);
        }
    }
    None
}

/// Returns true if a workspace is i3's internal scratchpad.
/// `num == -1` is canonical + immutable. Name is a secondary guard.
#[inline]
fn is_scratchpad_workspace(ws: &Node) -> bool {
    ws.num == Some(-1) || ws.name.as_deref() == Some("__i3_scratch")
}

fn collect_workspaces<'a>(node: &'a Node, out: &mut Vec<&'a Node>) {
    if node.node_type == NodeType::Workspace {
        if !is_scratchpad_workspace(node) {
            out.push(node);
        }
        return;
    }
    for child in &node.nodes {
        collect_workspaces(child, out);
    }
}

fn collect_leaves<'a>(node: &'a Node, out: &mut Vec<&'a Node>) {
    if node.nodes.is_empty() && node.floating_nodes.is_empty() {
        if matches!(node.node_type, NodeType::Con | NodeType::FloatingCon) {
            out.push(node);
        }
        return;
    }
    for child in node.nodes.iter().chain(node.floating_nodes.iter()) {
        collect_leaves(child, out);
    }
}

#[inline]
fn window_class(node: &Node) -> Option<String> {
    node.window_properties
        .as_ref()
        .and_then(|wp| wp.class.as_ref().or(wp.instance.as_ref()))
        .map(|s| {
            // Take last token (handles multi-word classes) and lowercase
            s.split_whitespace()
                .next_back()
                .unwrap_or(s)
                .to_lowercase()
        })
}

// ── Tiling Handler ────────────────────────────────────────────
// Called on every Window::Focus event. O(n) tree traversal.
//
// Key insight: `find_tiling_parent` only walks `nodes` (not `floating_nodes`).
// If the focused window is floating (scratchpad, dialog, etc.), the parent
// search returns None and we skip. No special-casing needed.

fn handle_tiling(cmd: &mut Connection, tree: &Node) -> Result<()> {
    let focused = match find_focused(tree) {
        Some(f) => f,
        None => return Ok(()),
    };

    // find_tiling_parent returns None for floating windows (scratchpad, dialogs)
    // because it only traverses `nodes`, not `floating_nodes`.
    let parent = match find_tiling_parent(tree, focused.id) {
        Some(p) => p,
        None => return Ok(()),
    };

    // Skip tabbed/stacked — user chose that layout deliberately
    if matches!(parent.layout, NodeLayout::Tabbed | NodeLayout::Stacked) {
        return Ok(());
    }

    let mode = TILING_MODE.load(Ordering::Relaxed);

    match mode {
        MODE_ALT => {
            // Alternating: split perpendicular to longest dimension
            let r = &focused.rect;
            if r.height > r.width {
                if matches!(parent.layout, NodeLayout::SplitH) {
                    cmd.run_command("split v")?;
                }
            } else if matches!(parent.layout, NodeLayout::SplitV) {
                cmd.run_command("split h")?;
            }
        }
        MODE_VERT => {
            if !matches!(parent.layout, NodeLayout::SplitV) {
                cmd.run_command("split v")?;
            }
        }
        MODE_HORIZ => {
            if !matches!(parent.layout, NodeLayout::SplitH) {
                cmd.run_command("split h")?;
            }
        }
        _ => {}
    }

    Ok(())
}

// ── Workspace Naming ──────────────────────────────────────────
// Called on Window and Workspace events. O(w * l) where w=workspaces, l=avg leaves.

fn update_workspace_names(
    cmd: &mut Connection,
    tree: &Node,
    icons: &HashMap<&str, &str>,
) -> Result<()> {
    let mut ws_buf = Vec::with_capacity(10);
    collect_workspaces(tree, &mut ws_buf);

    // Snapshot workspace metadata before issuing mutable IPC commands.
    // Avoids borrow conflict: ws_buf borrows tree (immutable) while cmd is mutable.
    let ws_info: Vec<(String, Option<i64>)> = ws_buf
        .iter()
        .map(|ws| {
            let name = ws.name.as_deref().unwrap_or("").to_string();
            let num = ws.num.map(|n| n as i64);
            (name, num)
        })
        .collect();

    let mut leaf_buf = Vec::with_capacity(16);

    for (idx, ws) in ws_buf.iter().enumerate() {
        let (ref ws_name, ws_num) = ws_info[idx];

        leaf_buf.clear();
        collect_leaves(ws, &mut leaf_buf);

        let new_label = if let Some(first) = leaf_buf.first() {
            let cls = window_class(first)
                .or_else(|| first.name.clone())
                .unwrap_or_default();

            // Single lookup — avoids double hash
            let fallback: &str = icons.get(cls.as_str()).copied().unwrap_or(&cls);

            let ws_num_pos = ws_num.filter(|&n| n >= 0);
            match ws_num_pos {
                Some(n) => format!("{}: {}", n, fallback),
                None => {
                    let prefix: String =
                        ws_name.chars().take_while(|c| c.is_ascii_digit()).collect();
                    if let Ok(n) = prefix.parse::<i64>() {
                        format!("{}: {}", n, fallback)
                    } else {
                        fallback.to_string()
                    }
                }
            }
        } else {
            ws_name.clone()
        };

        if !new_label.is_empty() && new_label != *ws_name {
            let escaped_old = ws_name.replace('"', "\\\"");
            let escaped_new = new_label.replace('"', "\\\"");

            let rename_cmd = if !ws_name.is_empty() {
                format!(r#"rename workspace "{}" to "{}""#, escaped_old, escaped_new)
            } else if let Some(n) = ws_num {
                format!(r#"rename workspace number {} to "{}""#, n, escaped_new)
            } else {
                continue;
            };

            let _ = cmd.run_command(&rename_cmd);
        }
    }

    Ok(())
}

// ── Process Management ────────────────────────────────────────

/// If a previous buggy daemon run renamed `__i3_scratch`, restore it.
///
/// i3 hides the scratchpad workspace from the bar by checking `name == "__i3_scratch"`.
/// If the name was changed, it becomes visible in the bar and behaves like a regular
/// workspace. This repairs that damage on startup.
fn repair_scratchpad(cmd: &mut Connection, tree: &Node) {
    fn find_ws_by_num(node: &Node, target_num: i32) -> Option<&Node> {
        if node.node_type == NodeType::Workspace && node.num == Some(target_num) {
            return Some(node);
        }
        for child in &node.nodes {
            if let Some(found) = find_ws_by_num(child, target_num) {
                return Some(found);
            }
        }
        None
    }

    if let Some(ws) = find_ws_by_num(tree, -1) {
        if ws.name.as_deref() != Some("__i3_scratch") {
            let old_name = ws.name.as_deref().unwrap_or("");
            let escaped = old_name.replace('"', "\\\"");
            let _ = cmd.run_command(format!(
                r#"rename workspace "{}" to "__i3_scratch""#, escaped
            ));
            eprintln!(
                "i3-helper: repaired scratchpad workspace '{}' → '__i3_scratch'",
                old_name
            );
        }
    }
}

fn kill_previous() {
    let path = pid_path();
    if let Ok(pid_str) = fs::read_to_string(&path) {
        if let Ok(pid) = pid_str.trim().parse::<i32>() {
            if pid > 0 {
                // SAFETY: kill(2) with sig=0 checks existence without signaling.
                // PID validated > 0 to avoid killing process group 0.
                unsafe {
                    if libc::kill(pid, 0) == 0 {
                        libc::kill(pid, libc::SIGTERM);
                        thread::sleep(std::time::Duration::from_millis(50));
                    }
                }
            }
        }
    }
}

fn write_pid() -> Result<()> {
    fs::write(pid_path(), std::process::id().to_string())
        .context("Failed to write PID file")?;
    Ok(())
}

// ── Signal Setup ──────────────────────────────────────────────

fn setup_signals() -> Result<()> {
    let mut signals =
        Signals::new([SIGUSR1, SIGUSR2]).context("Failed to register signal handlers")?;

    thread::spawn(move || {
        let req_file = request_path();
        for sig in signals.forever() {
            match sig {
                SIGUSR1 => {
                    // Check for explicit mode request (from --set-mode client)
                    let next = if let Ok(req) = fs::read_to_string(&req_file) {
                        let _ = fs::remove_file(&req_file);
                        parse_mode(req.trim()).unwrap_or_else(|| {
                            (TILING_MODE.load(Ordering::Relaxed) + 1) % 3
                        })
                    } else {
                        // No request file → cycle
                        (TILING_MODE.load(Ordering::Relaxed) + 1) % 3
                    };
                    TILING_MODE.store(next, Ordering::Relaxed);
                    let label = mode_label(next);
                    let icon = mode_icon(next);
                    let _ = fs::write(mode_path(), label);
                    let _ = Cmd::new("notify-send")
                        .args(["-t", "1500", "-h", "string:x-canonical-private-synchronous:tiling", "Tiling Mode", icon])
                        .spawn();
                }
                SIGUSR2 => {
                    FORCE_REFRESH.store(true, Ordering::Relaxed);
                }
                _ => {}
            }
        }
    });

    Ok(())
}

// ── Main ──────────────────────────────────────────────────────

fn main() -> Result<()> {
    let args: Vec<String> = env::args().collect();
    let mut initial_mode = MODE_ALT;
    let mut set_mode_request: Option<String> = None;
    let mut i = 1;
    while i < args.len() {
        match args[i].as_str() {
            "--set-mode" | "-s" => {
                i += 1;
                if i < args.len() {
                    set_mode_request = Some(args[i].clone());
                } else {
                    eprintln!("--set-mode requires a value: alternating|vertical|horizontal");
                    std::process::exit(1);
                }
            }
            "--mode" | "-m" => {
                i += 1;
                if i < args.len() {
                    initial_mode = parse_mode(&args[i]).unwrap_or_else(|| {
                        eprintln!("Unknown mode '{}', using alternating", args[i]);
                        MODE_ALT
                    });
                }
            }
            "--help" | "-h" => {
                println!("i3-helper: high-performance i3wm event daemon");
                println!();
                println!("Usage:");
                println!("  i3-helper [OPTIONS]              Start daemon");
                println!("  i3-helper --set-mode <MODE>      Set mode on running daemon");
                println!();
                println!("Options:");
                println!("  -m, --mode <MODE>      Initial tiling mode");
                println!("  -s, --set-mode <MODE>  Signal running daemon to switch mode");
                println!("  -h, --help             Show this help");
                println!();
                println!("Modes: alternating (a) | vertical (v) | horizontal (h)");
                println!();
                println!("Signals:");
                println!("  SIGUSR1  Cycle tiling mode (alt → vert → horiz → alt)");
                println!("  SIGUSR2  Force refresh workspace names");
                return Ok(());
            }
            _ => {}
        }
        i += 1;
    }

    // Client mode: signal running daemon to set a specific mode
    if let Some(mode_str) = set_mode_request {
        if parse_mode(&mode_str).is_none() {
            eprintln!("Unknown mode '{}'. Use: alternating|vertical|horizontal", mode_str);
            std::process::exit(1);
        }
        // Write request file, then signal daemon
        fs::write(request_path(), &mode_str)
            .context("Failed to write mode request")?;
        let pid_file = pid_path();
        if let Ok(pid_str) = fs::read_to_string(&pid_file) {
            if let Ok(pid) = pid_str.trim().parse::<i32>() {
                if pid > 0 {
                    unsafe { libc::kill(pid, libc::SIGUSR1) };
                }
            }
        } else {
            eprintln!("i3-helper daemon not running (no PID file)");
            std::process::exit(1);
        }
        return Ok(());
    }

    // Ensure i3 socket is discoverable (swayipc checks I3SOCK → SWAYSOCK → i3 --get-socketpath)
    if env::var("I3SOCK").is_err() && env::var("SWAYSOCK").is_err() {
        if let Ok(output) = Cmd::new("i3").arg("--get-socketpath").output() {
            if output.status.success() {
                let path = String::from_utf8_lossy(&output.stdout).trim().to_string();
                // SAFETY: single-threaded at this point (before thread::spawn)
                unsafe { env::set_var("I3SOCK", &path) };
            }
        }
    }

    // Kill any previous instance
    kill_previous();

    // Initialize state
    TILING_MODE.store(initial_mode, Ordering::Relaxed);
    let _ = fs::write(mode_path(), mode_label(initial_mode));
    write_pid()?;

    // Signal handlers (SIGUSR1 = cycle mode, SIGUSR2 = force refresh)
    setup_signals()?;

    let icons = build_icon_map();

    // Command connection (for get_tree + run_command)
    let mut cmd_conn = Connection::new().context("Failed to connect to i3 (command channel)")?;

    // Repair scratchpad if a previous buggy run renamed it, then initial name sync
    if let Ok(tree) = cmd_conn.get_tree() {
        repair_scratchpad(&mut cmd_conn, &tree);
    }
    if let Ok(tree) = cmd_conn.get_tree() {
        let _ = update_workspace_names(&mut cmd_conn, &tree, &icons);
    }

    // Event connection (subscribes to window + workspace events; blocking iterator)
    let event_iter = Connection::new()
        .context("Failed to connect to i3 (event channel)")?
        .subscribe([EventType::Window, EventType::Workspace])
        .context("Failed to subscribe to i3 events")?;

    eprintln!(
        "i3-helper: started (pid={}, mode={})",
        std::process::id(),
        mode_label(initial_mode)
    );

    for event in event_iter {
        let event = match event {
            Ok(e) => e,
            Err(e) => {
                eprintln!("i3-helper: event error: {e}");
                break; // Connection lost — i3 will restart us via exec_always
            }
        };

        let (do_tiling, do_names) = match &event {
            Event::Window(w) => (
                w.change == WindowChange::Focus,
                matches!(
                    w.change,
                    WindowChange::Focus
                        | WindowChange::New
                        | WindowChange::Close
                        | WindowChange::Move
                        | WindowChange::Title
                ),
            ),
            Event::Workspace(_) => (false, true),
            _ => (false, false),
        };

        let force = FORCE_REFRESH.swap(false, Ordering::Relaxed);

        if do_tiling || do_names || force {
            // Single get_tree() call serves both handlers
            if let Ok(tree) = cmd_conn.get_tree() {
                if do_tiling {
                    let _ = handle_tiling(&mut cmd_conn, &tree);
                }
                if do_names || force {
                    let _ = update_workspace_names(&mut cmd_conn, &tree, &icons);
                }
            }
        }
    }

    // Cleanup on exit
    let _ = fs::remove_file(pid_path());
    let _ = fs::remove_file(mode_path());

    Ok(())
}