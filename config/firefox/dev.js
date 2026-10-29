// =============================================================================
// Developer Edition overrides
// =============================================================================
// ./setup.zsh config appends this file to a copy of user.js in the Developer
// Edition profile. Prefs set later win, so these replace the user.js values.
// Re-run ./setup.zsh config after editing either file.
// =============================================================================

// Real screen size, timer precision and fonts when testing own sites
user_pref("privacy.resistFingerprinting", false);
// Plain HTTP to local addresses (OrbStack .orb.local, LAN devices)
user_pref("dom.security.https_only_mode.upgrade_local", false);
