#!/usr/bin/env zsh

# =============================================================================
# macOS Security & System Defaults
# =============================================================================
# Configures macOS security hardening and system preferences.
# Designed to be idempotent (safe to run multiple times).
# Usage: security.zsh (not run by setup.zsh)
# Requires: admin rights. Calls sudo itself; run as your user, not with sudo.
# =============================================================================

set -uo pipefail

failed=0
readonly FW=/usr/libexec/ApplicationFirewall/socketfilterfw
readonly DAEMONS=/System/Library/LaunchDaemons
readonly ARD_DIR=/System/Library/CoreServices/RemoteManagement
readonly KICKSTART="$ARD_DIR/ARDAgent.app/Contents/Resources/kickstart"
readonly SU_PREF=/Library/Preferences/com.apple.SoftwareUpdate
readonly NAT_PREF=/Library/Preferences/SystemConfiguration/com.apple.nat
readonly CRASH_DIR="/Library/Application Support/CrashReporter"
readonly DIAG_PREF="$CRASH_DIR/DiagnosticMessagesHistory.plist"
readonly LOGIN_PREF=/Library/Preferences/com.apple.loginwindow
readonly HANDOFF_PREF=com.apple.coreservices.useractivityd
readonly HOST_NAME=MacBook

# Log Functions
info() { echo "\033[0;34mℹ️  $*\033[0m"; }
warn() { echo "\033[0;33m⚠️  $*\033[0m" >&2; }
error() { echo "\033[0;31m❌️ $*\033[0m" >&2 && failed=1; }
success() { echo "\033[0;32m✅ $*\033[0m"; }

# Error trap: report and continue
TRAPZERR() { error "Error at ${funcfiletrace[1]}"; }

((EUID == 0)) && error "Run as your user, not with sudo." && exit 1

# Close System Settings to prevent it from overriding changes
info "Closing System Settings..."
osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true

# =============================================================================
# Firewall
# =============================================================================

info "Configuring firewall..."

# Enable the firewall
sudo $FW --setglobalstate on || error "Failed to enable firewall"

# Enable stealth mode (don't answer pings or port scans)
sudo $FW --setstealthmode on || error "Failed to enable stealth mode"

# Allow built-in software to accept incoming connections
sudo $FW --setallowsigned on || error "Failed to allow signed apps"

# Ask before downloaded signed apps accept incoming connections
sudo $FW --setallowsignedapp off ||
  error "Failed to disable signed app exceptions"

# =============================================================================
# Network Ports & Services
# =============================================================================

info "Disabling network services..."

# Disable the built-in Apache HTTP server
sudo launchctl bootout system $DAEMONS/org.apache.httpd.plist 2>/dev/null ||
  true
sudo launchctl disable system/org.apache.httpd 2>/dev/null || true

# Disable the NFS server
sudo launchctl bootout system $DAEMONS/com.apple.nfsd.plist 2>/dev/null || true
sudo launchctl disable system/com.apple.nfsd 2>/dev/null || true

# Disable NetBIOS (announces the host name on UDP 137/138)
sudo launchctl bootout system/com.apple.netbiosd 2>/dev/null || true
sudo launchctl disable system/com.apple.netbiosd ||
  error "Failed to disable NetBIOS"

# Disable Bonjour multicast advertisements
sudo defaults write /Library/Preferences/com.apple.mDNSResponder.plist \
  NoMulticastAdvertisements -bool true

# =============================================================================
# Host Name
# =============================================================================

info "Setting a generic host name..."

# Use a generic host name (the default contains your user name)
for key in ComputerName LocalHostName HostName; do
  sudo scutil --set $key $HOST_NAME
done

# =============================================================================
# Captive Portal
# =============================================================================

info "Disabling captive portal assistant..."

# Don't auto-open hotspot login pages
sudo defaults write \
  /Library/Preferences/SystemConfiguration/com.apple.captive.control \
  Active -bool false

# =============================================================================
# FileVault (Disk Encryption)
# =============================================================================

info "Enabling FileVault..."

# Enable FileVault disk encryption
fdesetup isactive >/dev/null || sudo fdesetup enable

# =============================================================================
# Gatekeeper
# =============================================================================

info "Enabling Gatekeeper..."

# Only allow apps from the App Store and identified developers
sudo spctl --global-enable || error "Failed to enable Gatekeeper"

# =============================================================================
# Automatic Updates
# =============================================================================

info "Enabling automatic updates..."

# Check for updates automatically (softwareupdated reads the system domain)
sudo defaults write $SU_PREF AutomaticCheckEnabled -bool true

# Download new updates in the background
sudo defaults write $SU_PREF AutomaticDownload -bool true

# Install security responses and system files
sudo defaults write $SU_PREF CriticalUpdateInstall -bool true

# Install XProtect and malware definition updates
sudo defaults write $SU_PREF ConfigDataInstall -bool true

# Install macOS updates
sudo defaults write $SU_PREF AutomaticallyInstallMacOSUpdates -bool true

# Install App Store app updates
sudo defaults write /Library/Preferences/com.apple.commerce \
  AutoUpdate -bool true

# Turn on scheduled update checks
softwareupdate --schedule on

# =============================================================================
# Screen Lock
# =============================================================================

info "Configuring screen lock..."

# Require password immediately after sleep or screen saver
# (com.apple.screensaver askForPassword is ignored since macOS 10.13.4)
sysadminctl -screenLock status 2>&1 | grep -q immediate ||
  sudo sysadminctl -screenLock immediate -password - ||
  error "Failed to set screen lock"

