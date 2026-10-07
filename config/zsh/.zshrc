# Options
setopt no_clobber extended_glob interactive_comments
setopt share_history hist_ignore_all_dups hist_ignore_space
setopt hist_reduce_blanks hist_verify
setopt auto_cd auto_pushd pushd_ignore_dups cdable_vars
setopt always_to_end

# PATH
typeset -U path fpath
path=(
  "/opt/homebrew/bin"
  "/opt/homebrew/sbin"
  "$HOME/.local/bin"
  "$HOME/.bun/bin"
  "$HOME/.cargo/bin"
  "$HOME/go/bin"
  "$HOME/Library/pnpm"
  "$SCRIPTS_DIR"
  $path
)

# History
HISTFILE="$ZDOTDIR/.zsh_history"
HISTSIZE=10000
SAVEHIST=$HISTSIZE

# Completion
fpath=(
  "/opt/homebrew/share/zsh-completions"
  "/opt/homebrew/share/zsh/site-functions"
  $fpath
)
autoload -Uz compinit
if [[ -n $ZDOTDIR/.zcompdump(#qN.mh+24) ]]; then
  compinit && touch $ZDOTDIR/.zcompdump
else
  compinit -C
fi
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
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
[[ -f "$ZDOTDIR/.zsh_aliases" ]] && source "$ZDOTDIR/.zsh_aliases"
[[ -f "$ZDOTDIR/.zsh_functions" ]] && source "$ZDOTDIR/.zsh_functions"
