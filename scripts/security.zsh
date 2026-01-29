#!/usr/bin/env zsh

# =============================================================================
# macOS Security & System Defaults
# =============================================================================
# Configures macOS security hardening and system preferences.
# Designed to be idempotent (safe to run multiple times).
# Requires: sudo credentials (handled by parent setup.zsh)
# =============================================================================

# Close System Settings to prevent it from overriding changes
osascript -e 'tell application "System Settings" to quit' 2>/dev/null

# Keep sudo alive for the duration of the script
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# =============================================================================
# Firewall
# =============================================================================

sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsigned on
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsignedapp on

# =============================================================================
# Network Ports & Services
# =============================================================================

# Disable built-in Apache HTTP server
sudo launchctl unload -w /System/Library/LaunchDaemons/org.apache.httpd.plist 2>/dev/null

# Disable TFTP server
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.tftpd.plist 2>/dev/null

# Disable FTP server
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.ftpd.plist 2>/dev/null

# Disable NFS server
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.nfsd.plist 2>/dev/null

# Disable mDNS multicast advertisements (Bonjour)
sudo defaults write /Library/Preferences/com.apple.mDNSResponder.plist \
  NoMulticastAdvertisements -bool true

# =============================================================================
# DNS Security
# =============================================================================

# Set DNS to Quad9 (malware blocking + encrypted DNS)
sudo networksetup -setdnsservers Wi-Fi 9.9.9.9 149.112.112.112

# =============================================================================
# Captive Portal & Certificate Verification
# =============================================================================

# Disable captive portal (prevents auto-connecting to rogue hotspots)
sudo defaults write \
  /Library/Preferences/SystemConfiguration/com.apple.captive.control \
  Active -bool false

# Enable OCSP certificate revocation checking
defaults write com.apple.security.revocation \
  OCSPStyle -string RequireIfPresent
defaults write com.apple.security.revocation \
  CRLStyle -string RequireIfPresent

# =============================================================================
# FileVault (Disk Encryption)
# =============================================================================

if ! fdesetup status | grep -q "FileVault is On"; then
  echo "WARNING: FileVault is NOT enabled. Enable it via:"
  echo "  System Settings > Privacy & Security > FileVault"
  echo "  Or run: sudo fdesetup enable"
fi

# =============================================================================
# Gatekeeper
# =============================================================================

sudo spctl --master-enable

# =============================================================================
# Automatic Updates
# =============================================================================

defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
defaults write com.apple.SoftwareUpdate AutomaticDownload -bool true
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -bool true
defaults write com.apple.SoftwareUpdate \
  AutomaticallyInstallMacOSUpdates -bool true
defaults write com.apple.commerce AutoUpdate -bool true
softwareupdate --schedule on

# =============================================================================
# Screen Lock
# =============================================================================

defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0
defaults -currentHost write com.apple.screensaver idleTime -int 300
sudo pmset -a displaysleep 10

# =============================================================================
# Remote Access
# =============================================================================

sudo systemsetup -f -setremotelogin off
ard_path="/System/Library/CoreServices/RemoteManagement"
ard_path+="/ARDAgent.app/Contents/Resources/kickstart"
sudo "$ard_path" -deactivate -stop 2>/dev/null
sudo pmset -a womp 0

# =============================================================================
# Sharing Services
# =============================================================================

smbd_plist="/System/Library/LaunchDaemons/com.apple.smbd.plist"
sudo launchctl unload -w "$smbd_plist" 2>/dev/null
cupsctl --no-share-printers 2>/dev/null
defaults write com.apple.NetworkBrowser DisableAirDrop -bool true
nat_pref="/Library/Preferences/SystemConfiguration/com.apple.nat"
sudo defaults write "$nat_pref" NAT -dict Enabled -int 0 2>/dev/null

# =============================================================================
# Privacy & Analytics
# =============================================================================

defaults write com.apple.CrashReporter DialogType none
defaults write com.apple.CrashReporter AutoSubmit -bool false
defaults write com.apple.assistant.support \
  "Siri Data Sharing Opt-In Status" -int 2
defaults write com.apple.AdLib \
  allowApplePersonalizedAdvertising -bool false
defaults write com.apple.AdLib \
  allowIdentifierForAdvertising -bool false
defaults write com.apple.lookup.shared \
  LookupSuggestionsDisabled -bool true

# =============================================================================
# Login Window
# =============================================================================

login_pref="/Library/Preferences/com.apple.loginwindow"
sudo defaults write "$login_pref" GuestEnabled -bool false
sudo defaults write "$login_pref" SHOWFULLNAME -bool true
sudo defaults delete "$login_pref" autoLoginUser 2>/dev/null
sudo defaults write "$login_pref" RetriesUntilHint -int 0
sudo defaults write "$login_pref" AdminHostInfo HostName

# =============================================================================
# Terminal Security
# =============================================================================

defaults write com.apple.terminal SecureKeyboardEntry -bool true

# =============================================================================
# Finder Security
# =============================================================================

defaults write com.apple.desktopservices \
  DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices \
  DSDontWriteUSBStores -bool true

# =============================================================================
# Bluetooth
# =============================================================================

defaults -currentHost write com.apple.Bluetooth \
  PrefKeyServicesEnabled -bool false

# =============================================================================
# Siri
# =============================================================================

defaults write com.apple.assistant.support "Assistant Enabled" -bool false
defaults write com.apple.Siri StatusMenuVisible -bool false
defaults write com.apple.Siri UserHasDeclinedEnable -bool true


# =============================================================================
# Restart affected services
# =============================================================================

killall SystemUIServer 2>/dev/null
killall Finder 2>/dev/null

echo "macOS security defaults applied successfully."
