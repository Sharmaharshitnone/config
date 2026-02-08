zmodload zsh/zprof
#
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# --- 1. PLUGIN MANAGER (Sheldon) ---
# Initialize plugins immediately (p10k needs to be first)
eval "$(SHELDON_CONFIG_DIR=$ZDOTDIR sheldon source)"


# --- 3. BASIC OPTIONS ---
HISTFILE="$XDG_CACHE_HOME/zsh_history"
HISTSIZE=1000000
SAVEHIST=1000000
setopt HIST_IGNORE_DUPS hist_ignore_space
setopt hist_ignore_space HIST_IGNORE_ALL_DUPS inc_append_history share_history
setopt hist_ignore_all_dups hist_find_no_dups auto_cd nobEEP
export HISTORY_IGNORE="(ls|ll|la|cd|cd ..|pwd|exit|clear|history|rm *|nvim *|touch *|chmod *|chown *|export *|unset *|reboot|shutdown|top|htop|btop|kill *|pkill *|make clean|cargo clean)"
export ZSH_AUTOSUGGEST_HISTORY_IGNORE="$HISTORY_IGNORE"
export ZSH_AUTOSUGGEST_USE_ASYNC=1
export ZSH_AUTOSUGGEST_STRATEGY=(history completion)
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#606060"
bindkey '^ ' autosuggest-accept

# --- 3.5. FZF INTEGRATION ---
source <(fzf --zsh)
export FZF_DEFAULT_OPTS="--height 70% --layout=reverse --border --inline-info"
bindkey '^R' fzf-history-widget
bindkey '^T' fzf-tab

# --- COMPINIT (Single init, XDG-compliant) ---
autoload -Uz compinit
_comp_dumpfile="${XDG_CACHE_HOME:-$HOME/.cache}/zcompdump-${ZSH_VERSION}"

if [[ -n $_comp_dumpfile(#qN.mh+24) ]]; then
  compinit -C -d "$_comp_dumpfile"
else
  compinit -i -d "$_comp_dumpfile"
  { zcompile "$_comp_dumpfile" } &!  # Background compile, .zwc is zsh word code NOT gzip
fi
unset _comp_dumpfile
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

load-tokens(){
	local -A mappings=(
		"tokens/github" "GITHUB_PERSONAL_ACCESS_TOKEN"
		"tokens/context7" "CONTEXT7_API_KEY"
	)

	local secret_path var secret
	
	for secret_path var in ${(kv)mappings}; do
		
		secret=$(pass "$secret_path" 2>/dev/null | read -r line && echo "$line")

		if [[ -n "$secret" ]]; then
		    export "$var"="$secret"
		    printf "Loaded %s\n" "$var" "$secret_path"
		else
		    printf "Warning: No secret found at %s\n" "$secret_path" "$var"
		fi
	done
}

# To customize prompt, run `p10k configure` or edit ~/.config/zsh/.p10k.zsh.
[[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh
source "$ZDOTDIR/syntax-highlight.zsh"
