#!/usr/bin/env zsh

# -------------------------------
# Make Bootable macOS USB Installer
# -------------------------------

# 1. Find the latest full installer version
echo "Fetching latest macOS installer version..."
OS_VERSION=$(softwareupdate --list-full-installers | awk '/\*/ {print $2}' | tail -1)
if [[ -z "$OS_VERSION" ]]; then
    echo "Error: Could not find any macOS installers."
    exit 1
fi
echo "Latest macOS version: $OS_VERSION"

# 2. Download the installer
echo "Downloading macOS $OS_VERSION..."
softwareupdate --fetch-full-installer --full-installer-version "$OS_VERSION"

# 3. Find the installer app in /Applications
INSTALLER_PATH=$(find /Applications -maxdepth 1 -type d -name "Install macOS*.app" | tail -1)
if [[ ! -d "$INSTALLER_PATH" ]]; then
    echo "Error: macOS installer not found in Applications folder."
    exit 1
fi
echo "Installer found at: $INSTALLER_PATH"

# 4. Ask user for USB disk
echo "Please list your disks with 'diskutil list' and enter the USB disk identifier (e.g., disk2):"
read USB_DISK
if [[ -z "$USB_DISK" ]]; then
    echo "No disk entered. Exiting."
    exit 1
fi

# 5. Erase the USB drive
echo "Erasing /dev/$USB_DISK..."
diskutil eraseDisk APFS "Installer" /dev/$USB_DISK

# 6. Create the bootable installer
echo "Creating bootable installer..."
sudo "$INSTALLER_PATH/Contents/Resources/createinstallmedia" \
    --volume /Volumes/Installer \
    --nointeraction \
    --downloadassets

echo "Bootable macOS USB installer created successfully!"
