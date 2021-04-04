#!/usr/bin/env zsh

set -e

# Ask for the administrator password upfront
sudo -v

# Install Xcode Command Line Tools
hash git &> /dev/null || xcode-select --install

# Install dotfiles
echo -e "\033[0;32mInstalling dotfiles...\033[0m"
# git clone --bare https://github.com/suzel/dotfiles.git $HOME/.dotfiles
# [ ! -d $HOME/.dotfiles ] && { echo -e "\033[0;31mError downloading dotfiles! \033[0m"; exit 1 }

echo -e "\033[0;32mSuccess!\033[0m"
