# Config for Powerlevel10k — Pure Dark Monochrome theme.
# Transparent bg, gray-scale text, no candy colors.
#

# Temporarily change options.
'builtin' 'local' '-a' 'p10k_config_opts'
[[ ! -o 'aliases'         ]] || p10k_config_opts+=('aliases')
[[ ! -o 'sh_glob'         ]] || p10k_config_opts+=('sh_glob')
[[ ! -o 'no_brace_expand' ]] || p10k_config_opts+=('no_brace_expand')
'builtin' 'setopt' 'no_aliases' 'no_sh_glob' 'brace_expand'

() {
  emulate -L zsh -o extended_glob

  # Unset all configuration options. This allows you to apply configuration changes without
  # restarting zsh. Edit ~/.p10k.zsh and type `source ~/.p10k.zsh`.
  unset -m '(POWERLEVEL9K_*|DEFAULT_USER)~POWERLEVEL9K_GITSTATUS_DIR'

  # Zsh >= 5.1 is required.
  [[ $ZSH_VERSION == (5.<1->*|<6->.*) ]] || return

  # ─── Pure Dark Monochrome Palette ───────────────────────────────────
  # No candy colors. Grays + muted white only. Transparent background.
  #
  # Spectrum:  bright → dim
  #   #ffffff  (pure white — rarely used, active highlights)
  #   #d4d4d4  (primary text)
  #   #aaaaaa  (secondary / subtext)
  #   #888888  (muted metadata)
  #   #666666  (dim separators)
  #   #444444  (faint / surface)
  #   #333333  (very faint)
  #
  # Semantic (minimal color, only for git status):
  #   #88cc88  (clean/ok — desaturated green)
  #   #cccc66  (modified/warn — desaturated yellow)
  #   #cc6666  (error/conflict — desaturated red)
  #   #6699cc  (info/untracked — desaturated blue)

  # Core backgrounds (unused — transparent)
  typeset -g P10K_COLOR_BASE=""           # transparent
  typeset -g P10K_COLOR_MANTLE=""         # transparent
  typeset -g P10K_COLOR_CRUST=""          # transparent

  # Text tiers
  typeset -g P10K_COLOR_TEXT="#d4d4d4"     # Primary text
  typeset -g P10K_COLOR_SUBTEXT1="#aaaaaa" # Secondary text
  typeset -g P10K_COLOR_SUBTEXT0="#888888" # Muted text

  # Overlay / surface tiers
  typeset -g P10K_COLOR_OVERLAY2="#888888"
  typeset -g P10K_COLOR_OVERLAY1="#666666"
  typeset -g P10K_COLOR_OVERLAY0="#555555"

  typeset -g P10K_COLOR_SURFACE2="#555555"
  typeset -g P10K_COLOR_SURFACE1="#444444"
  typeset -g P10K_COLOR_SURFACE0="#333333"

  # Semantic colors (desaturated, dark-theme friendly)
  typeset -g P10K_COLOR_BLUE="#6699cc"
  typeset -g P10K_COLOR_LAVENDER="#d4d4d4"  # dirs — just bright white
  typeset -g P10K_COLOR_SAPPHIRE="#6699cc"
  typeset -g P10K_COLOR_SKY="#aaaaaa"
  typeset -g P10K_COLOR_TEAL="#88aa88"
  typeset -g P10K_COLOR_GREEN="#88cc88"
  typeset -g P10K_COLOR_YELLOW="#cccc66"
  typeset -g P10K_COLOR_PEACH="#ccaa66"
  typeset -g P10K_COLOR_RED="#cc6666"
  typeset -g P10K_COLOR_MAROON="#cc6666"
  typeset -g P10K_COLOR_PINK="#aaaaaa"
  typeset -g P10K_COLOR_FLAMINGO="#aaaaaa"
  typeset -g P10K_COLOR_ROSEWATER="#bbbbbb"
  typeset -g P10K_COLOR_MAUVE="#d4d4d4"     # git branch — bright white

  # The list of segments shown on the left. Fill it with the most important segments.
  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
    # =========================[ Line #1 ]=========================
    # os_icon                 # os identifier
    dir                     # current directory
    vcs                     # git status
    prompt_char             # prompt symbol
  )

  # The list of segments shown on the right. Fill it with less important segments.
  # Right prompt on the last prompt line (where you are typing your commands) gets
  # automatically hidden when the input line reaches it. Right prompt above the
  # last prompt line gets hidden if it would overlap with left prompt.
  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
    # =========================[ Line #1 ]=========================
    status                  # exit code of the last command
    command_execution_time  # duration of the last command
    background_jobs         # presence of background jobs
    direnv                  # direnv status (https://direnv.net/)
    asdf                    # asdf version manager (https://github.com/asdf-vm/asdf)
    virtualenv              # python virtual environment (https://docs.python.org/3/library/venv.html)
    anaconda                # conda environment (https://conda.io/)
    pyenv                   # python environment (https://github.com/pyenv/pyenv)
    goenv                   # go environment (https://github.com/syndbg/goenv)
    nodenv                  # node.js version from nodenv (https://github.com/nodenv/nodenv)
    nvm                     # node.js version from nvm (https://github.com/nvm-sh/nvm)
    nodeenv                 # node.js environment (https://github.com/ekalinin/nodeenv)
    # node_version          # node.js version
    # go_version            # go version (https://golang.org)
    # rust_version          # rustc version (https://www.rust-lang.org)
    # dotnet_version        # .NET version (https://dotnet.microsoft.com)
    # php_version           # php version (https://www.php.net/)
    # laravel_version       # laravel php framework version (https://laravel.com/)
    # java_version          # java version (https://www.java.com/)
    # package               # name@version from package.json (https://docs.npmjs.com/files/package.json)
    rbenv                   # ruby version from rbenv (https://github.com/rbenv/rbenv)
    rvm                     # ruby version from rvm (https://rvm.io)
    fvm                     # flutter version management (https://github.com/leoafarias/fvm)
    luaenv                  # lua version from luaenv (https://github.com/cehoffman/luaenv)
    jenv                    # java version from jenv (https://github.com/jenv/jenv)
    plenv                   # perl version from plenv (https://github.com/tokuhirom/plenv)
    perlbrew                # perl version from perlbrew (https://github.com/gugod/App-perlbrew)
    phpenv                  # php version from phpenv (https://github.com/phpenv/phpenv)
    scalaenv                # scala version from scalaenv (https://github.com/scalaenv/scalaenv)
    haskell_stack           # haskell version from stack (https://haskellstack.org/)
    kubecontext             # current kubernetes context (https://kubernetes.io/)
    terraform               # terraform workspace (https://www.terraform.io)
    # terraform_version     # terraform version (https://www.terraform.io)
    aws                     # aws profile (https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html)
    aws_eb_env              # aws elastic beanstalk environment (https://aws.amazon.com/elasticbeanstalk/)
    azure                   # azure account name (https://docs.microsoft.com/en-us/cli/azure)
    gcloud                  # google cloud cli account and project (https://cloud.google.com/)
    google_app_cred         # google application credentials (https://cloud.google.com/docs/authentication/production)
    toolbox                 # toolbox name (https://github.com/containers/toolbox)
    context                 # user@hostname
    nordvpn                 # nordvpn connection status, linux only (https://nordvpn.com/)
    ranger                  # ranger shell (https://github.com/ranger/ranger)
    yazi                    # yazi shell (https://github.com/sxyazi/yazi)
    nnn                     # nnn shell (https://github.com/jarun/nnn)
    lf                      # lf shell (https://github.com/gokcehan/lf)
    xplr                    # xplr shell (https://github.com/sayanarijit/xplr)
    vim_shell               # vim shell indicator (:sh)
    midnight_commander      # midnight commander shell (https://midnight-commander.org/)
    nix_shell               # nix shell (https://nixos.org/nixos/nix-pills/developing-with-nix-shell.html)
    chezmoi_shell           # chezmoi shell (https://www.chezmoi.io/)
    # vi_mode               # vi mode (you don't need this if you've enabled prompt_char)
    # vpn_ip                # virtual private network indicator
    # load                  # CPU load
    # disk_usage            # disk usage
    # ram                   # free RAM
    # swap                  # used swap
    todo                    # todo items (https://github.com/todotxt/todo.txt-cli)
    timewarrior             # timewarrior tracking status (https://timewarrior.net/)
    taskwarrior             # taskwarrior task count (https://taskwarrior.org/)
    per_directory_history   # Oh My Zsh per-directory-history local/global indicator
    # cpu_arch              # CPU architecture
    # time                  # current time
    # =========================[ Line #2 ]=========================
    newline
    # ip                    # ip address and bandwidth usage for a specified network interface
    # public_ip             # public IP address
    # proxy                 # system-wide http/https/ftp proxy
    # battery               # internal battery
    # wifi                  # wifi speed
    # example               # example user-defined segment (see prompt_example function below)
  )

  # Defines character set used by powerlevel10k. It's best to let `p10k configure` set it for you.
  typeset -g POWERLEVEL9K_MODE=nerdfont-v3
  # When set to `moderate`, some icons will have an extra space after them. This is meant to avoid
  # icon overlap when using non-monospace fonts. When set to `none`, spaces are not added.
  typeset -g POWERLEVEL9K_ICON_PADDING=none

  # Basic style options that define the overall look of your prompt. You probably don't want to
  # change them.
  typeset -g POWERLEVEL9K_BACKGROUND=                            # transparent background
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_{LEFT,RIGHT}_WHITESPACE=  # no surrounding whitespace
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SUBSEGMENT_SEPARATOR=' '  # separate segments with a space
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SEGMENT_SEPARATOR=        # no end-of-line symbol

  # When set to true, icons appear before content on both sides of the prompt. When set
  # to false, icons go after content. If empty or not set, icons go before content in the left
  # prompt and after content in the right prompt.
  #
  # You can also override it for a specific segment:
  #
  #   POWERLEVEL9K_STATUS_ICON_BEFORE_CONTENT=false
  #
  # Or for a specific segment in specific state:
  #
  #   POWERLEVEL9K_DIR_NOT_WRITABLE_ICON_BEFORE_CONTENT=false
  typeset -g POWERLEVEL9K_ICON_BEFORE_CONTENT=true

  # Add an empty line before each prompt.
  typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=false

  

  # The left end of left prompt.
  typeset -g POWERLEVEL9K_LEFT_PROMPT_FIRST_SEGMENT_START_SYMBOL=' '
  # The right end of right prompt.
  typeset -g POWERLEVEL9K_RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL=' '

  # Ruler, a.k.a. the horizontal line before each prompt. If you set it to true, you'll
  # probably want to set POWERLEVEL9K_PROMPT_ADD_NEWLINE=false above and
  # POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_CHAR=' ' below.
  typeset -g POWERLEVEL9K_SHOW_RULER=true
  typeset -g POWERLEVEL9K_RULER_CHAR='─'
  typeset -g POWERLEVEL9K_RULER_FOREGROUND=$P10K_COLOR_SURFACE1

  # Filler between left and right prompt on the first prompt line. You can set it to '·' or '─'
  # to make it easier to see the alignment between left and right prompt and to separate prompt
  # from command output. It serves the same purpose as ruler (see above) without increasing
  # the number of prompt lines. You'll probably want to set POWERLEVEL9K_SHOW_RULER=false
  # if using this. You might also like POWERLEVEL9K_PROMPT_ADD_NEWLINE=false for more compact
  # prompt.
  # typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_CHAR=' '
  
  if [[ $POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_CHAR != ' ' ]]; then
    # The color of the filler.
    typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_FOREGROUND=$P10K_COLOR_SURFACE1
    # Add a space between the end of left prompt and the filler.
    typeset -g POWERLEVEL9K_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL=' '
    # Add a space between the filler and the start of right prompt.
    typeset -g POWERLEVEL9K_RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL=' '
    # Start filler from the edge of the screen if there are no left segments on the first line.
    typeset -g POWERLEVEL9K_EMPTY_LINE_LEFT_PROMPT_FIRST_SEGMENT_END_SYMBOL='%{%}'
    # End filler on the edge of the screen if there are no right segments on the first line.
    typeset -g POWERLEVEL9K_EMPTY_LINE_RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL='%{%}'
  fi

  

  #################################[ os_icon: os identifier ]##################################
  # OS identifier color.
  typeset -g POWERLEVEL9K_OS_ICON_FOREGROUND=$P10K_COLOR_TEXT
  # Custom icon.
  # typeset -g POWERLEVEL9K_OS_ICON_CONTENT_EXPANSION='⭐'

  ################################[ prompt_char: prompt symbol ]################################
  
  # Green prompt symbol if the last command succeeded.
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=$P10K_COLOR_MAUVE
  # Red prompt symbol if the last command failed.
  typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=$P10K_COLOR_MAROON
  # Default prompt symbol.
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIINS_CONTENT_EXPANSION='❯'
  # Prompt symbol in command vi mode.
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VICMD_CONTENT_EXPANSION='❮'
  # Prompt symbol in visual vi mode.
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIVIS_CONTENT_EXPANSION='V'
  # Prompt symbol in overwrite vi mode.
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIOWR_CONTENT_EXPANSION='▶'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OVERWRITE_STATE=true
  # No line terminator if prompt_char is the last segment.
  typeset -g POWERLEVEL9K_PROMPT_CHAR_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL=''
  # No line introducer if prompt_char is the first segment.
  typeset -g POWERLEVEL9K_PROMPT_CHAR_LEFT_PROMPT_FIRST_SEGMENT_START_SYMBOL=
  

  ##################################[ dir: current directory ]##################################
  # Default current directory color.
  typeset -g POWERLEVEL9K_DIR_FOREGROUND=$P10K_COLOR_LAVENDER
  # Custom Home Icon
  typeset -g POWERLEVEL9K_DIR_HOME_VISUAL_IDENTIFIER_EXPANSION=''
  
  # If directory is too long, shorten some of its segments to the shortest possible unique
  # prefix. The shortened directory can be tab-completed to the original.
  typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_last
  # Replace removed segment suffixes with this symbol.
  typeset -g POWERLEVEL9K_SHORTEN_DELIMITER="..."
  # Color of the shortened directory segments.
  typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=$P10K_COLOR_SUBTEXT1
  # Color of the anchor directory segments. Anchor segments are never shortened. The first
  # segment is always an anchor.
  typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=$P10K_COLOR_LAVENDER
  # Display anchor directory segments in bold.
  typeset -g POWERLEVEL9K_DIR_ANCHOR_BOLD=true
  # Don't shorten directories that contain any of these files. They are anchors.
  local anchor_files=(
    .bzr
    .citc
    .git
    .hg
    .node-version
    .python-version
    .go-version
    .ruby-version
    .lua-version
    .java-version
    .perl-version
    .php-version
    .tool-versions
    .mise.toml
    .shorten_folder_marker
    .svn
    .terraform
    CVS
    Cargo.toml
    composer.json
    go.mod
    package.json
    stack.yaml
  )
  typeset -g POWERLEVEL9K_SHORTEN_FOLDER_MARKER="(${(j:|:)anchor_files})"
  # If set to "first" ("last"), remove everything before the first (last) subdirectory that contains
  # files matching $POWERLEVEL9K_SHORTEN_FOLDER_MARKER. For example, when the current directory is
  # /foo/bar/git_repo/nested_git_repo/baz, prompt will display git_repo/nested_git_repo/baz (first)
  # or nested_git_repo/baz (last). This assumes that git_repo and nested_git_repo contain markers
  # and other directories don't.
  #
  # Optionally, "first" and "last" can be followed by ":<offset>" where <offset> is an integer.
  # This moves the truncation point to the right (positive offset) or to the left (negative offset)
  # relative to the marker. Plain "first" and "last" are equivalent to "first:0" and "last:0"
  # respectively.
  typeset -g POWERLEVEL9K_DIR_TRUNCATE_BEFORE_MARKER=false
  # Don't shorten this many last directory segments. They are anchors.
  typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=2
  # Shorten directory if it's longer than this even if there is space for it. The value can
  # be either absolute (e.g., '80') or a percentage of terminal width (e.g, '50%'). If empty,
  # directory will be shortened only when prompt doesn't fit or when other parameters demand it
  # (see POWERLEVEL9K_DIR_MIN_COMMAND_COLUMNS and POWERLEVEL9K_DIR_MIN_COMMAND_COLUMNS_PCT below).
  # If set to `0`, directory will always be shortened to its minimum length.
  typeset -g POWERLEVEL9K_DIR_MAX_LENGTH=80
  # When \`dir\` segment is on the last prompt line, try to shorten it enough to leave at least this
  # many columns for typing commands.
  typeset -g POWERLEVEL9K_DIR_MIN_COMMAND_COLUMNS=40
  # When \`dir\` segment is on the last prompt line, try to shorten it enough to leave at least
  # COLUMNS * POWERLEVEL9K_DIR_MIN_COMMAND_COLUMNS_PCT * 0.01 columns for typing commands.
  typeset -g POWERLEVEL9K_DIR_MIN_COMMAND_COLUMNS_PCT=50
  # If set to true, embed a hyperlink into the directory. Useful for quickly
  # opening a directory in the file manager simply by clicking the link.
  # Can also be handy when the directory is shortened, as it allows you to see
  # the full directory that was used in previous commands.
  typeset -g POWERLEVEL9K_DIR_HYPERLINK=false

  # Enable special styling for non-writable and non-existent directories. See POWERLEVEL9K_LOCK_ICON
  # and POWERLEVEL9K_DIR_CLASSES below.
  typeset -g POWERLEVEL9K_DIR_SHOW_WRITABLE=v3

  # The default icon shown next to non-writable and non-existent directories when
  # POWERLEVEL9K_DIR_SHOW_WRITABLE is set to v3.
  # typeset -g POWERLEVEL9K_LOCK_ICON='⭐'

  # POWERLEVEL9K_DIR_CLASSES allows you to specify custom icons and colors for different
  # directories. It must be an array with 3 * N elements. Each triplet consists of:
  #
  #   1. A pattern against which the current directory ($PWD) is matched. Matching is done with
  #      extended_glob option enabled.
  #   2. Directory class for the purpose of styling.
  #   3. An empty string.
  #
  # Triplets are tried in order. The first triplet whose pattern matches $PWD wins.
  #
  # If POWERLEVEL9K_DIR_SHOW_WRITABLE is set to v3, non-writable and non-existent directories
  # acquire class suffix _NOT_WRITABLE and NON_EXISTENT respectively.
  #
  # For example, given these settings:
  #
  #   typeset -g POWERLEVEL9K_DIR_CLASSES=(
  #     '~/work(|/*)'  WORK     ''
  #     '~(|/*)'       HOME     ''
  #     '*'            DEFAULT  '')
  #
  # Whenever the current directory is ~/work or a subdirectory of ~/work, it gets styled with one
  # of the following classes depending on its writability and existence: WORK, WORK_NOT_WRITABLE or
  # WORK_NON_EXISTENT.
  #
  # Simply assigning classes to directories doesn't have any visible effects. It merely gives you an
  # option to define custom colors and icons for different directory classes.
  #
  #   # Styling for WORK.
  #   typeset -g POWERLEVEL9K_DIR_WORK_VISUAL_IDENTIFIER_EXPANSION='⭐'
  #   typeset -g POWERLEVEL9K_DIR_WORK_FOREGROUND=$P10K_COLOR_BLUE
  #   typeset -g POWERLEVEL9K_DIR_WORK_SHORTENED_FOREGROUND=$P10K_COLOR_SUBTEXT1
  #   typeset -g POWERLEVEL9K_DIR_WORK_ANCHOR_FOREGROUND=$P10K_COLOR_SKY
  #
  #   # Styling for WORK_NOT_WRITABLE.
  #   typeset -g POWERLEVEL9K_DIR_WORK_NOT_WRITABLE_VISUAL_IDENTIFIER_EXPANSION='⭐'
  #   typeset -g POWERLEVEL9K_DIR_WORK_NOT_WRITABLE_FOREGROUND=$P10K_COLOR_BLUE
  #   typeset -g POWERLEVEL9K_DIR_WORK_NOT_WRITABLE_SHORTENED_FOREGROUND=$P10K_COLOR_SUBTEXT1
  #   typeset -g POWERLEVEL9K_DIR_WORK_NOT_WRITABLE_ANCHOR_FOREGROUND=$P10K_COLOR_SKY
  #
  #   # Styling for WORK_NON_EXISTENT.
  #   typeset -g POWERLEVEL9K_DIR_WORK_NON_EXISTENT_VISUAL_IDENTIFIER_EXPANSION='⭐'
  #   typeset -g POWERLEVEL9K_DIR_WORK_NON_EXISTENT_FOREGROUND=$P10K_COLOR_BLUE
  #   typeset -g POWERLEVEL9K_DIR_WORK_NON_EXISTENT_SHORTENED_FOREGROUND=$P10K_COLOR_SUBTEXT1
  #   typeset -g POWERLEVEL9K_DIR_WORK_NON_EXISTENT_ANCHOR_FOREGROUND=$P10K_COLOR_SKY
  #
  # If a styling parameter isn't explicitly defined for some class, it falls back to the classless
  # parameter. For example, if POWERLEVEL9K_DIR_WORK_NOT_WRITABLE_FOREGROUND is not set, it falls
  # back to POWERLEVEL9K_DIR_FOREGROUND.
  #
  # typeset -g POWERLEVEL9K_DIR_CLASSES=()

  # Custom prefix.
  # typeset -g POWERLEVEL9K_DIR_PREFIX='%fin '

  #####################################[ vcs: git status ]######################################

  

  # Branch icon. Set this parameter to '\UE0A0 ' for the popular Powerline branch icon.
  typeset -g POWERLEVEL9K_VCS_BRANCH_ICON='\uF126 '

  # Untracked files icon. It's really a question mark, your font isn't broken.
  # Change the value of this parameter to show a different icon.
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_ICON='?'

  # Formatter for Git status.
  #
  # Example output: master wip ⇣42⇡42 *42 merge ~42 +42 !42 ?42.
  #
  # You can edit the function to customize how Git status looks.
  #
  # VCS_STATUS_* parameters are set by gitstatus plugin. See reference:
  # https://github.com/romkatv/gitstatus/blob/master/gitstatus.plugin.zsh.
  function my_git_formatter() {
    emulate -L zsh

    if [[ -n $P9K_CONTENT ]]; then
      # If P9K_CONTENT is not empty, use it. It's either "loading" or from vcs_info (not from
      # gitstatus plugin). VCS_STATUS_* parameters are not available in this case.
      typeset -g my_git_format=$P9K_CONTENT
      return
    fi
    
    if (( $1 )); then
      # Styling for up-to-date Git status.
      local       meta='%F{#d4d4d4}'     # bright white
      local      clean='%F{#d4d4d4}'     # bright white
      local   modified='%F{#cccc66}'     # desaturated yellow
      local  untracked='%F{#6699cc}'     # desaturated blue
      local conflicted='%F{#cc6666}'     # desaturated red
    else
      # Styling for incomplete and stale Git status.
      local       meta='%F{#666666}'     # dim gray
      local      clean='%F{#666666}'
      local   modified='%F{#666666}'
      local  untracked='%F{#666666}'
      local conflicted='%F{#666666}'
    fi

    local res

    if [[ -n $VCS_STATUS_LOCAL_BRANCH ]]; then
      local branch=${(V)VCS_STATUS_LOCAL_BRANCH}
      # If local branch name is at most 32 characters long, show it in full.
      # Otherwise show the first 12 … the last 12.
      # Tip: To always show local branch name in full without truncation, delete the next line.
      (( $#branch > 32 )) && branch[13,-13]="…"  # <-- this line
      res+="${clean}${(g::)POWERLEVEL9K_VCS_BRANCH_ICON}${branch//\%/%%}"
    fi

    if [[ -n $VCS_STATUS_TAG
          # Show tag only if not on a branch.
          # Tip: To always show tag, delete the next line.
          && -z $VCS_STATUS_LOCAL_BRANCH  # <-- this line
        ]]; then
      local tag=${(V)VCS_STATUS_TAG}
      # If tag name is at most 32 characters long, show it in full.
      # Otherwise show the first 12 … the last 12.
      # Tip: To always show tag name in full without truncation, delete the next line.
      (( $#tag > 32 )) && tag[13,-13]="…"  # <-- this line
      res+="${meta}#${clean}${tag//\%/%%}"
    fi

    # Display the current Git commit if there is no branch and no tag.
    # Tip: To always display the current Git commit, delete the next line.
    [[ -z $VCS_STATUS_LOCAL_BRANCH && -z $VCS_STATUS_TAG ]] &&  # <-- this line
      res+="${meta}@${clean}${VCS_STATUS_COMMIT[1,8]}"

    # Show tracking branch name if it differs from local branch.
    if [[ -n ${VCS_STATUS_REMOTE_BRANCH:#$VCS_STATUS_LOCAL_BRANCH} ]]; then
      res+="${meta}:${clean}${(V)VCS_STATUS_REMOTE_BRANCH//\%/%%}"
    fi

    # Display "wip" if the latest commit's summary contains "wip" or "WIP".
    if [[ $VCS_STATUS_COMMIT_SUMMARY == (|*[^[:alnum:]])(wip|WIP)(|[^[:alnum:]]*) ]]; then
      res+=" ${modified}wip"
    fi

    if (( VCS_STATUS_COMMITS_AHEAD || VCS_STATUS_COMMITS_BEHIND )); then
      # ⇣42 if behind the remote.
      (( VCS_STATUS_COMMITS_BEHIND )) && res+=" ${clean}⇣${VCS_STATUS_COMMITS_BEHIND}"
      # ⇡42 if ahead of the remote; no leading space if also behind the remote: ⇣42⇡42.
      (( VCS_STATUS_COMMITS_AHEAD && !VCS_STATUS_COMMITS_BEHIND )) && res+=" "
      (( VCS_STATUS_COMMITS_AHEAD  )) && res+="${clean}⇡${VCS_STATUS_COMMITS_AHEAD}"
    elif [[ -n $VCS_STATUS_REMOTE_BRANCH ]]; then
      # Tip: Uncomment the next line to display '=' if up to date with the remote.
      # res+=" ${clean}="
    fi

    # ⇠42 if behind the push remote.
    (( VCS_STATUS_PUSH_COMMITS_BEHIND )) && res+=" ${clean}⇠${VCS_STATUS_PUSH_COMMITS_BEHIND}"
    (( VCS_STATUS_PUSH_COMMITS_AHEAD && !VCS_STATUS_PUSH_COMMITS_BEHIND )) && res+=" "
    # ⇢42 if ahead of the push remote; no leading space if also behind: ⇠42⇢42.
    (( VCS_STATUS_PUSH_COMMITS_AHEAD  )) && res+="${clean}⇢${VCS_STATUS_PUSH_COMMITS_AHEAD}"
    # *42 if have stashes.
    (( VCS_STATUS_STASHES        )) && res+=" ${clean}*${VCS_STATUS_STASHES}"
    # 'merge' if the repo is in an unusual state.
    [[ -n $VCS_STATUS_ACTION     ]] && res+=" ${conflicted}${VCS_STATUS_ACTION}"
    # ~42 if have merge conflicts.
    (( VCS_STATUS_NUM_CONFLICTED )) && res+=" ${conflicted}~${VCS_STATUS_NUM_CONFLICTED}"
    # +42 if have staged changes.
    (( VCS_STATUS_NUM_STAGED     )) && res+=" ${modified}+${VCS_STATUS_NUM_STAGED}"
    # !42 if have unstaged changes.
    (( VCS_STATUS_NUM_UNSTAGED   )) && res+=" ${modified}!${VCS_STATUS_NUM_UNSTAGED}"
    # ?42 if have untracked files. It's really a question mark, your font isn't broken.
    # See POWERLEVEL9K_VCS_UNTRACKED_ICON above if you want to use a different icon.
    # Remove the next line if you don't want to see untracked files at all.
    (( VCS_STATUS_NUM_UNTRACKED  )) && res+=" ${untracked}${(g::)POWERLEVEL9K_VCS_UNTRACKED_ICON}${VCS_STATUS_NUM_UNTRACKED}"
    # "─" if the number of unstaged files is unknown. This can happen due to
    # POWERLEVEL9K_VCS_MAX_INDEX_SIZE_DIRTY (see below) being set to a non-negative number lower
    # than the number of files in the Git index, or due to bash.showDirtyState being set to false
    # in the repository config. The number of staged and untracked files may also be unknown
    # in this case.
    (( VCS_STATUS_HAS_UNSTAGED == -1 )) && res+=" ${modified}─"

    typeset -g my_git_format=$res
  }
  functions -M my_git_formatter 2>/dev/null

  # Don't count the number of unstaged, untracked and conflicted files in Git repositories with
  # more than this many files in the index. Negative value means infinity.
  #
  # If you are working in Git repositories with tens of millions of files and seeing performance
  # sagging, try setting POWERLEVEL9K_VCS_MAX_INDEX_SIZE_DIRTY to a number lower than the output
  # of \`git ls-files | wc -l\`. Alternatively, add \`bash.showDirtyState = false\` to the repository's
  # config: \`git config bash.showDirtyState false\`.
  typeset -g POWERLEVEL9K_VCS_MAX_INDEX_SIZE_DIRTY=-1

  # Don't show Git status in prompt for repositories whose workdir matches this pattern.
  # For example, if set to '~', the Git repository at $HOME/.git will be ignored.
  # Multiple patterns can be combined with '|': '~(|/foo)|/bar/baz/*'.
  typeset -g POWERLEVEL9K_VCS_DISABLED_WORKDIR_PATTERN='~'

  # Disable the default Git status formatting.
  typeset -g POWERLEVEL9K_VCS_DISABLE_GITSTATUS_FORMATTING=true
  # Install our own Git status formatter.
  typeset -g POWERLEVEL9K_VCS_CONTENT_EXPANSION='${$((my_git_formatter(1)))+${my_git_format}}'
  typeset -g POWERLEVEL9K_VCS_LOADING_CONTENT_EXPANSION='${$((my_git_formatter(0)))+${my_git_format}}'
  # Enable counters for staged, unstaged, etc.
  typeset -g POWERLEVEL9K_VCS_{STAGED,UNSTAGED,UNTRACKED,CONFLICTED,COMMITS_AHEAD,COMMITS_BEHIND}_MAX_NUM=-1

  
  # Icon color.
  typeset -g POWERLEVEL9K_VCS_VISUAL_IDENTIFIER_COLOR=$P10K_COLOR_MAUVE
  typeset -g POWERLEVEL9K_VCS_LOADING_VISUAL_IDENTIFIER_COLOR=$P10K_COLOR_MAUVE
  # Custom icon.
  # typeset -g POWERLEVEL9K_VCS_VISUAL_IDENTIFIER_EXPANSION='⭐'
  # Custom prefix.
  typeset -g POWERLEVEL9K_VCS_PREFIX='%F{#666666}on '

  # Show status of repositories of these types. You can add svn and/or hg if you are
  # using them. If you do, your prompt may become slow even when your current directory
  # isn't in an svn or hg repository.
  typeset -g POWERLEVEL9K_VCS_BACKENDS=(git)

  # These settings are used for repositories other than Git or when gitstatusd fails and
  # Powerlevel10k has to fall back to using vcs_info.
  typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=$P10K_COLOR_MAUVE
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=$P10K_COLOR_PINK
  typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=$P10K_COLOR_PEACH

  ##########################[ status: exit code of the last command ]###########################
  # Enable OK_PIPE, ERROR_PIPE and ERROR_SIGNAL status states to allow us to enable, disable and
  # style them independently from the regular OK and ERROR state.
  typeset -g POWERLEVEL9K_STATUS_EXTENDED_STATES=true

  # Status on success. No content, just an icon. No need to show it if prompt_char is enabled as
  # it will signify success by turning green.
  typeset -g POWERLEVEL9K_STATUS_OK=false
  typeset -g POWERLEVEL9K_STATUS_OK_FOREGROUND=$P10K_COLOR_GREEN
  typeset -g POWERLEVEL9K_STATUS_OK_VISUAL_IDENTIFIER_EXPANSION='' # U+EAB2

  # Status when some part of a pipe command fails but the overall exit status is zero. It may look
  # like this: 1|0.
  typeset -g POWERLEVEL9K_STATUS_OK_PIPE=true
  typeset -g POWERLEVEL9K_STATUS_OK_PIPE_FOREGROUND=$P10K_COLOR_GREEN
  typeset -g POWERLEVEL9K_STATUS_OK_PIPE_VISUAL_IDENTIFIER_EXPANSION='' # U+EAB2

  # Status when it's just an error code (e.g., '1'). No need to show it if prompt_char is enabled as
  # it will signify error by turning red.
  typeset -g POWERLEVEL9K_STATUS_ERROR=false
  typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=$P10K_COLOR_MAROON
  typeset -g POWERLEVEL9K_STATUS_ERROR_VISUAL_IDENTIFIER_EXPANSION='⨯'

  # Status when the last command was terminated by a signal.
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL=true
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL_FOREGROUND=$P10K_COLOR_MAROON
  # Use terse signal names: "INT" instead of "SIGINT(2)".
  typeset -g POWERLEVEL9K_STATUS_VERBOSE_SIGNAME=false
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL_VISUAL_IDENTIFIER_EXPANSION='⨯'

  # Status when some part of a pipe command fails and the overall exit status is also non-zero.
  # It may look like this: 1|0.
  typeset -g POWERLEVEL9K_STATUS_ERROR_PIPE=true
  typeset -g POWERLEVEL9K_STATUS_ERROR_PIPE_FOREGROUND=$P10K_COLOR_MAROON
  typeset -g POWERLEVEL9K_STATUS_ERROR_PIPE_VISUAL_IDENTIFIER_EXPANSION='⨯'

  ###################[ command_execution_time: duration of the last command ]###################
  # Show duration of the last command if takes at least this many seconds.
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3
  # Show this many fractional digits. Zero means round to seconds.
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION=0
  # Execution time color.
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=$P10K_COLOR_SUBTEXT1
  # Duration format: 1d 2h 3m 4s.
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FORMAT='d h m s'
  # Custom icon.
  # typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_VISUAL_IDENTIFIER_EXPANSION='⭐'
  # Custom prefix.
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PREFIX='%F{#666666}took '

  #######################[ background_jobs: presence of background jobs ]#######################
  # Don't show the number of background jobs.
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_VERBOSE=false
  # Background jobs color.
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND=$P10K_COLOR_YELLOW
  # Custom icon.
  # typeset -g POWERLEVEL9K_BACKGROUND_JOBS_VISUAL_IDENTIFIER_EXPANSION='⭐'

  #######################[ direnv: direnv status (https://direnv.net/) ]########################
  # Direnv color.
  typeset -g POWERLEVEL9K_DIRENV_FOREGROUND=$P10K_COLOR_YELLOW
  # Custom icon.
  # typeset -g POWERLEVEL9K_DIRENV_VISUAL_IDENTIFIER_EXPANSION='⭐'

  ###############[ asdf: asdf version manager (https://github.com/asdf-vm/asdf) ]###############
  # Default asdf color. Only used to display tools for which there is no color override (see below).
  # Tip:  Override this parameter for ${TOOL} with POWERLEVEL9K_ASDF_${TOOL}_FOREGROUND.
  typeset -g POWERLEVEL9K_ASDF_FOREGROUND=$P10K_COLOR_TEAL

  # There are four parameters that can be used to hide asdf tools. Each parameter describes
  # conditions under which a tool gets hidden. Parameters can hide tools but not unhide them. If at
  # least one parameter decides to hide a tool, that tool gets hidden. If no parameter decides to
  # hide a tool, it gets shown.
  #
  # Special note on the difference between POWERLEVEL9K_ASDF_SOURCES and
  # POWERLEVEL9K_ASDF_PROMPT_ALWAYS_SHOW. Consider the effect of the following commands:
  #
  #   asdf local  python 3.8.1
  #   asdf global python 3.8.1
  #
  # After running both commands the current python version is 3.8.1 and its source is "local" as
  # it takes precedence over "global". If POWERLEVEL9K_ASDF_PROMPT_ALWAYS_SHOW is set to false,
  # it'll hide python version in this case because 3.8.1 is the same as the global version.
  # POWERLEVEL9K_ASDF_SOURCES will hide python version only if the value of this parameter doesn't
  # contain "local".

  # Hide tool versions that don't come from one of these sources.
  #
  # Available sources:
  #
  # - shell   `asdf current` says "set by ASDF_${TOOL}_VERSION environment variable"
  # - local   `asdf current` says "set by /some/not/home/directory/file"
  # - global  `asdf current` says "set by /home/username/file"
  #
  # Note: If this parameter is set to (shell local global), it won't hide tools.
  # Tip:  Override this parameter for ${TOOL} with POWERLEVEL9K_ASDF_${TOOL}_SOURCES.
  typeset -g POWERLEVEL9K_ASDF_SOURCES=(shell local global)

  # If set to false, hide tool versions that are the same as global.
  #
  # Note: The name of this parameter doesn't reflect its meaning at all.
  # Note: If this parameter is set to true, it won't hide tools.
  # Tip:  Override this parameter for ${TOOL} with POWERLEVEL9K_ASDF_${TOOL}_PROMPT_ALWAYS_SHOW.
  typeset -g POWERLEVEL9K_ASDF_PROMPT_ALWAYS_SHOW=false

  # If set to false, hide tool versions that are equal to "system".
  #
  # Note: If this parameter is set to true, it won't hide tools.
  # Tip: Override this parameter for ${TOOL} with POWERLEVEL9K_ASDF_${TOOL}_SHOW_SYSTEM.
  typeset -g POWERLEVEL9K_ASDF_SHOW_SYSTEM=true

  # If set to non-empty value, hide tools unless there is a file matching the specified file pattern
  # in the current directory, or its parent directory, or its grandparent directory, and so on.
  #
  # Note: If this parameter is set to empty value, it won't hide tools.
  # Note: SHOW_ON_UPGLOB isn't specific to asdf. It works with all prompt segments.
  # Tip: Override this parameter for ${TOOL} with POWERLEVEL9K_ASDF_${TOOL}_SHOW_ON_UPGLOB.
  #
  # Example: Hide nodejs version when there is no package.json and no *.js files in the current
  # directory, in `..`, in `../..` and so on.
  #
  #   typeset -g POWERLEVEL9K_ASDF_NODEJS_SHOW_ON_UPGLOB='*.js|package.json'
  typeset -g POWERLEVEL9K_ASDF_SHOW_ON_UPGLOB=

  # Ruby version from asdf.
  typeset -g POWERLEVEL9K_ASDF_RUBY_FOREGROUND=$P10K_COLOR_PINK
  # typeset -g POWERLEVEL9K_ASDF_RUBY_VISUAL_IDENTIFIER_EXPANSION='⭐'
  # typeset -g POWERLEVEL9K_ASDF_RUBY_SHOW_ON_UPGLOB='*.foo|*.bar'

  # Python version from asdf.
  typeset -g POWERLEVEL9K_ASDF_PYTHON_FOREGROUND=$P10K_COLOR_SKY
  # typeset -g POWERLEVEL9K_ASDF_PYTHON_VISUAL_IDENTIFIER_EXPANSION='⭐'
  # typeset -g POWERLEVEL9K_ASDF_PYTHON_SHOW_ON_UPGLOB='*.foo|*.bar'

  # Go version from asdf.
  typeset -g POWERLEVEL9K_ASDF_GOLANG_FOREGROUND=$P10K_COLOR_SKY
  # typeset -g POWERLEVEL9K_ASDF_GOLANG_VISUAL_IDENTIFIER_EXPANSION='⭐'
  # typeset -g POWERLEVEL9K_ASDF_GOLANG_SHOW_ON_UPGLOB='*.foo|*.bar'

  # Node.js version from asdf.
  typeset -g POWERLEVEL9K_ASDF_NODEJS_FOREGROUND=$P10K_COLOR_GREEN
  # typeset -g POWERLEVEL9K_ASDF_NODEJS_VISUAL_IDENTIFIER_EXPANSION='⭐'
  # typeset -g POWERLEVEL9K_ASDF_NODEJS_SHOW_ON_UPGLOB='*.foo|*.bar'

  # Rust version from asdf.
  typeset -g POWERLEVEL9K_ASDF_RUST_FOREGROUND=$P10K_COLOR_SKY
  # typeset -g POWERLEVEL9K_ASDF_RUST_VISUAL_IDENTIFIER_EXPANSION='⭐'
  # typeset -g POWERLEVEL9K_ASDF_RUST_SHOW_ON_UPGLOB='*.foo|*.bar'

  ################[ dotnet_version: .NET version (https://dotnet.microsoft.com) ]#################
  # .NET version color.
  typeset -g POWERLEVEL9K_DOTNET_VERSION_FOREGROUND=$P10K_COLOR_BLUE
  # Custom icon.
  # typeset -g POWERLEVEL9K_DOTNET_VERSION_VISUAL_IDENTIFIER_EXPANSION='⭐'

  #####################[ php_version: php version (https://www.php.net/) ]######################
  # PHP version color.
  typeset -g POWERLEVEL9K_PHP_VERSION_FOREGROUND=$P10K_COLOR_BLUE
  # Custom icon.
  # typeset -g POWERLEVEL9K_PHP_VERSION_VISUAL_IDENTIFIER_EXPANSION='⭐'

  ##########[ laravel_version: laravel php framework version (https://laravel.com/) ]###########
  # Laravel version color.
  typeset -g POWERLEVEL9K_LARAVEL_VERSION_FOREGROUND=$P10K_COLOR_RED
  # Custom icon.
  # typeset -g POWERLEVEL9K_LARAVEL_VERSION_VISUAL_IDENTIFIER_EXPANSION='⭐'

  ####################[ java_version: java version (https://www.java.com/) ]####################
  # Java version color.
  typeset -g POWERLEVEL9K_JAVA_VERSION_FOREGROUND=$P10K_COLOR_PEACH
  # Custom icon.
  # typeset -g POWERLEVEL9K_JAVA_VERSION_VISUAL_IDENTIFIER_EXPANSION='⭐'

  ###[ package: name@version from package.json (https://docs.npmjs.com/files/package.json) ]####
  # Package color.
  typeset -g POWERLEVEL9K_PACKAGE_FOREGROUND=$P10K_COLOR_TEXT
  # Custom icon.
  # typeset -g POWERLEVEL9K_PACKAGE_VISUAL_IDENTIFIER_EXPANSION='⭐'

  #######################[ rbenv: ruby version from rbenv (https://github.com/rbenv/rbenv) ]#######################
  typeset -g POWERLEVEL9K_RBENV_FOREGROUND=$P10K_COLOR_PINK

  #######################[ rvm: ruby version from rvm (https://rvm.io) ]#######################
  typeset -g POWERLEVEL9K_RVM_FOREGROUND=$P10K_COLOR_PINK

  ################[ fvm: flutter version management (https://github.com/leoafarias/fvm) ]################
  typeset -g POWERLEVEL9K_FVM_FOREGROUND=$P10K_COLOR_SAPPHIRE

  #######################[ luaenv: lua version from luaenv (https://github.com/cehoffman/luaenv) ]#######################
  typeset -g POWERLEVEL9K_LUAENV_FOREGROUND=$P10K_COLOR_BLUE

  #######################[ jenv: java version from jenv (https://github.com/jenv/jenv) ]#######################
  typeset -g POWERLEVEL9K_JENV_FOREGROUND=$P10K_COLOR_PEACH

  #######################[ plenv: perl version from plenv (https://github.com/tokuhirom/plenv) ]#######################
  typeset -g POWERLEVEL9K_PLENV_FOREGROUND=$P10K_COLOR_BLUE

  #######################[ perlbrew: perl version from perlbrew (https://github.com/gugod/App-perlbrew) ]#######################
  typeset -g POWERLEVEL9K_PERLBREW_FOREGROUND=$P10K_COLOR_BLUE

  #######################[ phpenv: php version from phpenv (https://github.com/phpenv/phpenv) ]#######################
  typeset -g POWERLEVEL9K_PHPENV_FOREGROUND=$P10K_COLOR_BLUE

  #######################[ scalaenv: scala version from scalaenv (https://github.com/scalaenv/scalaenv) ]#######################
  typeset -g POWERLEVEL9K_SCALAENV_FOREGROUND=$P10K_COLOR_RED

  #######################[ haskell_stack: haskell version from stack (https://haskellstack.org/) ]#######################
  typeset -g POWERLEVEL9K_HASKELL_STACK_FOREGROUND=$P10K_COLOR_MAUVE

  #########################[ kubecontext: current kubernetes context (https://kubernetes.io/) ]#########################
  typeset -g POWERLEVEL9K_KUBECONTEXT_SHOW_ON_COMMAND='kubectl|helm|kubens|kubectx|oc|istioctl|kogito|k9s|helmfile|flux|fluxctl|stern'
  typeset -g POWERLEVEL9K_KUBECONTEXT_CLASSES=(
      '*'  DEFAULT)
  typeset -g POWERLEVEL9K_KUBECONTEXT_DEFAULT_FOREGROUND=$P10K_COLOR_TEAL
  # typeset -g POWERLEVEL9K_KUBECONTEXT_DEFAULT_VISUAL_IDENTIFIER_EXPANSION='⭐'

  ######################[ terraform: terraform workspace (https://www.terraform.io) ]######################
  typeset -g POWERLEVEL9K_TERRAFORM_SHOW_DEFAULT=false
  typeset -g POWERLEVEL9K_TERRAFORM_CLASSES=(
      '*'         OTHER)
  typeset -g POWERLEVEL9K_TERRAFORM_OTHER_FOREGROUND=$P10K_COLOR_MAUVE

  ################[ terraform_version: terraform version (https://www.terraform.io) ]################
  typeset -g POWERLEVEL9K_TERRAFORM_VERSION_FOREGROUND=$P10K_COLOR_MAUVE

  ################[ aws: aws profile (https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html) ]################
  typeset -g POWERLEVEL9K_AWS_SHOW_ON_COMMAND='aws|awless|terraform|pulumi|terragrunt'
  typeset -g POWERLEVEL9K_AWS_CLASSES=(
      '*'  DEFAULT)
  typeset -g POWERLEVEL9K_AWS_DEFAULT_FOREGROUND=$P10K_COLOR_PEACH

  ################[ aws_eb_env: aws elastic beanstalk environment (https://aws.amazon.com/elasticbeanstalk/) ]################
  typeset -g POWERLEVEL9K_AWS_EB_ENV_FOREGROUND=$P10K_COLOR_PEACH

  ################[ azure: azure account name (https://docs.microsoft.com/en-us/cli/azure) ]################
  typeset -g POWERLEVEL9K_AZURE_SHOW_ON_COMMAND='az|terraform|pulumi|terragrunt'
  typeset -g POWERLEVEL9K_AZURE_FOREGROUND=$P10K_COLOR_BLUE

  ################[ gcloud: google cloud cli account and project (https://cloud.google.com/) ]################
  typeset -g POWERLEVEL9K_GCLOUD_SHOW_ON_COMMAND='gcloud|gcs|gsutil'
  typeset -g POWERLEVEL9K_GCLOUD_FOREGROUND=$P10K_COLOR_BLUE
  typeset -g POWERLEVEL9K_GCLOUD_PARTIAL_CONTENT_EXPANSION='${P9K_GCLOUD_PROJECT_ID//\%/%%}'
  typeset -g POWERLEVEL9K_GCLOUD_COMPLETE_CONTENT_EXPANSION='${P9K_GCLOUD_PROJECT_ID//\%/%%}'
  typeset -g POWERLEVEL9K_GCLOUD_REFRESH_PROJECT_NAME_SECONDS=60

  ################[ google_app_cred: google application credentials (https://cloud.google.com/docs/authentication/production) ]################
  typeset -g POWERLEVEL9K_GOOGLE_APP_CRED_SHOW_ON_COMMAND='terraform|pulumi|terragrunt'
  typeset -g POWERLEVEL9K_GOOGLE_APP_CRED_CLASSES=(
      '*'             DEFAULT)
  typeset -g POWERLEVEL9K_GOOGLE_APP_CRED_DEFAULT_FOREGROUND=$P10K_COLOR_BLUE

  ###############################[ public_ip: public IP address ]###############################
  typeset -g POWERLEVEL9K_PUBLIC_IP_FOREGROUND=$P10K_COLOR_YELLOW

  ########################[ vpn_ip: virtual private network indicator ]#########################
  typeset -g POWERLEVEL9K_VPN_IP_FOREGROUND=$P10K_COLOR_TEAL
  typeset -g POWERLEVEL9K_VPN_IP_INTERFACE='(gpd|wg|(.*tun)|tailscale)[0-9]*'
  typeset -g POWERLEVEL9K_VPN_IP_SHOW_ALL=false

  ########################[ ip: ip address and bandwidth usage for a specified network interface ]#########################
  typeset -g POWERLEVEL9K_IP_FOREGROUND=$P10K_COLOR_TEAL
  typeset -g POWERLEVEL9K_IP_INTERFACE='[ew].*'

  ########################[ proxy: system-wide http/https/ftp proxy ]#########################
  typeset -g POWERLEVEL9K_PROXY_FOREGROUND=$P10K_COLOR_YELLOW

  ################################[ battery: internal battery ]#################################
  typeset -g POWERLEVEL9K_BATTERY_LOW_THRESHOLD=20
  typeset -g POWERLEVEL9K_BATTERY_LOW_FOREGROUND=$P10K_COLOR_RED
  typeset -g POWERLEVEL9K_BATTERY_{CHARGING,CHARGED}_FOREGROUND=$P10K_COLOR_GREEN
  typeset -g POWERLEVEL9K_BATTERY_DISCONNECTED_FOREGROUND=$P10K_COLOR_YELLOW
  typeset -g POWERLEVEL9K_BATTERY_STAGES='\uf58d\uf579\uf57a\uf57b\uf57c\uf57d\uf57e\uf57f\uf580\uf581\uf578'
  typeset -g POWERLEVEL9K_BATTERY_VERBOSE=false

  #####################################[ wifi: wifi speed ]#####################################
  typeset -g POWERLEVEL9K_WIFI_FOREGROUND=$P10K_COLOR_TEAL

  ####################################[ time: current time ]####################################
  typeset -g POWERLEVEL9K_TIME_FOREGROUND=$P10K_COLOR_OVERLAY2
  typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%H:%M:%S}'
  # typeset -g POWERLEVEL9K_TIME_VISUAL_IDENTIFIER_EXPANSION='⭐'

  #################################[ context: user@hostname ]##################################
  typeset -g POWERLEVEL9K_CONTEXT_FOREGROUND=$P10K_COLOR_SUBTEXT1
  typeset -g POWERLEVEL9K_CONTEXT_TEMPLATE='%n@%m'
  typeset -g POWERLEVEL9K_CONTEXT_ROOT_TEMPLATE='%n@%m'
  typeset -g POWERLEVEL9K_CONTEXT_{DEFAULT,SUDO}_{CONTENT,VISUAL_IDENTIFIER}_EXPANSION=

  ###[ virtualenv: python virtual environment (https://docs.python.org/3/library/venv.html) ]###
  typeset -g POWERLEVEL9K_VIRTUALENV_FOREGROUND=$P10K_COLOR_SKY
  typeset -g POWERLEVEL9K_VIRTUALENV_SHOW_PYTHON_VERSION=true
  typeset -g POWERLEVEL9K_VIRTUALENV_SHOW_WITH_PYENV=false
  typeset -g POWERLEVEL9K_VIRTUALENV_{LEFT,RIGHT}_DELIMITER=

  #####################[ anaconda: conda environment (https://conda.io/) ]######################
  typeset -g POWERLEVEL9K_ANACONDA_FOREGROUND=$P10K_COLOR_SKY
  typeset -g POWERLEVEL9K_ANACONDA_CONTENT_EXPANSION='${${${${CONDA_PROMPT_MODIFIER#\(}% }%\)}:-${CONDA_PREFIX:t}}'

  ################[ pyenv: python environment (https://github.com/pyenv/pyenv) ]################
  typeset -g POWERLEVEL9K_PYENV_FOREGROUND=$P10K_COLOR_SKY
  typeset -g POWERLEVEL9K_PYENV_SOURCES=(shell local global)
  typeset -g POWERLEVEL9K_PYENV_PROMPT_ALWAYS_SHOW=false
  typeset -g POWERLEVEL9K_PYENV_SHOW_SYSTEM=true
  typeset -g POWERLEVEL9K_PYENV_CONTENT_EXPANSION='${P9K_CONTENT}${${P9K_PYENV_PYTHON_VERSION:#$P9K_CONTENT}:+ $P9K_PYENV_PYTHON_VERSION}'

  ################[ goenv: go environment (https://github.com/syndbg/goenv) ]################
  typeset -g POWERLEVEL9K_GOENV_FOREGROUND=$P10K_COLOR_SKY
  typeset -g POWERLEVEL9K_GOENV_SOURCES=(shell local global)
  typeset -g POWERLEVEL9K_GOENV_PROMPT_ALWAYS_SHOW=false
  typeset -g POWERLEVEL9K_GOENV_SHOW_SYSTEM=true

  ################[ nodenv: node.js version from nodenv (https://github.com/nodenv/nodenv) ]################
  typeset -g POWERLEVEL9K_NODENV_FOREGROUND=$P10K_COLOR_GREEN
  typeset -g POWERLEVEL9K_NODENV_SOURCES=(shell local global)
  typeset -g POWERLEVEL9K_NODENV_PROMPT_ALWAYS_SHOW=false
  typeset -g POWERLEVEL9K_NODENV_SHOW_SYSTEM=true

  ################[ nvm: node.js version from nvm (https://github.com/nvm-sh/nvm) ]################
  typeset -g POWERLEVEL9K_NVM_FOREGROUND=$P10K_COLOR_GREEN

  ################[ nodeenv: node.js environment (https://github.com/ekalinin/nodeenv) ]################
  typeset -g POWERLEVEL9K_NODEENV_FOREGROUND=$P10K_COLOR_GREEN
  typeset -g POWERLEVEL9K_NODEENV_SHOW_NODE_VERSION=true
  typeset -g POWERLEVEL9K_NODEENV_{LEFT,RIGHT}_DELIMITER=

  ################[ node_version: node.js version ]################
  typeset -g POWERLEVEL9K_NODE_VERSION_FOREGROUND=$P10K_COLOR_GREEN
  typeset -g POWERLEVEL9K_NODE_VERSION_PROJECT_ONLY=true

  ################[ go_version: go version (https://golang.org) ]################
  typeset -g POWERLEVEL9K_GO_VERSION_FOREGROUND=$P10K_COLOR_SKY
  typeset -g POWERLEVEL9K_GO_VERSION_PROJECT_ONLY=true

  ################[ rust_version: rustc version (https://www.rust-lang.org) ]################
  typeset -g POWERLEVEL9K_RUST_VERSION_FOREGROUND=$P10K_COLOR_SKY
  typeset -g POWERLEVEL9K_RUST_VERSION_PROJECT_ONLY=true

  ################[ nordvpn: nordvpn connection status, linux only (https://nordvpn.com/) ]################
  typeset -g POWERLEVEL9K_NORDVPN_FOREGROUND=$P10K_COLOR_BLUE
  typeset -g POWERLEVEL9K_NORDVPN_{DISCONNECTED,CONNECTING,DISCONNECTING}_CONTENT_EXPANSION=
  typeset -g POWERLEVEL9K_NORDVPN_{DISCONNECTED,CONNECTING,DISCONNECTING}_VISUAL_IDENTIFIER_EXPANSION=

  ################[ ranger: ranger shell (https://github.com/ranger/ranger) ]################
  typeset -g POWERLEVEL9K_RANGER_FOREGROUND=$P10K_COLOR_YELLOW
  # typeset -g POWERLEVEL9K_RANGER_VISUAL_IDENTIFIER_EXPANSION='⭐'

  ################[ yazi: yazi shell (https://github.com/sxyazi/yazi) ]################
  typeset -g POWERLEVEL9K_YAZI_FOREGROUND=$P10K_COLOR_YELLOW
  # typeset -g POWERLEVEL9K_YAZI_VISUAL_IDENTIFIER_EXPANSION='⭐'

  ################[ nnn: nnn shell (https://github.com/jarun/nnn) ]################
  typeset -g POWERLEVEL9K_NNN_FOREGROUND=$P10K_COLOR_YELLOW
  # typeset -g POWERLEVEL9K_NNN_VISUAL_IDENTIFIER_EXPANSION='⭐'

  ################[ lf: lf shell (https://github.com/gokcehan/lf) ]################
  typeset -g POWERLEVEL9K_LF_FOREGROUND=$P10K_COLOR_YELLOW
  # typeset -g POWERLEVEL9K_LF_VISUAL_IDENTIFIER_EXPANSION='⭐'

  ################[ xplr: xplr shell (https://github.com/sayanarijit/xplr) ]################
  typeset -g POWERLEVEL9K_XPLR_FOREGROUND=$P10K_COLOR_YELLOW
  # typeset -g POWERLEVEL9K_XPLR_VISUAL_IDENTIFIER_EXPANSION='⭐'

  ################[ vim_shell: vim shell indicator (:sh) ]################
  typeset -g POWERLEVEL9K_VIM_SHELL_FOREGROUND=$P10K_COLOR_TEAL
  # typeset -g POWERLEVEL9K_VIM_SHELL_VISUAL_IDENTIFIER_EXPANSION='⭐'

  ################[ midnight_commander: midnight commander shell (https://midnight-commander.org/) ]################
  typeset -g POWERLEVEL9K_MIDNIGHT_COMMANDER_FOREGROUND=$P10K_COLOR_YELLOW
  # typeset -g POWERLEVEL9K_MIDNIGHT_COMMANDER_VISUAL_IDENTIFIER_EXPANSION='⭐'

  ################[ nix_shell: nix shell (https://nixos.org/nixos/nix-pills/developing-with-nix-shell.html) ]################
  typeset -g POWERLEVEL9K_NIX_SHELL_FOREGROUND=$P10K_COLOR_MAUVE
  typeset -g POWERLEVEL9K_NIX_SHELL_INFER_FROM_FILES=false
  typeset -g POWERLEVEL9K_NIX_SHELL_CONTENT_EXPANSION=

  ################[ chezmoi_shell: chezmoi shell (https://www.chezmoi.io/) ]################
  typeset -g POWERLEVEL9K_CHEZMOI_SHELL_FOREGROUND=$P10K_COLOR_PEACH
  # typeset -g POWERLEVEL9K_CHEZMOI_SHELL_VISUAL_IDENTIFIER_EXPANSION='⭐'

  ################[ todo: todo items (https://github.com/todotxt/todo.txt-cli) ]################
  typeset -g POWERLEVEL9K_TODO_FOREGROUND=$P10K_COLOR_SAPPHIRE
  typeset -g POWERLEVEL9K_TODO_HIDE_ZERO_TOTAL=true
  typeset -g POWERLEVEL9K_TODO_HIDE_ZERO_FILTERED=false

  ################[ timewarrior: timewarrior tracking status (https://timewarrior.net/) ]################
  typeset -g POWERLEVEL9K_TIMEWARRIOR_FOREGROUND=$P10K_COLOR_GREEN
  typeset -g POWERLEVEL9K_TIMEWARRIOR_CONTENT_EXPANSION='${P9K_CONTENT:0:24}${${P9K_CONTENT:24}:+…}'

  ################[ taskwarrior: taskwarrior task count (https://taskwarrior.org/) ]################
  typeset -g POWERLEVEL9K_TASKWARRIOR_FOREGROUND=$P10K_COLOR_TEAL

  ################[ per_directory_history: Oh My Zsh per-directory-history local/global indicator ]################
  typeset -g POWERLEVEL9K_PER_DIRECTORY_HISTORY_LOCAL_FOREGROUND=$P10K_COLOR_PEACH
  typeset -g POWERLEVEL9K_PER_DIRECTORY_HISTORY_GLOBAL_FOREGROUND=$P10K_COLOR_BLUE

  ################[ cpu_arch: CPU architecture ]################
  typeset -g POWERLEVEL9K_CPU_ARCH_FOREGROUND=$P10K_COLOR_TEXT

  ################[ disk_usage: disk usage ]################
  typeset -g POWERLEVEL9K_DISK_USAGE_NORMAL_FOREGROUND=$P10K_COLOR_GREEN
  typeset -g POWERLEVEL9K_DISK_USAGE_WARNING_FOREGROUND=$P10K_COLOR_YELLOW
  typeset -g POWERLEVEL9K_DISK_USAGE_CRITICAL_FOREGROUND=$P10K_COLOR_RED
  typeset -g POWERLEVEL9K_DISK_USAGE_WARNING_LEVEL=90
  typeset -g POWERLEVEL9K_DISK_USAGE_CRITICAL_LEVEL=95
  typeset -g POWERLEVEL9K_DISK_USAGE_ONLY_WARNING=false

  ################[ ram: free RAM ]################
  typeset -g POWERLEVEL9K_RAM_FOREGROUND=$P10K_COLOR_GREEN

  ################[ swap: used swap ]################
  typeset -g POWERLEVEL9K_SWAP_FOREGROUND=$P10K_COLOR_YELLOW

  ################[ load: CPU load ]################
  typeset -g POWERLEVEL9K_LOAD_NORMAL_FOREGROUND=$P10K_COLOR_GREEN
  typeset -g POWERLEVEL9K_LOAD_WARNING_FOREGROUND=$P10K_COLOR_YELLOW
  typeset -g POWERLEVEL9K_LOAD_CRITICAL_FOREGROUND=$P10K_COLOR_RED

  # User-defined prompt segments may be added here.

  # Transient prompt works similarly to the builtin transient_rprompt option. It trims down prompt
  # when accepting a command line. Supported values:
  #
  #   - off:      Don't trim prompt (default).
  #   - always:   Trim prompt when accepting a command line.
  #   - same-dir: Trim prompt when accepting a command line unless this is the first command
  #               typed after changing current working directory.
  #
  # You can customize the content of transient prompt options.
  typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=always

  # Instant prompt mode.
  #
  #   - off:     Disable instant prompt. Choose this if you've enabled instant prompt by accident.
  #   - quiet:   Enable instant prompt. Display warnings when detecting console output during
  #              zsh initialization. Choose this if you've never tried instant prompt.
  #   - verbose: Enable instant prompt. Display multiple warnings when detecting console output
  #              during zsh initialization. Choose this if you want to know what exactly is
  #              printing to the console.
  #   - top:     Enable instant prompt. Suppress all warnings. Choose this if you know what you
  #              are doing.
  typeset -g POWERLEVEL9K_INSTANT_PROMPT=verbose

  # HOT RELOAD
  (( ! $+functions[p10k] )) || p10k reload
}

# Tell \`p10k configure\` which file it should overwrite.
typeset -g POWERLEVEL9K_CONFIG_FILE=${${(%):-%x}:a}

(( ${#p10k_config_opts} )) && setopt ${p10k_config_opts[@]}
'builtin' 'unset' 'p10k_config_opts'
