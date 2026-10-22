# Options
setopt no_clobber interactive_comments
setopt share_history hist_ignore_all_dups hist_ignore_space
setopt hist_reduce_blanks hist_verify
setopt auto_cd auto_pushd pushd_ignore_dups
setopt always_to_end
setopt no_case_glob cd_silent

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
zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh"
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:warnings' format 'No matches: %d'

# Keybindings
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward

# fzf (fd respects .gitignore, bat/eza previews)
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_DEFAULT_OPTS='--height 60% --layout reverse --border'
export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always {}'"
export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {}'"
_fzf_compgen_path() { fd --hidden --exclude .git . "$1"; }
_fzf_compgen_dir() { fd --type d --hidden --exclude .git . "$1"; }

# Plugins
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source <(/opt/homebrew/bin/fzf --zsh)
eval "$(/opt/homebrew/bin/starship init zsh)"
eval "$(/opt/homebrew/bin/zoxide init zsh)"
source /opt/homebrew/share/zsh-fast-syntax-highlighting/*.plugin.zsh

# API keys from iCloud Drive (KEY=value lines only, never sourced)
() {
  local f="$ICLOUD_DIR/Secrets/secrets.env" line
  [[ -r $f ]] || return
  for line in ${(f)"$(<$f)"}; do
    [[ $line =~ '^[A-Za-z_][A-Za-z0-9_]*=' ]] && export "$line"
  done
}

# SSH key passphrase from Keychain into the agent (needed for commit signing)
ssh-add -l &>/dev/null || ssh-add --apple-load-keychain -q 2>/dev/null

# Aliases & Functions
[[ -f "$ZDOTDIR/aliases.zsh" ]] && source "$ZDOTDIR/aliases.zsh"
autoload -Uz $ZDOTDIR/functions/*(.:t)
