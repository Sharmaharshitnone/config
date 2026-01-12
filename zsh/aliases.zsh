# --- ELITE ZSH ALIASES & FUNCTIONS ---

# --- 1. MODERN REPLACEMENTS ---
alias ls='eza --icons --group-directories-first'
# alias ll='eza -la --icons --group-directories-first'
alias la="ll -a"
# alias lt='eza -T --icons --group-directories-first'
alias lt="eza --tree --level=2 --icons --group-directories-first"
alias ll="eza -l --icons --group-directories-first --git --header --total-size --smart-group"
# alias grep='rg'
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -I'
alias e='nvim'

# --- 2. NAVIGATION ---
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias mkcd='_mkcd() { mkdir -p "$1" && cd "$1"; }; _mkcd'

# --- 3. ARCH LINUX (YAY) ---
alias upd='update_clean' # Uses the robust function below
alias in='yay -S'
alias rem='yay -Rns'
alias orphan='yay -Rns $(yay -Qtdq)'
alias please='sudo $(fc -ln -1)' # Retry last command with sudo

# --- 4. RUST & DEVELOPMENT ---
alias c='cargo'
alias cr='cargo run'
alias ct='cargo test'
alias cb='cargo build'
alias ck='cargo check'
alias cw='cargo watch -x run'   # Requires cargo-watch
alias cl='cargo clippy'
alias cx='cargo run --example'

# --- 5. CP WORKFLOW ---
function cpprun() {
    g++ -O3 -std=c++23 -Wall -Wextra -DLOCAL "$1" -o "${1%.*}" && ./"${1%.*}"
}
function cpp_debug() {
    g++ -g -fsanitize=address,undefined -std=c++23 -Wall -DLOCAL "$1" -o "${1%.*}" && ./"${1%.*}"
}

# --- 6. UTILITIES ---
alias lg='lazygit'
alias ld='lazydocker'
alias myip='curl http://ipecho.net/plain; echo'

# --- 7. CUSTOM FUNCTIONS ---

# # Extract Archives
# extract() {
#     if [[ -z "$1" ]]; then echo "Usage: extract <file>"; return 1; fi
#     if [[ ! -f "$1" ]]; then echo "Error: File not found: '$1'"; return 1; fi
#     case "$1" in
#         *.tar.gz|*.tgz) tar -xzvf "$1" ;;
#         *.tar.bz2|*.tbz2) tar -xjvf "$1" ;;
#         *.tar.xz|*.txz) tar -xJvf "$1" ;;
#         *.tar) tar -xvf "$1" ;;
#         *.zip|*.jar) unzip "$1" ;;
#         *.7z) 7z x "$1" ;;
#         *.rar) 7z x "$1" ;;
#         *) echo "Unknown format: $1" ;;
#     esac
# }
#
# # Robust System Update (Merged from upclean.zsh)
# update_clean() {
#     echo ":: Starting System Update..."
#     sudo pacman -Sy --needed --noconfirm archlinux-keyring
#     yay -Syu --combinedupgrade --noprogressbar
#     echo ":: Pruning Orphans..."
#     yay -Yc --noconfirm
#     echo ":: Cleaning Cache..."
#     sudo paccache -rk2 2>&1
#     echo ":: Done!"
# }
# alias upclean='update_clean'

# pass
alias p="pass"
alias pp="pass git push"

# History Hooks (Prevent logging failed commands)
function zshaddhistory() {
    LASTHIST=${1//\\\\$\'\\n\'/}
    return 2 # Save to internal list but wait for execution status
}
function precmd() {
    if [[ $? == 0 && -n ${LASTHIST//[[:space:]\\n]/} && -n $HISTFILE ]] ; then
        print -sr -- ${=${LASTHIST%%\'\\n\'}}
    fi 
}


alias v='nvim'
alias g='git'
alias config='cd ~/work/config'
alias img="fd -e jpg -e png | nsxiv -itfa"
