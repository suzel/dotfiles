#!/usr/bin/env zsh
# Full install: curl -fsSL https://git.io/suzel-dotfiles | zsh -s
# Single steps: ./setup.zsh config packages
# Steps: homebrew repo config packages macos

set -euo pipefail

# Log Functions
info() { echo "\033[0;34mℹ️  $*\033[0m"; }
warn() { echo "\033[0;33m⚠️  $*\033[0m" >&2; }
error() { echo "\033[0;31m❌️ $*\033[0m" >&2; }
success() { echo "\033[0;32m✅ $*\033[0m"; }

# Error trap: funcfiletrace, as $LINENO is function-relative here
TRAPZERR() {
  error "Error at ${funcfiletrace[1]}"
  exit 1
}

readonly DOTFILES="$HOME/Projects/dotfiles"
readonly REPO_URL="https://github.com/suzel/dotfiles.git"
readonly GH_RAW="https://raw.githubusercontent.com"
readonly BREW_URL="$GH_RAW/Homebrew/install/HEAD/install.sh"
readonly CODE_USER=~/Library/Application\ Support/Code/User

# Repo path → target, symlinked: edits on either side hit the same file
links=(
  # Zsh, file by file: ZDOTDIR's .zsh_history/.zcompdump stay out of the repo
  config/zsh/.zshenv ~/.zshenv
  config/zsh/.zshrc ~/.config/zsh/.zshrc
  config/zsh/.zsh_aliases ~/.config/zsh/.zsh_aliases
  config/zsh/.zsh_functions ~/.config/zsh/.zsh_functions

  # Git
  config/git ~/.config/git

  # Terminal (Ghostty + Starship prompt)
  config/ghostty ~/.config/ghostty
  config/starship/starship.toml ~/.config/starship.toml

  # VS Code
  config/vscode/argv.json ~/.vscode/argv.json
  config/vscode/settings.json $CODE_USER/settings.json
  config/vscode/keybindings.json $CODE_USER/keybindings.json
  config/vscode/tasks.json $CODE_USER/tasks.json
)

# The installer adds the Command Line Tools (git too), no GUI dialog
homebrew() {
  info "Setting up Homebrew..."
  if [[ ! -x /opt/homebrew/bin/brew ]]; then
    sudo -v # NONINTERACTIVE needs it; elsewhere brew/mas ask themselves
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL "$BREW_URL")"
  fi
  eval "$(/opt/homebrew/bin/brew shellenv)"
  brew analytics off
}

# No pull: the checkout may hold uncommitted work
repo() {
  [[ -d $DOTFILES/.git ]] && return
  info "Cloning dotfiles into $DOTFILES..."
  git clone -q "$REPO_URL" "$DOTFILES"
}

config() {
  info "Linking config files and scripts..."
  local i src dst f
  for ((i = 1; i < ${#links}; i += 2)); do
    src=${links[i]} dst=${links[i + 1]}
    mkdir -p "${dst:h}"
    # first run: keep the old copy
    [[ -e $dst && ! -L $dst ]] && mv "$dst" "$dst.bak"
    # -n: don't link inside an existing dir link
    ln -sfn "$DOTFILES/$src" "$dst"
  done
  # Keep .zsh: ~/Scripts precedes /usr/bin, so defaults would shadow defaults(1)
  mkdir -p ~/Scripts
  ln -sf $DOTFILES/scripts/*.zsh ~/Scripts/
  # .js drop the suffix (names must shadow no command), npm deps: Brewfile
  for f in $DOTFILES/scripts/*.js(N); do ln -sf $f ~/Scripts/${f:t:r}; done
  rm -f ~/Scripts/*(N-@) # drop links to scripts renamed or removed in the repo
}

packages() {
  info "Installing Brewfile packages (quiet, may take a while)..."
  local brewfile="$DOTFILES/config/brew/Brewfile"
  # mas sees apps only via Spotlight; with indexing off it reinstalls them
  [[ $(mdutil -s /) == *"Indexing enabled"* ]] ||
    export HOMEBREW_BUNDLE_MAS_SKIP="$(awk '/^mas / {print $NF}' "$brewfile")"
  brew bundle -q --file="$brewfile" ||
    warn "Some packages failed, re-run: dotfiles packages"
  brew cleanup -q --prune=all
  # Nightly upgrade (Brewfile tap); start refuses to rerun, so delete first
  brew autoupdate delete >/dev/null
  brew autoupdate start 03:00 --upgrade --cleanup --ac-only --notify-on-error
}

macos() {
  info "Applying macOS settings..."
  zsh "$DOTFILES/scripts/defaults.zsh"
}

main() {
  (($#)) || set -- homebrew repo config packages macos
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

# Last line: with curl | zsh nothing runs until the whole script has arrived
main "$@"
