# ZSH SYNTAX HIGHLIGHTING CONFIGURATION (Catppuccin Mocha)
# Documentation: https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters/main.md
# Must be sourced AFTER zsh-syntax-highlighting plugin loads

# CRITICAL: Declare ZSH_HIGHLIGHT_STYLES as associative array FIRST
typeset -A ZSH_HIGHLIGHT_STYLES

# ===== CATPPUCCIN MOCHA PALETTE =====
# Red:     #f38ba8  |  Peach:   #fab387
# Blue:    #89b4fa  |  Teal:    #94e2d5
# Green:   #a6e3a1  |  Mauve:   #cba6f7
# Yellow:  #f9e2af  |  Maroon:  #eba0ac
# Overlay: #6c7086  |  Surface: #45475a

# ===== COMMAND TYPES =====
ZSH_HIGHLIGHT_STYLES[precommand]='fg=#f38ba8,bold'           # sudo, noglob, builtin
ZSH_HIGHLIGHT_STYLES[command]='fg=#89b4fa'                   # ls, grep, nvim
ZSH_HIGHLIGHT_STYLES[alias]='fg=#94e2d5'                     # User-defined aliases
ZSH_HIGHLIGHT_STYLES[suffix-alias]='fg=#94e2d5,underline'    # Suffix aliases (zsh 5.1.1+)
ZSH_HIGHLIGHT_STYLES[global-alias]='fg=#cba6f7'              # Global aliases
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#89b4fa,bold'              # shift, pwd, cd
ZSH_HIGHLIGHT_STYLES[function]='fg=#a6e3a1'                  # User functions
ZSH_HIGHLIGHT_STYLES[hashed-command]='fg=#89b4fa,italic'     # Cached commands

# ===== ERROR STATES =====
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#f38ba8,underline'   # Typos/invalid commands
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#fab387,bold'        # if, for, while

# ===== PATHS & FILES =====
ZSH_HIGHLIGHT_STYLES[path]='fg=#f9e2af'                      # Valid paths
ZSH_HIGHLIGHT_STYLES[path_prefix]='fg=#f9e2af,underline'     # Partial valid paths
ZSH_HIGHLIGHT_STYLES[autodirectory]='fg=#f9e2af,italic'      # AUTO_CD dirs

# ===== ARGUMENTS & QUOTING =====
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#a6e3a1'    # 'string'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#a6e3a1'    # "string"
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=#a6e3a1'    # $'string'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='fg=#fab387'      # `cmd`

# ===== SPECIAL ELEMENTS =====
ZSH_HIGHLIGHT_STYLES[comment]='fg=#6c7086,italic'            # # comments
ZSH_HIGHLIGHT_STYLES[redirection]='fg=#fab387,bold'          # >, <, |
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=#eba0ac,bold'     # ;, &&, ||
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#cba6f7'      # -o
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#cba6f7'      # --option

# ===== GLOBBING & EXPANSION =====
ZSH_HIGHLIGHT_STYLES[globbing]='fg=#fab387,bold'             # *.txt, **/*.md
ZSH_HIGHLIGHT_STYLES[history-expansion]='fg=#eba0ac'         # !!, !$
ZSH_HIGHLIGHT_STYLES[assign]='fg=#f9e2af,bold'               # VAR=value

# ===== SUBSTITUTIONS =====
ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter]='fg=#45475a,bold'          # $( )
ZSH_HIGHLIGHT_STYLES[process-substitution-delimiter]='fg=#45475a,bold'          # <( )
ZSH_HIGHLIGHT_STYLES[arithmetic-expansion]='fg=#cba6f7'                          # $(( ))
ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]='fg=#fab387'                 # "$var"

# ===== FILE DESCRIPTORS =====
ZSH_HIGHLIGHT_STYLES[named-fd]='fg=#89b4fa,bold'             # {fd}
ZSH_HIGHLIGHT_STYLES[numeric-fd]='fg=#89b4fa'                # 2>&1

# ===== FALLBACK =====
ZSH_HIGHLIGHT_STYLES[default]='fg=#cdd6f4'                   # Catppuccin Text (everything else)
ZSH_HIGHLIGHT_STYLES[arg0]='fg=#f38ba8,italic'               # Fallback for unknown command types
