export ZDOTDIR="$HOME/.config/zsh"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export TERMINAL="kitty"
export EDITOR="nvim"
export VISUAL="nvim"
export BROWSER="firefox"
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export SHELDON_CONFIG_DIR="$HOME/.config/zsh"
export HISTFILE=/dev/null
# Prevent PATH duplication on subshells using typeset -U (unique)
typeset -U path PATH
path=("$HOME/.local/bin" "$CARGO_HOME/bin" $path)
export PATH
