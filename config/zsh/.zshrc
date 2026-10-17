# Options
setopt no_clobber interactive_comments
setopt share_history hist_ignore_all_dups hist_ignore_space
setopt hist_reduce_blanks hist_verify
setopt auto_cd auto_pushd pushd_ignore_dups
setopt always_to_end

# PATH
typeset -U path fpath
path=(
  "/opt/homebrew/bin"
  "/opt/homebrew/sbin"
  "/opt/homebrew/opt/rustup/bin"
  $path
  "$HOME/.local/bin"
  "$HOME/.bun/bin"
  "$HOME/.cargo/bin"
  "$HOME/go/bin"
  "$XDG_DATA_HOME/pnpm/bin"
  "$SCRIPTS_DIR"
)

# History
HISTFILE="$ZDOTDIR/.zsh_history"
HISTSIZE=10000
SAVEHIST=$HISTSIZE

# Completion
fpath=(
  "$ZDOTDIR/functions"
  "/opt/homebrew/share/zsh-completions"
  "/opt/homebrew/share/zsh/site-functions"
  $fpath
)
autoload -Uz compinit
() {
  local dump=($ZDOTDIR/.zcompdump(N.mh+24))
  if (($#dump)); then compinit && touch $dump; else compinit -C; fi
}
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh"
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:warnings' format 'No matches: %d'

# Keybindings
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward

# Plugins
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source <(/opt/homebrew/bin/fzf --zsh)
eval "$(/opt/homebrew/bin/starship init zsh)"
eval "$(/opt/homebrew/bin/zoxide init zsh)"

# Aliases & Functions
[[ -f "$ZDOTDIR/aliases.zsh" ]] && source "$ZDOTDIR/aliases.zsh"
autoload -Uz $ZDOTDIR/functions/*(.:t)
