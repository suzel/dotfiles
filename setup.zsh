#!/usr/bin/env zsh

set -e

# Ask for the administrator password upfront
sudo -v

REPO_URL="https://github.com/suzel/dotfiles.git"
REPO_PATH="$HOME/.dotfiles"

# Install Xcode Command Line Tools
hash git &> /dev/null || xcode-select --install

# Install dotfiles
echo -e "\033[0;32mInstalling dotfiles...\033[0m"
git clone $REPO_URL $REPO_PATH
[ ! -d $REPO_PATH ] && { echo -e "\033[0;31mError downloading dotfiles! \033[0m"; exit 1 }
cd $REPO_PATH

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

# Create directories
echo -e "\033[0;32mCreating directories...\033[0m"
mkdir -p ~/Scripts/
mkdir -p ~/Projects/

# Copy script files
echo -e "\033[0;32mCopying script files...\033[0m"
cp -r ./scripts/*.zsh ~/Scripts/

# Update config files
echo -e "\033[0;32mUpdating config files...\033[0m"
cp -r ./config/zsh/. ~/
cp -r ./config/git/. ~/

# Update OSX Settings
echo -e "\033[0;32mUpdating OSX settings...\033[0m"
zsh ./scripts/defaults.zsh

echo -e "\033[0;32mCompleted!\033[0m"
( sleep 1; rm -rf $REPO_PATH ) & exit
