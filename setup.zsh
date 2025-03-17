#!/usr/bin/env zsh

set -e

# Ask for the administrator password upfront
sudo -v

# Install Xcode Command Line Tools
hash git &> /dev/null || xcode-select --install

# Install dotfiles
echo -e "\033[0;32mInstalling dotfiles...\033[0m"
git clone https://github.com/suzel/dotfiles.git $HOME/Projects/dotfiles
[ ! -d $HOME/Projects/dotfiles ] && { echo -e "\033[0;31mError downloading dotfiles! \033[0m"; exit 1 }

# Install Homebrew Modules
echo -e "\033[0;32mInstalling brew modules...\033[0m"
brew bundle --file=./Brewfile --cleanup
brew autoupdate start
brew analytics off
brew cleanup -s

echo -e "\033[0;32mCompleted!\033[0m"
