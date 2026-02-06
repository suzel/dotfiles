#!/usr/bin/env zsh

set -euo pipefail

# Ask for the administrator password upfront
sudo -v

# Log Functions with Colors
info() { echo "\033[0;34mℹ️  $*\033[0m"; }
warn() { echo "\033[0;33m⚠️  $*\033[0m"; }
error() { echo "\033[0;31m❌ $*\033[0m"; }
success() { echo "\033[0;32m✅ $*\033[0m"; }

# Trap errors and display the line number
trap 'error "Error occurred at line $LINENO"; exit 1' ERR

# Parameters
readonly REPO_URL="https://github.com/suzel/dotfiles.git"
readonly REPO_PATH="$HOME/.dotfiles"
readonly BREW_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

# Install Xcode Command Line Tools
if ! xcode-select -p &>/dev/null; then
  info "Installing Xcode Command Line Tools..."
  xcode-select --install
  until xcode-select -p &>/dev/null; do
    sleep 5
  done
  success "Xcode Command Line Tools installed."
else
  success "Xcode Command Line Tools already installed."
fi

# Install dotfiles
if [[ -d "$REPO_PATH" ]]; then
  warn "Dotfiles directory already exists. Pulling latest changes..."
  cd "$REPO_PATH"
  git pull origin main || { error "Error updating dotfiles!"; exit 1 }
else
  info "Installing dotfiles..."
  if ! git clone "$REPO_URL" "$REPO_PATH"; then
    error "Error downloading dotfiles!"
    exit 1
  fi
  cd "$REPO_PATH"
fi

# Install Homebrew
if ! command -v brew &>/dev/null; then
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL $BREW_URL)"

  eval "$(/opt/homebrew/bin/brew shellenv)"
  success "Homebrew installed."
else
  success "Homebrew already installed."
fi

# Install Homebrew Packages
info "Installing Homebrew packages..."
brew bundle --file=./config/brew/Brewfile
brew autoupdate start --upgrade --cleanup --quiet
brew analytics off
brew cleanup -s
success "Homebrew packages installed."

# Update config files
info "Updating config files..."
cp -r ./config/zsh/ ~/.config/zsh/
mv ~/.config/zsh/.zshenv ~/.zshenv
source ~/.zshenv
cp -r ./config/git/ ~/.config/git/
cp -r ./config/ghostty/ ~/.config/ghostty/
cp ./config/vscode/argv.json ~/.vscode/argv.json
cp ./config/vscode/{settings,keybindings}.json ~/Library/Application\ Support/Code/User/
cp ./config/starship/starship.toml ~/.config/starship.toml
success "Config files updated."

# Create directories
info "Creating directories..."
mkdir -p $SCRIPTS_DIR $PROJECTS_DIR

# Copy script files
info "Copying script files..."
cp -r ./scripts/*.zsh $SCRIPTS_DIR

# Update macOS Settings
info "Updating macOS settings..."
zsh ./scripts/defaults.zsh
zsh ./scripts/security.zsh

# Cleanup
rm -rf "$REPO_PATH"

success "Completed!"
