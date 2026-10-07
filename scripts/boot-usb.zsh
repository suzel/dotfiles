#!/usr/bin/env zsh

# =============================================================================
# Bootable macOS USB Installer
# =============================================================================
# Downloads the latest full macOS installer and writes it to a USB disk.
# Asks for the disk first, so a wrong choice fails before the download.
# Usage: boot-usb.zsh
# Requires: an external USB disk of 32 GB or more (it gets erased)
# =============================================================================

set -euo pipefail

# Log Functions
info() { echo "\033[0;34mℹ️  $*\033[0m"; }
warn() { echo "\033[0;33m⚠️  $*\033[0m" >&2; }
error() { echo "\033[0;31m❌️ $*\033[0m" >&2; }
success() { echo "\033[0;32m✅ $*\033[0m"; }

# Error trap
TRAPZERR() {
  error "Error at ${funcfiletrace[1]}"
  exit 1
}

die() {
  error "$*"
  exit 1
}

# Sets $disk. Asked first: a wrong disk fails in seconds, not after ~15 GB
pick_disk() {
  info "External disks:"
  diskutil list external physical
  echo "Enter the USB disk identifier (e.g., disk4):"
  read -r disk
  [[ $disk == disk<-> ]] ||
    die "Expected a whole disk like disk4, got '$disk'."

  local plist
  plist=$(diskutil info -plist $disk 2>/dev/null) ||
    die "/dev/$disk does not exist."
  # Internal flag, not a boot-disk name: on Apple Silicon / is disk3, SSD disk0
  [[ $(plutil -extract Internal raw - <<<$plist) == false ]] ||
    die "/dev/$disk is an internal disk."

  warn "All data on /dev/$disk ($(plutil -extract MediaName raw - <<<$plist))" \
    "will be erased after the download!"
  echo "Continue? (y/N):"
  read -r confirm
  [[ $confirm == [yY] ]] || {
    warn "Aborted."
    exit 0
  }
}

download() {
  local version
  # awk reads to the end, so pipefail never sees a SIGPIPE from softwareupdate
  version=$(softwareupdate --list-full-installers | awk -F'Version: ' '
    NF > 1 && !v { split($2, a, ","); v = a[1] }
    END { print v }')
  [[ -n $version ]] || die "Could not find any macOS installers."
  info "Downloading macOS $version..."
  softwareupdate --fetch-full-installer --full-installer-version $version
}

create() {
  # newest installer
  local installer=(/Applications/Install\ macOS*.app(N/om[1]))
  (($#installer)) || die "macOS installer not found in /Applications."

  # createinstallmedia reformats it itself; this just gives it a volume
  info "Erasing /dev/$disk..."
  diskutil eraseDisk JHFS+ Installer GPT $disk
  local volume
  volume=$(diskutil info -plist ${disk}s2 | plutil -extract MountPoint raw -)

  info "Creating bootable installer from ${installer:t}..."
  sudo "$installer/Contents/Resources/createinstallmedia" \
    --volume "$volume" --nointeraction --downloadassets
}

main() {
  pick_disk
  download
  create
  success "Bootable macOS USB installer created on /dev/$disk."
}

main "$@"
