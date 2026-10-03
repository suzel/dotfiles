#!/usr/bin/env zsh
# Full install: curl -fsSL https://raw.githubusercontent.com/suzel/dotfiles/main/setup.zsh | zsh -s
# Single steps: ./setup.zsh config packages   (steps: homebrew repo config packages macos)

set -euo pipefail

# Log Functions
info() { echo "\033[0;34mℹ️  $*\033[0m"; }
warn() { echo "\033[0;33m⚠️  $*\033[0m" >&2; }
error() { echo "\033[0;31m❌ $*\033[0m" >&2; }
success() { echo "\033[0;32m✅ $*\033[0m"; }

# $LINENO is function-relative inside traps, funcfiletrace has the real file:line
TRAPZERR() {
  error "Error at ${funcfiletrace[1]}"
  exit 1
}

readonly DOTFILES="$HOME/Projects/dotfiles"
readonly REPO_URL="https://github.com/suzel/dotfiles.git"
readonly BREW_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

# Repo path → target. Configs are symlinked, so edits on either side are the same file.
# zsh files are linked one by one: ZDOTDIR also gets .zsh_history/.zcompdump,
# which must stay out of the repo.
links=(
  # Zsh
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
  config/vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
  config/vscode/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json
)

# The installer also installs the Command Line Tools (git included) without the GUI dialog.
# No sudo -v elsewhere: brew and mas ask for the password themselves when they need it.
homebrew() {
  info "Setting up Homebrew..."
  if [[ ! -x /opt/homebrew/bin/brew ]]; then
    sudo -v # NONINTERACTIVE mode needs sudo already validated
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
  local i src dst
  for ((i = 1; i < ${#links}; i += 2)); do
    src=${links[i]} dst=${links[i + 1]}
    mkdir -p "${dst:h}"
    [[ -e $dst && ! -L $dst ]] && mv "$dst" "$dst.bak" # first run: keep the old copy
    ln -sfn "$DOTFILES/$src" "$dst"                    # -n: don't link inside an existing dir link
  done
  # Keep the .zsh suffix: ~/Scripts precedes /usr/bin in PATH,
  # so ~/Scripts/defaults would shadow defaults(1)
  mkdir -p ~/Scripts
  ln -sf $DOTFILES/scripts/*.zsh ~/Scripts/
  rm -f ~/Scripts/*(N-@) # drop links to scripts renamed or removed in the repo
}

packages() {
  info "Installing Brewfile packages (quiet, may take a while)..."
  local brewfile="$DOTFILES/config/brew/Brewfile"
  # mas sees installed apps only through Spotlight; with indexing off it force-reinstalls them
  [[ $(mdutil -s /) == *"Indexing enabled"* ]] ||
    export HOMEBREW_BUNDLE_MAS_SKIP="$(awk '/^mas / {print $NF}' "$brewfile")"
  brew bundle -q --file="$brewfile" ||
    warn "Some packages failed, re-run: dotfiles packages"
  brew cleanup -q --prune=all
  # Nightly update + upgrade + cleanup (domt4/autoupdate tap from the Brewfile).
  # start refuses to run twice, delete never fails: recreating re-applies these options.
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
