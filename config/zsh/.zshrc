# PATH
typeset -U path
path=(
  "/opt/homebrew/bin"
  "/opt/homebrew/sbin"
  "$HOME/.local/bin"
  "$HOME/.bun/bin"
  "$HOME/Scripts"
  "$HOME/Library/pnpm"
  "$GOBIN"
  $path
)

# General Options
setopt no_clobber extended_glob interactive_comments

# History
HISTFILE="$ZDOTDIR/.zsh_history"
HISTSIZE=10000
SAVEHIST=$HISTSIZE
setopt append_history inc_append_history share_history
setopt hist_ignore_all_dups hist_ignore_space hist_reduce_blanks hist_verify

# Navigation
setopt auto_cd auto_pushd pushd_ignore_dups cdable_vars

# Completion
setopt auto_list auto_menu always_to_end
autoload -Uz compinit
[[ -n $ZDOTDIR/.zcompdump(#qN.mh+24) ]] && compinit || compinit -C
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:warnings' format 'No matches: %d'

# Keybindings
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward

# Plugins
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
eval "$(/opt/homebrew/bin/starship init zsh)"

# Aliases & Functions
[[ -f "$ZDOTDIR/.zsh_aliases" ]] && source "$ZDOTDIR/.zsh_aliases"
[[ -f "$ZDOTDIR/.zsh_functions" ]] && source "$ZDOTDIR/.zsh_functions"