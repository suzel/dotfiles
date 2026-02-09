#!/usr/bin/env zsh

# =============================================================================
# macOS Security & System Defaults
# =============================================================================
# Configures macOS security hardening and system preferences.
# Designed to be idempotent (safe to run multiple times).
# Requires: Run with sudo from parent setup.zsh
# =============================================================================

# Log Functions
info() { echo "\033[0;34mℹ️  $*\033[0m"; }
error() { echo "\033[0;31m❌ $*\033[0m"; }
success() { echo "\033[0;32m✅ $*\033[0m"; }

# Close System Settings to prevent it from overriding changes
info "Closing System Settings..."
osascript -e 'tell application "System Settings" to quit' 2>/dev/null

# =============================================================================
# Firewall
# =============================================================================

info "Configuring firewall..."
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on || error "Failed to enable firewall"
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on || error "Failed to enable stealth mode"
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsigned on || error "Failed to allow signed apps"
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsignedapp on || error "Failed to allow signed app exceptions"

# =============================================================================
# Network Ports & Services
# =============================================================================

info "Disabling network services..."

# Disable built-in Apache HTTP server
httpd_plist="/System/Library/LaunchDaemons/org.apache.httpd.plist"
sudo launchctl bootout system "$httpd_plist" 2>/dev/null
sudo launchctl disable system/org.apache.httpd 2>/dev/null

# Disable TFTP server
tftpd_plist="/System/Library/LaunchDaemons/com.apple.tftpd.plist"
sudo launchctl bootout system "$tftpd_plist" 2>/dev/null
sudo launchctl disable system/com.apple.tftpd 2>/dev/null

# Disable FTP server
ftpd_plist="/System/Library/LaunchDaemons/com.apple.ftpd.plist"
sudo launchctl bootout system "$ftpd_plist" 2>/dev/null
sudo launchctl disable system/com.apple.ftpd 2>/dev/null

# Disable NFS server
nfsd_plist="/System/Library/LaunchDaemons/com.apple.nfsd.plist"
sudo launchctl bootout system "$nfsd_plist" 2>/dev/null
sudo launchctl disable system/com.apple.nfsd 2>/dev/null

# Disable mDNS multicast advertisements (Bonjour)
sudo defaults write /Library/Preferences/com.apple.mDNSResponder.plist \
  NoMulticastAdvertisements -bool true

# =============================================================================
# DNS Security
# =============================================================================

info "Setting DNS to Quad9..."
# Set DNS to Quad9 (malware blocking + encrypted DNS) on all active interfaces
while IFS= read -r iface; do
  sudo networksetup -setdnsservers "$iface" 9.9.9.9 149.112.112.112
done < <(networksetup -listallnetworkservices | tail -n +2)

# =============================================================================
# Captive Portal & Certificate Verification
# =============================================================================

info "Configuring captive portal & certificate verification..."
# Disable captive portal (prevents auto-connecting to rogue hotspots)
sudo defaults write \
  /Library/Preferences/SystemConfiguration/com.apple.captive.control \
  Active -bool false

# Enable OCSP certificate revocation checking (system-wide)
sudo defaults write /Library/Preferences/com.apple.security.revocation \
  OCSPStyle -string RequireIfPresent
sudo defaults write /Library/Preferences/com.apple.security.revocation \
  CRLStyle -string RequireIfPresent

# =============================================================================
# FileVault (Disk Encryption)
# =============================================================================

info "Enabling FileVault..."
sudo fdesetup enable 2>/dev/null

# =============================================================================
# Gatekeeper
# =============================================================================

info "Enabling Gatekeeper..."
sudo spctl --global-enable || error "Failed to enable Gatekeeper"

# =============================================================================
# Automatic Updates
# =============================================================================

info "Enabling automatic updates..."
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

info "Configuring screen lock..."
# Require password immediately after sleep or screen saver
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# =============================================================================
# Remote Access
# =============================================================================

info "Disabling remote access..."
# Note: Requires Full Disk Access for Terminal (macOS Catalina+)
sudo systemsetup -f -setremotelogin off || error "Failed to disable remote login"
ard_path="/System/Library/CoreServices/RemoteManagement"
ard_path+="/ARDAgent.app/Contents/Resources/kickstart"
sudo "$ard_path" -deactivate -stop 2>/dev/null
sudo pmset -a womp 0 || error "Failed to disable Wake-on-LAN"

# =============================================================================
# Sharing Services
# =============================================================================

info "Disabling sharing services..."
smbd_plist="/System/Library/LaunchDaemons/com.apple.smbd.plist"
sudo launchctl bootout system "$smbd_plist" 2>/dev/null
sudo launchctl disable system/com.apple.smbd 2>/dev/null
cupsctl --no-share-printers 2>/dev/null
# Disable AirDrop (legacy key + modern method)
defaults write com.apple.NetworkBrowser DisableAirDrop -bool true
defaults write com.apple.sharingd DiscoverableMode -string "Off" 2>/dev/null
nat_pref="/Library/Preferences/SystemConfiguration/com.apple.nat"
sudo defaults write "$nat_pref" NAT -dict Enabled -int 0 2>/dev/null

# =============================================================================
# Privacy & Analytics
# =============================================================================

info "Configuring privacy & analytics..."
defaults write com.apple.CrashReporter DialogType none
defaults write com.apple.CrashReporter AutoSubmit -bool false
defaults write com.apple.AdLib \
  allowApplePersonalizedAdvertising -bool false
defaults write com.apple.AdLib \
  allowIdentifierForAdvertising -bool false
defaults write com.apple.lookup.shared \
  LookupSuggestionsDisabled -bool true

# =============================================================================
# Login Window
# =============================================================================

info "Configuring login window..."
login_pref="/Library/Preferences/com.apple.loginwindow"
sudo defaults write "$login_pref" GuestEnabled -bool false
sudo defaults delete "$login_pref" autoLoginUser 2>/dev/null
sudo defaults write "$login_pref" RetriesUntilHint -int 0
sudo defaults write "$login_pref" AdminHostInfo HostName

# =============================================================================
# Terminal Security
# =============================================================================

info "Enabling secure keyboard entry..."
defaults write com.apple.terminal SecureKeyboardEntry -bool true

# =============================================================================
# Finder Security
# =============================================================================

info "Configuring Finder security..."
defaults write com.apple.desktopservices \
  DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices \
  DSDontWriteUSBStores -bool true

# =============================================================================
# Bluetooth
# =============================================================================

info "Disabling Bluetooth sharing..."
defaults -currentHost write com.apple.Bluetooth \
  PrefKeyServicesEnabled -bool false

# =============================================================================
# Siri
# =============================================================================

info "Disabling Siri..."
defaults write com.apple.assistant.support "Assistant Enabled" -bool false
defaults write com.apple.assistant.support \
  "Siri Data Sharing Opt-In Status" -int 2
defaults write com.apple.Siri StatusMenuVisible -bool false
defaults write com.apple.Siri UserHasDeclinedEnable -bool true


# =============================================================================
# Restart affected services
# =============================================================================

info "Restarting affected services..."
killall SystemUIServer 2>/dev/null
killall Finder 2>/dev/null

success "macOS security defaults applied successfully."
