#!/usr/bin/env zsh

# =============================================================================
# Make Bootable macOS USB Installer
# =============================================================================

# 1. Find the latest full installer version
echo "Fetching latest macOS installer version..."
OS_VERSION=$(softwareupdate --list-full-installers \
    | grep -m1 "Version:" | sed 's/.*Version: \([^,]*\).*/\1/')
if [[ -z "$OS_VERSION" ]]; then
    echo "Error: Could not find any macOS installers."
    exit 1
fi
echo "Latest macOS version: $OS_VERSION"

# 2. Download the installer
echo "Downloading macOS $OS_VERSION..."
if ! softwareupdate --fetch-full-installer \
    --full-installer-version "$OS_VERSION"; then
    echo "Error: Failed to download macOS $OS_VERSION installer."
    exit 1
fi

# 3. Find the installer app in /Applications
INSTALLER_PATH=$(find /Applications -maxdepth 1 -type d \
    -name "Install macOS*.app" | tail -1)
if [[ ! -d "$INSTALLER_PATH" ]]; then
    echo "Error: macOS installer not found in /Applications."
    exit 1
fi
echo "Installer found at: $INSTALLER_PATH"

# 4. Ask user for USB disk
echo ""
echo "Available disks:"
diskutil list
echo ""
echo "Enter the USB disk identifier (e.g., disk2):"
read -r USB_DISK
if [[ -z "$USB_DISK" ]]; then
    echo "No disk entered. Exiting."
    exit 1
fi

# 4.1 Validate disk exists
if ! diskutil info "/dev/$USB_DISK" &>/dev/null; then
    echo "Error: /dev/$USB_DISK does not exist."
    exit 1
fi

# 4.2 Prevent erasing the boot disk
BOOT_DISK=$(diskutil info / | awk '/Part of Whole:/ {print $NF}')
if [[ "$USB_DISK" == "$BOOT_DISK" ]]; then
    echo "Error: Cannot erase the boot disk ($BOOT_DISK)."
    exit 1
fi

# 4.3 Confirm before erasing
echo ""
echo "WARNING: All data on /dev/$USB_DISK will be erased!"
echo "Continue? (y/N):"
read -r CONFIRM
if [[ "$CONFIRM" != [yY] ]]; then
    echo "Aborted."
    exit 0
fi

# 5. Erase the USB drive
echo "Erasing /dev/$USB_DISK..."
if ! diskutil eraseDisk APFS "Installer" "/dev/$USB_DISK"; then
    echo "Error: Failed to erase /dev/$USB_DISK."
    exit 1
fi

# 6. Create the bootable installer
echo "Creating bootable installer..."
sudo "$INSTALLER_PATH/Contents/Resources/createinstallmedia" \
    --volume /Volumes/Installer \
    --nointeraction \
    --downloadassets

echo "Bootable macOS USB installer created successfully!"
