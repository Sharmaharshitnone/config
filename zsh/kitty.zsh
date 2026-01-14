# --- KITTY TERMINAL OPTIMIZATIONS ---

# SSH Kitten: Automatic terminfo transfer to remote servers
# Prevents "xterm-kitty: unknown terminal type" errors
if [[ "$TERM" == "xterm-kitty" ]]; then
    alias ssh="kitty +kitten ssh"
fi

# --- ZOXIDE + FZF INTEGRATION ---
# Prerequisite: Zoxide already configured via `eval "$(zoxide init zsh)"`

# Enhanced `cd` with fzf preview (Use `z` for quick jumps, `zi` for interactive)
function zi() {
    local dir
    dir=$(zoxide query --list | fzf \
        --height=40% \
        --layout=reverse \
        --border \
        --preview 'eza --tree --level=2 --icons --color=always {}' \
        --preview-window=right:50% \
        --bind 'ctrl-/:toggle-preview')
    [[ -n "$dir" ]] && cd "$dir"
}

# Kitty-optimized directory switching (ALT+C override)
# Binds ALT+C to fuzzy-find directories in current tree
export FZF_ALT_C_OPTS="
    --walker-skip .git,node_modules,target,build
    --preview 'eza --tree --level=2 --icons --color=always {}'
    --border
    --height=70%
"

# History search with Kitty's native rendering (CTRL+R override)
export FZF_CTRL_R_OPTS="
    --preview 'echo {}' 
    --preview-window=down:3:wrap
    --bind 'ctrl-y:execute-silent(echo -n {2..} | kitty +kitten clipboard)'
    --color=header:italic
    --header 'CTRL-Y: Copy to clipboard'
"

# File search with bat preview (CTRL+T override)
export FZF_CTRL_T_OPTS="
    --walker-skip .git,node_modules,target,build
    --preview 'bat --color=always --style=numbers --line-range=:500 {}'
    --bind 'ctrl-/:toggle-preview'
    --border
"

# --- KITTY-SPECIFIC KEYBINDS (Optional) ---
# Use Kitty's remote control API for advanced window management
# Requires `allow_remote_control yes` in kitty.conf

# Open new Kitty window in same directory
function kn() {
    kitty @ launch --cwd="$PWD" --type=os-window
}

# Clone current Kitty tab
function kt() {
    kitty @ launch --cwd="$PWD" --type=tab
}