# Start the screen saver after 5 minutes of inactivity
defaults -currentHost write com.apple.screensaver idleTime -int 300

# =============================================================================
# Remote Access
# =============================================================================

info "Disabling remote access..."

# Disable Remote Login (SSH), Screen Sharing and Remote Apple Events
for svc in com.openssh.sshd com.apple.screensharing com.apple.AEServer; do
  sudo launchctl bootout system/$svc 2>/dev/null || true
  sudo launchctl disable system/$svc || error "Failed to disable $svc"
done

# Disable Remote Management (Apple Remote Desktop)
sudo "$KICKSTART" -deactivate -stop 2>/dev/null || true

# Disable Wake for network access
sudo pmset -a womp 0 || error "Failed to disable Wake-on-LAN"

# =============================================================================
# Sharing Services
# =============================================================================

info "Disabling sharing services..."

# Disable File Sharing (SMB)
sudo launchctl bootout system $DAEMONS/com.apple.smbd.plist 2>/dev/null || true
sudo launchctl disable system/com.apple.smbd 2>/dev/null || true

# Disable Printer Sharing
cupsctl --no-share-printers 2>/dev/null || true

# Disable AirDrop (legacy key + modern method)
defaults write com.apple.NetworkBrowser DisableAirDrop -bool true
defaults write com.apple.sharingd DiscoverableMode -string "Off" 2>/dev/null ||
  true

# Disable Internet Sharing
sudo defaults write $NAT_PREF NAT -dict Enabled -int 0 2>/dev/null || true

# Disable Content Caching
[[ $(AssetCacheManagerUtil isActivated 2>&1) == *deactivated* ]] ||
  sudo AssetCacheManagerUtil deactivate ||
  error "Failed to disable content caching"

# Disable AirPlay Receiver (listens on *:5000 and *:7000)
defaults -currentHost write com.apple.controlcenter \
  AirplayReceiverEnabled -bool false

# Disable Handoff
defaults -currentHost write $HANDOFF_PREF ActivityAdvertisingAllowed -bool false
defaults -currentHost write $HANDOFF_PREF ActivityReceivingAllowed -bool false

# =============================================================================
# Privacy & Analytics
# =============================================================================

info "Configuring privacy & analytics..."

# Don't show the crash reporter dialog
defaults write com.apple.CrashReporter DialogType none

# Don't share Mac analytics with Apple or app developers
sudo defaults write "$DIAG_PREF" AutoSubmit -bool false
sudo defaults write "$DIAG_PREF" ThirdPartyDataSubmit -bool false

# Disable personalized ads
defaults write com.apple.AdLib \
  allowApplePersonalizedAdvertising -bool false

# Disable suggestions in Look Up
defaults write com.apple.lookup.shared \
  LookupSuggestionsDisabled -bool true

# =============================================================================
# Login Window
# =============================================================================

info "Configuring login window..."

# Disable the guest account
sudo defaults write $LOGIN_PREF GuestEnabled -bool false

# Disable automatic login
sudo defaults delete $LOGIN_PREF autoLoginUser 2>/dev/null || true

# Never show the password hint
sudo defaults write $LOGIN_PREF RetriesUntilHint -int 0

# Don't show host name, IP and OS build when the clock is clicked
sudo defaults delete $LOGIN_PREF AdminHostInfo 2>/dev/null || true

# =============================================================================
# Terminal Security
# =============================================================================

info "Enabling secure keyboard entry..."

# Enable Secure Keyboard Entry in Terminal
defaults write com.apple.terminal SecureKeyboardEntry -bool true

# =============================================================================
# Finder Security
# =============================================================================

info "Configuring Finder security..."

# Don't create .DS_Store files on network volumes
defaults write com.apple.desktopservices \
  DSDontWriteNetworkStores -bool true

# =============================================================================
# Home Folder
# =============================================================================

info "Making the home folder private..."

# Make the home folder private (default 750 lets the staff group list it)
chmod 700 "$HOME"

# =============================================================================
# Bluetooth
# =============================================================================

info "Disabling Bluetooth sharing..."

# Disable Bluetooth sharing
defaults -currentHost write com.apple.Bluetooth \
  PrefKeyServicesEnabled -bool false

# =============================================================================
# Siri
# =============================================================================

info "Disabling Siri..."

# Disable Siri
defaults write com.apple.assistant.support "Assistant Enabled" -bool false

# Don't share audio recordings with Apple
defaults write com.apple.assistant.support \
  "Siri Data Sharing Opt-In Status" -int 2

# Hide Siri in the menu bar
defaults write com.apple.Siri StatusMenuVisible -bool false

# =============================================================================
# Restart affected services
# =============================================================================

info "Restarting affected services..."
killall SystemUIServer 2>/dev/null || true
killall Finder 2>/dev/null || true
killall ControlCenter 2>/dev/null || true

# =============================================================================
# Manual Steps
# =============================================================================

info "Checking steps the script can't do..."
[[ $(systemextensionsctl list 2>/dev/null) == *lulu*'activated enabled'* ]] ||
  warn "LuLu is not filtering: allow it in Login Items & Extensions"
[[ $(tmutil destinationinfo 2>&1) != *"No destinations"* ]] ||
  warn "No Time Machine destination: add an encrypted backup disk"

info "Restart the Mac to apply all network and sharing changes."
((failed)) && warn "Some security settings failed, see errors above." ||
  success "macOS security defaults applied successfully."
