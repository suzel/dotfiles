#!/usr/bin/env zsh

# =============================================================================
# Dotfiles Setup
# =============================================================================
# Installs Homebrew and packages, links configs and applies macOS defaults.
# Usage: curl -fsSL https://git.io/suzel-dotfiles | zsh -s (full install)
#        ./setup.zsh config packages (single steps)
# Steps: homebrew repo config packages shell github secrets macos
# =============================================================================

set -euo pipefail

# Logging
info() { echo "\033[0;34mℹ️  $*\033[0m"; }
warn() { echo "\033[0;33m⚠️  $*\033[0m" >&2; }
error() { echo "\033[0;31m❌️ $*\033[0m" >&2; }
success() { echo "\033[0;32m✅ $*\033[0m"; }

# Error trap
TRAPZERR() { error "Error at ${funcfiletrace[1]}" && exit 1; }

readonly DOTFILES="$HOME/Projects/dotfiles"
readonly REPO_URL="https://github.com/suzel/dotfiles.git"
readonly GH_RAW="https://raw.githubusercontent.com"
readonly BREW_URL="$GH_RAW/Homebrew/install/HEAD/install.sh"
readonly CODE_USER="$HOME/Library/Application Support/Code/User"
readonly FIREFOX="$HOME/Library/Application Support/Firefox/Profiles"
readonly FF_POLICIES=/Library/Preferences/org.mozilla.firefox
readonly ICLOUD="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
readonly SECRETS=$ICLOUD/Secrets/secrets.env

links=(
  # Zsh
  config/zsh/.zshenv ~/.zshenv
  config/zsh/.zshenv ~/.config/zsh/.zshenv
  config/zsh/.zshrc ~/.config/zsh/.zshrc
  config/zsh/aliases.zsh ~/.config/zsh/aliases.zsh
  config/zsh/functions ~/.config/zsh/functions

  # Git
  config/git ~/.config/git

  # Cargo
  config/cargo/config.toml ~/.cargo/config.toml

  # Terminal
  config/ghostty ~/.config/ghostty
  config/starship/starship.toml ~/.config/starship.toml

  # Claude Code
  config/claude/CLAUDE.md ~/.claude/CLAUDE.md
  config/claude/settings.json ~/.claude/settings.json
  config/claude/guides ~/.claude/guides
  config/claude/skills ~/.claude/skills
  config/claude/agents ~/.claude/agents

  # VS Code
  config/vscode/argv.json ~/.vscode/argv.json
  config/vscode/settings.json $CODE_USER/settings.json
  config/vscode/keybindings.json $CODE_USER/keybindings.json
  config/vscode/tasks.json $CODE_USER/tasks.json
  config/vscode/snippets $CODE_USER/snippets
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
  local i src dst f ff=($FIREFOX/*.default-release(N/))
  ((${#ff})) && links+=(
    config/firefox/user.js $ff[1]/user.js
    config/firefox/customKeys.json $ff[1]/customKeys.json
    config/firefox/chrome $ff[1]/chrome
  )
  plutil -extract policies xml1 -o - $DOTFILES/config/firefox/policies.json |
    sudo defaults import $FF_POLICIES -
  sudo defaults write $FF_POLICIES EnterprisePoliciesEnabled -bool true
  for ((i = 1; i < ${#links}; i += 2)); do
    src=${links[i]} dst=${links[i + 1]}
    mkdir -p "${dst:h}"
    [[ -e $dst && ! -L $dst ]] && rm -rf "$dst"
    ln -sfn "$DOTFILES/$src" "$dst"
  done
  mkdir -p ~/Scripts
  ln -sf $DOTFILES/scripts/*.zsh ~/Scripts/
  rm -f ~/Scripts/*(N-@) ~/.claude/*(N-@)
}

# Brewfile install
packages() {
  info "Installing Brewfile packages (quiet, may take a while)..."
  local brewfile="$DOTFILES/config/brew/Brewfile"
  local rustup=/opt/homebrew/opt/rustup/bin/rustup
  [[ $(mdutil -s /) == *"Indexing enabled"* ]] ||
    export HOMEBREW_BUNDLE_MAS_SKIP="$(awk '/^mas / {print $NF}' "$brewfile")"
  HOMEBREW_NO_AUTO_UPDATE=1 brew bundle -q --file="$brewfile" ||
    warn "Some packages failed, re-run: dotfiles packages"
  [[ -x $rustup ]] && $rustup -q default stable
  brew cleanup --prune=all >/dev/null
  brew autoupdate delete >/dev/null
  brew autoupdate start 03:00 --upgrade --cleanup --ac-only \
    --notify-on-error &>/dev/null
}

# Homebrew zsh as login shell
shell() {
  info "Setting Homebrew zsh as login shell..."
  local zsh=/opt/homebrew/bin/zsh
  [[ -x $zsh ]] || {
    warn "Homebrew zsh not found, skipping"
    return
  }
  grep -qx $zsh /etc/shells ||
    print -r -- $zsh | sudo tee -a /etc/shells >/dev/null
  [[ $(dscl . -read ~ UserShell) == *$zsh ]] || chsh -s $zsh </dev/tty
}

# GitHub login, signing, SSH key passphrase in Keychain
github() {
  info "Setting up GitHub (approve in the browser)..."
  local scope=admin:ssh_signing_key
  gh auth status &>/dev/null ||
    gh auth login -h github.com -p ssh -w -s $scope </dev/tty
  [[ $(gh auth status 2>&1) == *$scope* ]] ||
    gh auth refresh -h github.com -s $scope </dev/tty
  gh ssh-key add ~/.ssh/id_ed25519.pub --type signing \
    --title "$(scutil --get ComputerName)"
  chmod 700 ~/.ssh
  grep -qx '  UseKeychain yes' ~/.ssh/config 2>/dev/null ||
    print -r -- $'\nHost *\n  UseKeychain yes\n  AddKeysToAgent yes' \
      >>~/.ssh/config
  ssh-add --apple-use-keychain ~/.ssh/id_ed25519 </dev/tty
}

# iCloud secrets file: permissions, one-time reminder
secrets() {
  info "Checking iCloud secrets file..."
  [[ -f $SECRETS ]] || {
    warn "Missing $SECRETS (wait for iCloud sync, or create it)"
    return
  }
  chmod 600 "$SECRETS"
  info "Once: Finder > Control-click Secrets > Keep Downloaded"
  open -R "${SECRETS:h}"
}

# macOS defaults
macos() {
  info "Applying macOS settings..."
  zsh "$DOTFILES/scripts/defaults.zsh"
}

# Run steps
main() {
  (($#)) || set -- homebrew repo config packages shell github secrets macos
  local step
  for step; do
    ((${+functions[$step]} == 0)) && error "Unknown step: $step" && exit 1
    $step
  done
  success "Completed!"
}

main "$@"
