#!/usr/bin/env bash
# =============================================================================
# ATUIN MASTERY PRACTICE LAB
# =============================================================================
# This script seeds your atuin history with realistic commands, then walks you
# through 30 progressive drills covering every Atuin feature.
#
# Usage:   chmod +x atuin/practice/atuin-drills.sh
#          ./atuin/practice/atuin-drills.sh
#
# NOTE: This script ONLY prints instructions. It never modifies your config.
#       You execute the drills yourself in your terminal.
# =============================================================================

set -euo pipefail

# --- Colors ---
BOLD="\033[1m"
GREEN="\033[1;32m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
DIM="\033[2m"
RESET="\033[0m"

# --- Helper ---
section() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD}${GREEN}  $1${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

drill() {
    local num="$1"
    shift
    echo ""
    echo -e "  ${YELLOW}DRILL #${num}${RESET}: ${BOLD}$1${RESET}"
    shift
    echo -e "  ${DIM}────────────────────────────────────────────${RESET}"
    for line in "$@"; do
        echo -e "  $line"
    done
    echo ""
    echo -e "  ${DIM}Press Enter when done...${RESET}"
    read -r
}

# =============================================================================
section "PHASE 0 — VERIFY YOUR INSTALLATION"
# =============================================================================

drill 0 "Health Check" \
    "Run these commands and verify output:" \
    "" \
    "  ${CYAN}atuin --version${RESET}        # Should show 18.12.1" \
    "  ${CYAN}atuin doctor${RESET}           # Diagnoses common issues" \
    "  ${CYAN}atuin info${RESET}             # Shows config paths, version, env vars" \
    "  ${CYAN}atuin status${RESET}           # Shows sync status (if logged in)" \
    "" \
    "✓ If doctor shows issues, fix them before continuing."

# =============================================================================
section "PHASE 1 — BASIC NAVIGATION (Drills 1-5)"
# =============================================================================

drill 1 "Open the TUI with Ctrl-R" \
    "Press ${BOLD}Ctrl-R${RESET} in your shell." \
    "" \
    "Observe:" \
    "  • The search bar (bottom or top depending on 'invert')" \
    "  • The columns: exit | duration | time | command" \
    "  • The help bar at the bottom" \
    "  • Total command count in the bottom-right" \
    "" \
    "Press ${BOLD}Esc${RESET} to close without selecting anything."

drill 2 "Open the TUI with Up Arrow" \
    "Press the ${BOLD}Up Arrow (↑)${RESET} key." \
    "" \
    "Notice the difference:" \
    "  • With our config, Up Arrow filters to ${BOLD}current directory only${RESET}" \
    "  • Ctrl-R searches ${BOLD}globally${RESET} across all hosts" \
    "" \
    "This is the power of filter_mode_shell_up_key_binding = 'directory'" \
    "Close with Esc."

drill 3 "Select and Execute a Command" \
    "Open TUI (Ctrl-R), navigate to any command, then:" \
    "" \
    "  ${CYAN}Enter${RESET}  → Immediately executes (enter_accept = true)" \
    "  ${CYAN}Tab${RESET}    → Places command in your prompt for editing" \
    "" \
    "Practice both! Tab is safer when you want to modify arguments."

drill 4 "Navigate with Arrow Keys" \
    "Open TUI (Ctrl-R), then practice:" \
    "" \
    "  ${CYAN}↑ / Ctrl-N / Ctrl-K${RESET}    Move UP in the list (older)" \
    "  ${CYAN}↓ / Ctrl-P / Ctrl-J${RESET}    Move DOWN in the list (newer)" \
    "  ${CYAN}← / Ctrl-B${RESET}             Move cursor LEFT in search query" \
    "  ${CYAN}→ / Ctrl-F${RESET}             Move cursor RIGHT in search query" \
    "  ${CYAN}Home / Ctrl-A${RESET}           Jump to start of search query" \
    "  ${CYAN}End / Ctrl-E${RESET}            Jump to end of search query" \
    "  ${CYAN}Page Up${RESET}                Scroll results one page up" \
    "  ${CYAN}Page Down${RESET}              Scroll results one page down"

drill 5 "Quick Select with Alt-N" \
    "Open TUI (Ctrl-R). Notice the numbers ${BOLD}1-9${RESET} beside each entry." \
    "" \
    "  ${CYAN}Alt-1${RESET}  → Select the 1st item" \
    "  ${CYAN}Alt-5${RESET}  → Select the 5th item" \
    "  ${CYAN}Alt-9${RESET}  → Select the 9th item" \
    "" \
    "This is the fastest way to pick a recent command without scrolling."

# =============================================================================
section "PHASE 2 — SEARCH MODES (Drills 6-10)"
# =============================================================================

drill 6 "Fuzzy Search (Default)" \
    "Open TUI, type: ${CYAN}gitcm${RESET}" \
    "" \
    "Fuzzy matches 'git commit', 'git checkout main', etc." \
    "The letters don't need to be contiguous — just in order." \
    "" \
    "Now try: ${CYAN}^git${RESET}  (prefix match: only commands STARTING with 'git')" \
    "Now try: ${CYAN}.log\$${RESET} (suffix match: only commands ENDING with '.log')" \
    "Now try: ${CYAN}'exact${RESET} (exact match: only commands containing literal 'exact')" \
    "Now try: ${CYAN}!docker${RESET} (inverse: commands NOT containing 'docker')"

drill 7 "Cycle Search Modes with Ctrl-S" \
    "Open TUI, then press ${BOLD}Ctrl-S${RESET} repeatedly." \
    "" \
    "Watch the mode indicator change:" \
    "  fuzzy → prefix → fulltext → skim → fuzzy" \
    "" \
    "  ${BOLD}prefix${RESET}:    Your query matches the START of commands" \
    "  ${BOLD}fulltext${RESET}:  Your query matches ANYWHERE (substring)" \
    "  ${BOLD}fuzzy${RESET}:     fzf-style matching (our default)" \
    "  ${BOLD}skim${RESET}:      skim-style matching (similar to fuzzy)"

drill 8 "Combined Fuzzy Operators" \
    "Open TUI, try this compound query:" \
    "" \
    "  ${CYAN}^git commit | ^git push${RESET}" \
    "" \
    "The | (pipe) is an OR operator in fuzzy mode." \
    "This finds commands starting with 'git commit' OR 'git push'."

drill 9 "Prefix Search for Exact Recall" \
    "Switch to prefix mode (Ctrl-S until 'prefix' shows)." \
    "" \
    "Type: ${CYAN}sudo pacman${RESET}" \
    "" \
    "Only commands that literally start with 'sudo pacman' appear." \
    "This is useful when you know exactly how a command begins."

drill 10 "Fulltext Substring Search" \
    "Switch to fulltext mode (Ctrl-S until 'fulltext' shows)." \
    "" \
    "Type: ${CYAN}--force${RESET}" \
    "" \
    "This finds ANY command containing '--force' anywhere." \
    "Great for finding that dangerous flag you used last week."

# =============================================================================
section "PHASE 3 — FILTER MODES (Drills 11-16)"
# =============================================================================

drill 11 "Cycle Filter Modes with Ctrl-R" \
    "Inside the TUI, press ${BOLD}Ctrl-R${RESET} repeatedly." \
    "" \
    "Watch the filter cycle:" \
    "  global → host → session → workspace → directory" \
    "" \
    "  ${BOLD}global${RESET}:    All commands from all machines" \
    "  ${BOLD}host${RESET}:      Only commands from THIS machine" \
    "  ${BOLD}session${RESET}:   Only commands from THIS shell session" \
    "  ${BOLD}workspace${RESET}: Only commands from THIS git repository" \
    "  ${BOLD}directory${RESET}: Only commands from THIS exact directory"

drill 12 "Directory Filter (The Killer Feature)" \
    "cd into a project directory:" \
    "" \
    "  ${CYAN}cd ~/work/config${RESET}" \
    "" \
    "Now press ${BOLD}Up Arrow${RESET}. You'll ONLY see commands you ran here." \
    "This is because filter_mode_shell_up_key_binding = 'directory'." \
    "" \
    "Now cd elsewhere and press Up — completely different commands!"

drill 13 "Workspace Filter (Git-Aware)" \
    "cd into any subdirectory of a git repo:" \
    "" \
    "  ${CYAN}cd ~/work/config/zsh${RESET}" \
    "" \
    "Open TUI (Ctrl-R), cycle to 'workspace' filter." \
    "You'll see commands from ANY directory within the config repo." \
    "This is because workspaces = true in your config."

drill 14 "Session Filter" \
    "Open a NEW terminal (kitty shortcut or i3 keybind)." \
    "Run some unique commands:" \
    "" \
    "  ${CYAN}echo 'session-test-alpha'${RESET}" \
    "  ${CYAN}echo 'session-test-bravo'${RESET}" \
    "" \
    "Now open TUI, cycle to 'session' filter." \
    "Only those 2 commands (plus any others from this session) appear."

drill 15 "Host Filter" \
    "Open TUI, cycle to 'host' filter." \
    "" \
    "This shows all commands from THIS machine only." \
    "If you sync across machines, other hosts' commands are hidden." \
    "" \
    "Useful when you have identical repos on laptop + desktop."

drill 16 "Context Switch (Ctrl-A, C)" \
    "Open TUI, select a command from a different directory." \
    "Now press ${BOLD}Ctrl-A${RESET} then ${BOLD}C${RESET}." \
    "" \
    "This switches context to the SELECTED command's session." \
    "You'll see all commands from that command's shell session." \
    "" \
    "Press Ctrl-A, C again to return to your original context."

# =============================================================================
section "PHASE 4 — INSPECTOR & MANAGEMENT (Drills 17-20)"
# =============================================================================

drill 17 "Open the Inspector (Ctrl-O)" \
    "Open TUI, select any command, then press ${BOLD}Ctrl-O${RESET}." \
    "" \
    "The Inspector shows:" \
    "  • Full command text (unwrapped)" \
    "  • Working directory where it was run" \
    "  • Timestamp and duration" \
    "  • Exit code" \
    "  • Host and session info" \
    "" \
    "Navigation in Inspector:" \
    "  ${CYAN}↑/↓${RESET}       Browse adjacent commands" \
    "  ${CYAN}Enter${RESET}     Execute this command" \
    "  ${CYAN}Tab${RESET}       Edit this command" \
    "  ${CYAN}Ctrl-D${RESET}    DELETE this entry from history" \
    "  ${CYAN}Ctrl-O${RESET}    Back to search" \
    "  ${CYAN}Esc${RESET}       Back to shell"

drill 18 "Delete a Specific History Entry" \
    "Sometimes you accidentally record a secret. Fix it:" \
    "" \
    "  ${CYAN}atuin search --interactive${RESET}" \
    "" \
    "Find the entry → Ctrl-O → ${BOLD}Ctrl-D${RESET} → Confirm deletion." \
    "" \
    "Alternatively, delete by ID:" \
    "  ${CYAN}atuin history list${RESET}     # Find the entry" \
    "  ${CYAN}atuin history delete <ID>${RESET}"

drill 19 "Copy Command to Clipboard (Ctrl-Y)" \
    "Open TUI, navigate to a useful command." \
    "Press ${BOLD}Ctrl-Y${RESET}." \
    "" \
    "The command is now in your system clipboard." \
    "Paste it anywhere with Ctrl-V (or your terminal's paste)."

drill 20 "Word-Level Editing in Search" \
    "Open TUI and type a multi-word query." \
    "" \
    "  ${CYAN}Ctrl-W${RESET}              Delete word backwards" \
    "  ${CYAN}Ctrl-Backspace${RESET}      Delete previous word" \
    "  ${CYAN}Ctrl-Delete${RESET}         Delete next word" \
    "  ${CYAN}Ctrl-← / Alt-B${RESET}      Jump to previous word" \
    "  ${CYAN}Ctrl-→ / Alt-F${RESET}      Jump to next word" \
    "  ${CYAN}Ctrl-U${RESET}              Clear the entire search line"

# =============================================================================
section "PHASE 5 — CLI COMMANDS (Drills 21-25)"
# =============================================================================

drill 21 "History List & Formatting" \
    "List your recent history:" \
    "" \
    "  ${CYAN}atuin history list${RESET}" \
    "  ${CYAN}atuin history list --limit 20${RESET}" \
    "  ${CYAN}atuin history list --format '{time} | {duration} | {command}'${RESET}" \
    "  ${CYAN}atuin history list --cwd .${RESET}         # Only current directory" \
    "  ${CYAN}atuin history list --session${RESET}       # Only current session" \
    "" \
    "Available format fields: {time}, {command}, {duration}, {exit}, {host}," \
    "  {user}, {directory}"

drill 22 "Statistics Deep Dive" \
    "View your command stats:" \
    "" \
    "  ${CYAN}atuin stats${RESET}                     # Top 10 commands" \
    "  ${CYAN}atuin stats --count 25${RESET}          # Top 25" \
    "" \
    "Notice how 'git commit' shows separately from 'git push'" \
    "because git is in common_subcommands." \
    "" \
    "And 'sudo' is stripped because it's in common_prefix." \
    "And 'cd', 'ls', 'z' are ignored because they're in ignored_commands."

drill 23 "Search from the CLI (Non-Interactive)" \
    "Search without opening the TUI:" \
    "" \
    "  ${CYAN}atuin search 'git push'${RESET}" \
    "  ${CYAN}atuin search --filter-mode directory 'cargo'${RESET}" \
    "  ${CYAN}atuin search --search-mode prefix 'sudo'${RESET}" \
    "  ${CYAN}atuin search --after '2025-01-01' --before '2025-12-31' 'docker'${RESET}" \
    "  ${CYAN}atuin search --exit 0 'make'${RESET}   # Only successful commands" \
    "" \
    "You can pipe results: ${CYAN}atuin search 'curl' | grep 'api.github'${RESET}"

drill 24 "Import Existing History" \
    "If you haven't already imported your zsh history:" \
    "" \
    "  ${CYAN}atuin import auto${RESET}              # Auto-detect and import" \
    "  ${CYAN}atuin import zsh${RESET}               # Explicitly from zsh" \
    "  ${CYAN}atuin import zsh-hist-db${RESET}       # From zsh history db" \
    "" \
    "This is a ONE-TIME operation. Future commands are auto-captured."

drill 25 "Prune History with Filters" \
    "After changing history_filter or cwd_filter, clean old entries:" \
    "" \
    "  ${CYAN}atuin history prune${RESET}" \
    "" \
    "This removes entries that NOW match your filters but were" \
    "recorded before you added the filter rules." \
    "" \
    "${RED}⚠ This is destructive! Entries are permanently deleted.${RESET}"

# =============================================================================
section "PHASE 6 — SYNC & DOTFILES (Drills 26-28)"
# =============================================================================

drill 26 "Set Up Sync" \
    "Register and enable cross-machine sync:" \
    "" \
    "  ${CYAN}atuin register -u <USERNAME> -e <EMAIL>${RESET}" \
    "  ${CYAN}atuin login -u <USERNAME>${RESET}" \
    "  ${CYAN}atuin sync${RESET}                    # Manual sync" \
    "  ${CYAN}atuin status${RESET}                  # Check sync status" \
    "" \
    "With auto_sync = true and sync_frequency = '5m'," \
    "syncing happens automatically. Manual sync is for impatient moments."

drill 27 "Dotfiles Sync (Cross-Machine Aliases)" \
    "With [dotfiles] enabled = true, manage aliases:" \
    "" \
    "  ${CYAN}atuin dotfiles alias set k 'kubectl'${RESET}" \
    "  ${CYAN}atuin dotfiles alias set dc 'docker compose'${RESET}" \
    "  ${CYAN}atuin dotfiles alias set lg 'lazygit'${RESET}" \
    "  ${CYAN}atuin dotfiles alias list${RESET}" \
    "  ${CYAN}atuin dotfiles alias delete dc${RESET}" \
    "" \
    "After setting an alias, restart your shell or re-source atuin init." \
    "These aliases sync across all your machines automatically!"

drill 28 "Daemon Mode (Advanced)" \
    "The daemon syncs in the background without blocking commands:" \
    "" \
    "  ${CYAN}# In config.toml, set [daemon] enabled = true${RESET}" \
    "  ${CYAN}atuin daemon${RESET}                  # Start the daemon" \
    "" \
    "Or create a systemd user service:" \
    "  ${CYAN}~/.config/systemd/user/atuin-daemon.service${RESET}" \
    "" \
    "The daemon is optional — auto_sync works fine for most users."

# =============================================================================
section "PHASE 7 — POWER USER (Drills 29-30)"
# =============================================================================

drill 29 "Shell Completions" \
    "Generate and install shell completions:" \
    "" \
    "  ${CYAN}atuin gen-completions --shell zsh > ~/.local/share/zsh/completions/_atuin${RESET}" \
    "" \
    "Now 'atuin <Tab>' shows all subcommands and options." \
    "Restart your shell to activate."

drill 30 "Build Your Muscle Memory Map" \
    "Here's your personal cheat sheet. Practice each daily:" \
    "" \
    "  ${BOLD}DAILY WORKFLOW:${RESET}" \
    "  ${CYAN}Ctrl-R${RESET}     → Global fuzzy search" \
    "  ${CYAN}↑ Arrow${RESET}    → Directory-scoped search (THE power move)" \
    "  ${CYAN}Enter${RESET}      → Execute immediately" \
    "  ${CYAN}Tab${RESET}        → Edit before executing" \
    "  ${CYAN}Alt-N${RESET}      → Quick-select by number" \
    "" \
    "  ${BOLD}NAVIGATION:${RESET}" \
    "  ${CYAN}Ctrl-R${RESET}     → Cycle filter: global → host → session → workspace → dir" \
    "  ${CYAN}Ctrl-S${RESET}     → Cycle search: fuzzy → prefix → fulltext → skim" \
    "  ${CYAN}Ctrl-O${RESET}     → Open Inspector" \
    "  ${CYAN}Ctrl-Y${RESET}     → Copy to clipboard" \
    "  ${CYAN}Ctrl-D${RESET}     → Delete entry (in Inspector)" \
    "" \
    "  ${BOLD}CLI:${RESET}" \
    "  ${CYAN}atuin stats${RESET}              → See your top commands" \
    "  ${CYAN}atuin search 'query'${RESET}     → Search non-interactively" \
    "  ${CYAN}atuin history list${RESET}       → Browse raw history" \
    "  ${CYAN}atuin sync${RESET}               → Force sync now" \
    "  ${CYAN}atuin doctor${RESET}             → Diagnose problems"

# =============================================================================
section "🏁 PRACTICE COMPLETE"
# =============================================================================

echo ""
echo -e "  ${GREEN}${BOLD}Congratulations!${RESET} You've completed all 30 Atuin drills."
echo ""
echo -e "  ${BOLD}Recommended daily practice:${RESET}"
echo -e "  • Week 1: Drills 1-10 (Navigation + Search Modes)"
echo -e "  • Week 2: Drills 11-16 (Filter Modes — this is where the magic is)"
echo -e "  • Week 3: Drills 17-25 (Inspector + CLI commands)"
echo -e "  • Week 4: Drills 26-30 (Sync + Power User)"
echo ""
echo -e "  ${DIM}Run this script again anytime: ./atuin/practice/atuin-drills.sh${RESET}"
echo ""
