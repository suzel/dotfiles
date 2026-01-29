# XDG Base Directory
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

# ZDOTDIR
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# Environment
export EDITOR="code --wait"
export VISUAL="$EDITOR"
export LANG=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8

# PATH
typeset -U path
path=(
  "/opt/homebrew/bin"
  "/opt/homebrew/sbin"
  "$HOME/.local/bin"
  "$HOME/Scripts"
  "$HOME/Library/pnpm"
  "/usr/local/go/bin"
  $path
)

# Homebrew
export HOMEBREW_NO_ENV_HINTS=1

# Directories
export PROJECTS_DIR="$HOME/Projects"
export SCRIPTS_DIR="$HOME/Scripts"
export ICLOUD_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs"

# Starship config path
export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship/starship.toml"
