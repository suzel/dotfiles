#!/usr/bin/env zsh

set -e

# Ask for the administrator password upfront
sudo -v

REPO_URL="https://github.com/suzel/dotfiles.git"
REPO_PATH="$HOME/Projects/dotfiles"

# Install Xcode Command Line Tools
hash git &> /dev/null || xcode-select --install

# Install dotfiles
echo -e "\033[0;32mInstalling dotfiles...\033[0m"
git clone $REPO_URL $REPO_PATH
[ ! -d $REPO_PATH ] && { echo -e "\033[0;31mError downloading dotfiles! \033[0m"; exit 1 }

# Install Homebrew
if ! command -v brew &>/dev/null; then
  echo -e "\033[0;32mInstalling Homebrew...\033[0m"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Install Homebrew Packages
echo -e "\033[0;32mInstalling Homebrew packages...\033[0m"
brew bundle --file=./config/brew/Brewfile --cleanup
brew autoupdate start
brew analytics off
brew cleanup -s

echo -e "\033[0;32mCompleted!\033[0m"
( sleep 2; rm -rf $REPO_PATH ) & exit
