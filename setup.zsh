#!/usr/bin/env zsh

# Full install: curl -fsSL https://git.io/suzel-dotfiles | zsh -s
# Single steps: ./setup.zsh config packages
# Steps: homebrew repo config packages github macos

set -euo pipefail

# Logging
info() { echo "\033[0;34mℹ️  $*\033[0m"; }
warn() { echo "\033[0;33m⚠️  $*\033[0m" >&2; }
error() { echo "\033[0;31m❌️ $*\033[0m" >&2; }
success() { echo "\033[0;32m✅ $*\033[0m"; }

# Error trap
TRAPZERR() {
  error "Error at ${funcfiletrace[1]}"
  exit 1
}

readonly DOTFILES="$HOME/Projects/dotfiles"
readonly REPO_URL="https://github.com/suzel/dotfiles.git"
readonly GH_RAW="https://raw.githubusercontent.com"
readonly BREW_URL="$GH_RAW/Homebrew/install/HEAD/install.sh"
readonly CODE_USER=~/Library/Application\ Support/Code/User

links=(
  config/zsh/.zshenv ~/.zshenv
  config/zsh/.zshrc ~/.config/zsh/.zshrc
  config/zsh/.zsh_aliases ~/.config/zsh/.zsh_aliases
  config/zsh/.zsh_functions ~/.config/zsh/.zsh_functions

  config/git ~/.config/git

  config/ghostty ~/.config/ghostty
  config/starship/starship.toml ~/.config/starship.toml

  config/vscode/argv.json ~/.vscode/argv.json
  config/vscode/settings.json $CODE_USER/settings.json
  config/vscode/keybindings.json $CODE_USER/keybindings.json
  config/vscode/tasks.json $CODE_USER/tasks.json
)

# Homebrew + CLT
homebrew() {
  info "Setting up Homebrew..."
  if [[ ! -x /opt/homebrew/bin/brew ]]; then
    sudo -v
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL "$BREW_URL")"
  fi
  eval "$(/opt/homebrew/bin/brew shellenv)"
  brew analytics off
}

# Clone, no pull
repo() {
  [[ -d $DOTFILES/.git ]] && return
  info "Cloning dotfiles into $DOTFILES..."
  git clone -q "$REPO_URL" "$DOTFILES"
}

# Symlink configs
config() {
  info "Linking config files and scripts..."
  local i src dst f
  for ((i = 1; i < ${#links}; i += 2)); do
    src=${links[i]} dst=${links[i + 1]}
    mkdir -p "${dst:h}"
    [[ -e $dst && ! -L $dst ]] && mv "$dst" "$dst.bak"
    ln -sfn "$DOTFILES/$src" "$dst"
  done
  mkdir -p ~/Scripts
  ln -sf $DOTFILES/scripts/*.zsh ~/Scripts/
  rm -f ~/Scripts/*(N-@)
}

# Brewfile install
packages() {
  info "Installing Brewfile packages (quiet, may take a while)..."
  local brewfile="$DOTFILES/config/brew/Brewfile"
  [[ $(mdutil -s /) == *"Indexing enabled"* ]] ||
    export HOMEBREW_BUNDLE_MAS_SKIP="$(awk '/^mas / {print $NF}' "$brewfile")"
  brew bundle -q --file="$brewfile" ||
    warn "Some packages failed, re-run: dotfiles packages"
  brew cleanup -q --prune=all
  brew autoupdate delete >/dev/null
  brew autoupdate start 03:00 --upgrade --cleanup --ac-only --notify-on-error
}

# GitHub login, signing
github() {
  info "Setting up GitHub (approve in the browser)..."
  local scope=admin:ssh_signing_key
  gh auth status &>/dev/null ||
    gh auth login -h github.com -p ssh -w -s $scope </dev/tty
  [[ $(gh auth status 2>&1) == *$scope* ]] ||
    gh auth refresh -h github.com -s $scope </dev/tty
  gh ssh-key add ~/.ssh/id_ed25519.pub --type signing \
    --title "$(scutil --get ComputerName)"
}

# macOS defaults
macos() {
  info "Applying macOS settings..."
  zsh "$DOTFILES/scripts/defaults.zsh"
}

# Run steps
main() {
  (($#)) || set -- homebrew repo config packages github macos
  local step
  for step; do
    ((${+functions[$step]})) || {
      error "Unknown step: $step"
      exit 1
    }
    $step
  done
  success "Completed!"
}

main "$@"
