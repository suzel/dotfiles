#!/usr/bin/env zsh

# Create Bootable Installer

# Download macOS installers
OS_VERSION=$(sw_vers -productVersion)
softwareupdate -d --fetch-full-installer --full-installer-version $OS_VERSION

# Make a bootable USB
diskutil eraseDisk JHFS+ Installer /dev/disk2
sudo /Applications/Install\ macOS\ Catalina.app/Contents/Resources/createinstallmedia \
    --volume /Volumes/Installer \
    --nointeraction \
    --downloadassets
