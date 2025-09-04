#!/usr/bin/env zsh

set -e

# Ask for the administrator password upfront
sudo -v

REPO_URL="https://github.com/suzel/dotfiles.git"
REPO_PATH="$HOME/.dotfiles"

# Install Xcode Command Line Tools
print -P "%F{green}Checking Xcode Command Line Tools...%f"
if ! command -v git &>/dev/null; then
  print -P "%F{red}Git not found! Please install Xcode Command Line Tools before running this script.%f"
  exit 1
fi

# Install dotfiles
print -P "%F{green}Installing dotfiles...%f"
if [[ -d "$REPO_PATH" ]]; then
  print -P "%F{yellow}Dotfiles directory already exists. Pulling latest changes...%f"
  cd "$REPO_PATH"
  git pull origin main || { print -P "%F{red}Error updating dotfiles!%f"; exit 1 }
else
  if ! git clone "$REPO_URL" "$REPO_PATH"; then
      print -P "%F{red}Error downloading dotfiles!%f"
      exit 1
  fi
  cd "$REPO_PATH"
fi

# Install Homebrew
if ! command -v brew &>/dev/null; then
  print -P "%F{green}Installing Homebrew...%f"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Platform-aware brew path
  if [[ -d "/opt/homebrew/bin" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

# Install Homebrew Packages
print -P "%F{green}Installing Homebrew packages...%f"
brew bundle --file=./config/brew/Brewfile --cleanup
brew autoupdate start --upgrade --cleanup --quiet
brew analytics off
brew cleanup -s

# Create directories
print -P "%F{green}Creating directories...%f"
mkdir -p ~/scripts/
mkdir -p ~/projects/

# Copy script files
print -P "%F{green}Copying script files...%f"
cp -r ./scripts/*.zsh ~/scripts/

# Update config files
print -P "%F{green}Updating config files...%f"
cp -r ./config/zsh/. ~/
cp -r ./config/git/. ~/

# Update macOS Settings
print -P "%F{green}Updating macOS settings...%f"
zsh ./scripts/defaults.zsh

# Cleanup
rm -rf "$REPO_PATH"

print -P "%F{green}Completed!%f"
exit
