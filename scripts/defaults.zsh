#!/usr/bin/env zsh

# Update OS Settings

# Enable automatic software updates on macOS
softwareupdate --schedule on

# Enable macOS firewall
/usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on

# Enable Dark Mode on macOS using defaults
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"

# Enable auto-hide for the macOS menu bar
defaults write NSGlobalDomain _HIHideMenuBar -bool true

# Enable auto-hide for the macOS Dock (toolbar)
defaults write com.apple.dock autohide -bool true

killall SystemUIServer
killall Dock
