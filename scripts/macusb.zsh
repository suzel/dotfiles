#!/usr/bin/env zsh

# Make Bootable USB

# Download the latest macOS installer
OS_VERSION=$(softwareupdate --list-full-installers | awk '/\*/ {print $2}' | tail -1)
softwareupdate --fetch-full-installer --full-installer-version "$OS_VERSION"

# Make sure the installer app exists
INSTALLER_PATH="/Applications/Install macOS.app"
if [ ! -d "$INSTALLER_PATH" ]; then
    echo "Error: macOS installer not found in Applications folder."
    exit 1
fi

# Erase the USB drive and create a bootable installer
diskutil eraseDisk APFS "Installer" /dev/disk2
sudo "$INSTALLER_PATH/Contents/Resources/createinstallmedia" \
    --volume /Volumes/Installer \
    --nointeraction \
    --downloadassets
