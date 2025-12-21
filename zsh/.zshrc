# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.config/zsh/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
zmodload zsh/zprof
#
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

autoload -Uz compinit
# Check if cache exists and is less than 24 hours old
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit -C
else
  compinit -i
  zcompile ~/.zcompdump
fi

# --- 1. PLUGIN MANAGER (Sheldon) ---
# Initialize plugins immediately (p10k needs to be first)
eval "$(SHELDON_CONFIG_DIR=$ZDOTDIR sheldon source)"

# --- 2. THEME CONFIG ---
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
# Legacy p10k config removed. Using .config/zsh/.p10k.zsh at the end.

# --- 3. BASIC OPTIONS ---
HISTFILE="$XDG_CACHE_HOME/zsh_history"
HISTSIZE=1000000
SAVEHIST=1000000
setopt inc_append_history share_history
setopt hist_ignore_all_dups hist_find_no_dups auto_cd nobEEP

# --- 3.5. FZF INTEGRATION ---
source <(fzf --zsh)
export FZF_DEFAULT_OPTS="--height 70% --layout=reverse --border --inline-info"
bindkey '^R' fzf-history-widget
bindkey '^T' fzf-tab

# --- ELITE COMPINIT (Fixed Path) ---
autoload -Uz compinit
# Define exactly where the dump file lives (Keep Home clean)
_comp_dumpfile="${XDG_CACHE_HOME:-$HOME/.cache}/zcompdump"

# Check if cache exists and is fresh (less than 24h old)
if [[ -n $_comp_dumpfile(#qN.mh+24) ]]; then
  compinit -C -d "$_comp_dumpfile"  # FAST (Skip checks)
else
  compinit -i -d "$_comp_dumpfile"  # SLOW (Regenerate)
  cat "$_comp_dumpfile" | gzip > "${_comp_dumpfile}.zwc" || zcompile "$_comp_dumpfile"        # Compile for speed
fi
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -1 --color=always $realpath'

# --- 5. VI MODE (ELITE) ---
bindkey -v
export KEYTIMEOUT=1

# 2. The "Elite" Visual Feedback (Cursor Shape)
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] || [[ $1 = 'block' ]]; then
    echo -ne '\e[2 q' # Block
  elif [[ ${KEYMAP} == main ]] || [[ ${KEYMAP} == viins ]] || [[ ${KEYMAP} = '' ]] || [[ $1 = 'beam' ]]; then
    echo -ne '\e[6 q' # Beam
  fi
}
zle -N zle-keymap-select

# Ensure beam cursor when starting a new line
zle-line-init() {
    zle -K viins 
    echo -ne "\e[6 q"
}
zle -N zle-line-init

# 3. Quality of Life Fixes (The "Plugin" Features)
# Use 'jk' to exit Insert Mode (Speed hack)
bindkey -M viins 'jk' vi-cmd-mode

# Fix Backspace behavior in Vim mode
bindkey -v '^?' backward-delete-char

# Fix Control-R (History Search) and Control-L (Clear Screen)
bindkey -M viins '^r' fzf-history-widget
bindkey -M vicmd '^r' fzf-history-widget
bindkey -M viins '^l' clear-screen
bindkey -M vicmd '^l' clear-screen

# Edit the current long command in Neovim (Press 'vv')
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'vv' edit-command-line

# --- 6. IMPORTS & TOOLS ---
# FNM (Fast Node Manager)
eval "$(fnm env --use-on-cd)"

# Load all custom .zsh config files (aliases.zsh, functions.zsh, etc.)
# (N) ensures it doesn't error if no files found.
# Standard globbing skips dotfiles (like .p10k.zsh), which is what we want.
for config_file in "${ZDOTDIR:-$HOME/.config/zsh}"/*.zsh(N); do
  source "$config_file"
done

# --- 7. ZOXIDE (Must be at end) ---
eval "$(zoxide init zsh)"

# To customize prompt, run `p10k configure` or edit ~/.config/zsh/.p10k.zsh.
[[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh
