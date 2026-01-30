#!/usr/bin/env zsh

# =============================================================================
# macOS User Defaults (UX & Productivity)
# =============================================================================
# Configures macOS preferences for a better user experience.
# Designed to be idempotent (safe to run multiple times).
# =============================================================================

# defaults write com.apple.dock persistent-apps -array-add '{ "tile-type" = "spacer-tile"; }'
# defaults write com.apple.dock persistent-apps -array-add '{ "tile-type" = "small-spacer-tile"; }'
# killall Dock

# Close System Settings to prevent it from overriding changes
osascript -e 'tell application "System Settings" to quit' 2>/dev/null

# =============================================================================
# Finder
# =============================================================================

# Show path bar at the bottom of Finder windows
defaults write com.apple.finder ShowPathbar -bool false

# Show status bar at the bottom of Finder windows
defaults write com.apple.finder ShowStatusBar -bool false

# Show hidden files
defaults write com.apple.finder AppleShowAllFiles -bool false

# Show file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# New Finder windows open home directory
defaults write com.apple.finder NewWindowTarget -string "PfHm"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"

# Search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Disable warning when changing file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Disable warning when emptying the Trash
defaults write com.apple.finder WarnOnEmptyTrash -bool false

# Use list view by default
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# =============================================================================
# Trackpad
# =============================================================================

# Enable tap to click for the current user
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad \
    Clicking -bool true
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain \
    com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Tracking speed (0.0 to 3.0, default: 1.0)
defaults write NSGlobalDomain com.apple.trackpad.scaling -float 0.875

# Enable three-finger drag
defaults write com.apple.AppleMultitouchTrackpad \
    TrackpadThreeFingerDrag -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad \
    TrackpadThreeFingerDrag -bool true

# =============================================================================
# Mouse
# =============================================================================

# Natural scroll direction
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool true

# Tracking speed (0.0 to 3.0, default: 1.0)
defaults write NSGlobalDomain com.apple.mouse.scaling -float 0.875

# Enable smart zoom (double-tap with one finger)
defaults write com.apple.driver.AppleBluetoothMultitouch.mouse \
    MouseOneFingerDoubleTapGesture -int 1
defaults write com.apple.AppleMultitouchMouse \
    MouseOneFingerDoubleTapGesture -int 1

# Swipe between pages with one finger (scroll left or right)
defaults write NSGlobalDomain \
    AppleEnableMouseSwipeNavigateWithScrolls -bool true

# Mission Control (double-tap with two fingers)
defaults write com.apple.driver.AppleBluetoothMultitouch.mouse \
    MouseTwoFingerDoubleTapGesture -int 1
defaults write com.apple.AppleMultitouchMouse \
    MouseTwoFingerDoubleTapGesture -int 1

# Swipe between full-screen apps (swipe left or right with two fingers)
defaults write com.apple.driver.AppleBluetoothMultitouch.mouse \
    MouseTwoFingerHorizSwipeGesture -int 2
defaults write com.apple.AppleMultitouchMouse \
    MouseTwoFingerHorizSwipeGesture -int 2

# =============================================================================
# Mission Control
# =============================================================================

# Don't automatically rearrange Spaces based on most recent use
defaults write com.apple.dock mru-spaces -bool false

# Don't group windows by application in Mission Control
defaults write com.apple.dock expose-group-apps -bool false

# =============================================================================
# Appearance
# =============================================================================

# Enable Dark Mode
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"

# Force 24-hour time format
sudo defaults write /Library/Preferences/.GlobalPreferences AppleICUForce24HourTime -bool true

# Light font smoothing (for non-retina external monitors)
defaults -currentHost write -g AppleFontSmoothing -int 1

# Auto-hide menu bar
defaults write NSGlobalDomain _HIHideMenuBar -bool true

# =============================================================================
# Dock
# =============================================================================

# Auto-hide the Dock
defaults write com.apple.dock autohide -bool true

# Speed up dock show/hide animation
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.4

# Set dock icon size
defaults write com.apple.dock tilesize -int 56

# Minimize windows into application icon
defaults write com.apple.dock minimize-to-application -bool true

# Minimize windows using genie effect
defaults write com.apple.dock mineffect -string "genie"

# Don't show recent applications in Dock
defaults write com.apple.dock show-recents -bool false

# Enable spring-loading for all Dock items
defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true

# Show indicator lights for open applications
defaults write com.apple.dock show-process-indicators -bool true

# Disable launch animation
defaults write com.apple.dock launchanim -bool false

# Make hidden app icons translucent
defaults write com.apple.dock showhidden -bool true

# =============================================================================
# Keyboard
# =============================================================================

# Disable press-and-hold for keys (enable key repeat)
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Fastest key repeat rate
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Disable auto-capitalization
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Disable smart quotes and dashes
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Disable period substitution (double space → period)
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# =============================================================================
# Screenshots
# =============================================================================

# Save screenshots to ~/Screenshots
mkdir -p "${HOME}/Screenshots"
defaults write com.apple.screencapture location -string "${HOME}/Screenshots"

# Save screenshots in PNG format
defaults write com.apple.screencapture type -string "png"

# Disable shadow in screenshots
defaults write com.apple.screencapture disable-shadow -bool true

# =============================================================================
# TextEdit
# =============================================================================

# Open as plain text by default (not rich text)
defaults write com.apple.TextEdit RichText -int 0

# Use UTF-8 encoding
defaults write com.apple.TextEdit PlainTextEncoding -int 4
defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4

# =============================================================================
# Activity Monitor
# =============================================================================

# Show all processes by default
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# Sort by CPU usage
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

# =============================================================================
# Animations
# =============================================================================

# Speed up window resize animation
defaults write NSGlobalDomain NSWindowResizeTime -float 0.1

# Speed up Mission Control animation
defaults write com.apple.dock expose-animation-duration -float 0.15

# =============================================================================
# Terminal.app
# =============================================================================

# Use UTF-8 encoding by default
defaults write com.apple.terminal StringEncodings -array 4

# Don't restore windows when re-opening Terminal
defaults write com.apple.terminal NSQuitAlwaysKeepsWindows -bool false

# Focus follows mouse
defaults write com.apple.terminal FocusFollowsMouse -bool true

# Hide line marks
defaults write com.apple.terminal ShowLineMarks -bool false

# Use Pro theme as default
defaults write com.apple.terminal "Default Window Settings" -string "Pro"
defaults write com.apple.terminal "Startup Window Settings" -string "Pro"

# Scroll-back buffer size
defaults write com.apple.terminal ScrollbackLines -int 100000

# Disable audible bell, use visual bell instead
defaults write com.apple.terminal Bell -bool false
defaults write com.apple.terminal VisualBell -bool true
defaults write com.apple.terminal VisualBellOnlyWhenMuted -bool false

# Close window without confirmation on clean exit
defaults write com.apple.terminal ExitOnCloseAction -int 1

# Don't render bold text as bright colors
defaults write com.apple.terminal BoldTextBrightColors -bool false

# Dim inactive split panes
defaults write com.apple.terminal DimInactiveSplitPanes -bool true

# Enable ANSI colors
defaults write com.apple.terminal ANSIColors -bool true

# Show active process in window title
defaults write com.apple.terminal ShowActiveProcessInTitle -bool true

# Show working directory in window title
defaults write com.apple.terminal ShowWorkingDirectoryInTitle -bool true

# Open new tabs in the same working directory
defaults write com.apple.terminal NewTabWorkingDirectoryBehavior -int 1

# Suppress "Last login" message
touch "${HOME}/.hushlogin"

# Set font and font size for Pro profile
osascript -e '
tell application "Terminal"
    set font name of settings set "Pro" to "JetBrainsMono Nerd Font"
    set font size of settings set "Pro" to 16
end tell'

# =============================================================================
# Power Management
# =============================================================================

# On charger: never sleep
sudo pmset -c displaysleep 0
sudo pmset -c sleep 0

# On battery: sleep after 15 minutes
sudo pmset -b displaysleep 15
sudo pmset -b sleep 15

# =============================================================================
# Login Window
# =============================================================================

# Show contact info on login screen (in case of lost/stolen device)
LOGIN_TEXT=$(echo 'Q29udGFjdDogc3VrcnUudXplbEBnbWFpbC5jb20=' \
    | base64 --decode)
sudo defaults write /Library/Preferences/com.apple.loginwindow \
    LoginwindowText -string "$LOGIN_TEXT"

# =============================================================================
# Restart affected services
# =============================================================================

killall Finder 2>/dev/null
killall Dock 2>/dev/null
killall SystemUIServer 2>/dev/null

echo "macOS user defaults applied successfully."
