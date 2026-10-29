// =============================================================================
// Firefox user.js
// =============================================================================
// Hardened Firefox with LibreWolf's security choices (librewolf.cfg), plus a
// few arkenfox and Betterfox extras. Firefox applies these prefs on every
// start, so they override Settings and about:config: change them here, then
// restart Firefox.
//
// Related files in this folder:
//   policies.json  Policies: extensions, search engine, AI, telemetry
//   dev.js         Developer Edition overrides, appended to a copy of this
//                  file by ./setup.zsh config (re-run it after editing)
//   chrome/        Theme for the browser UI (userChrome.css) and for pages
//                  (userContent.css)
//
// Sections: UI, Performance, Tracking protection, Fingerprinting,
// Permissions, HTTPS and certificates, Safe Browsing, DNS and connections,
// Storage and shutdown, Passwords and forms, Downloads, Search and address
// bar, AI, Telemetry, Ads and onboarding, DRM, extensions and devtools
// =============================================================================

// =============================================================================
// UI
// =============================================================================

// Reduced motion, which also turns off tab open and close animations
user_pref("ui.prefersReducedMotion", 1);
// Load chrome/userChrome.css and chrome/userContent.css
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
// Let macOS vibrancy show through the window (used by userChrome.css)
user_pref("widget.macos.titlebar-blend-mode.behind-window", true);
// Keep the Nova redesign off; userChrome.css targets the classic layout
user_pref("browser.nova.enabled", false);
// Compact density (1) for tabs, sidebar and toolbar, like VS Code
user_pref("browser.uidensity", 1);
// No fade to black when a video enters or leaves fullscreen
user_pref("full-screen-api.transition-duration.enter", "0 0");
user_pref("full-screen-api.transition-duration.leave", "0 0");
// Vertical tabs, no bookmarks toolbar
user_pref("sidebar.verticalTabs", true);
user_pref("browser.toolbars.bookmarks.visibility", "never");
// Dark background for pages that set no colors (matches userContent.css)
user_pref("browser.display.background_color.dark", "#1e2127");
// No smooth scrolling, spellcheck (0), quit warning or translation popups
user_pref("general.smoothScroll", false);
user_pref("layout.spellcheckDefault", 0);
user_pref("browser.warnOnQuitShortcut", false);
user_pref("browser.translations.automaticallyPopup", false);
// Blank page on start (0) and in new tabs
user_pref("browser.startup.page", 0);
user_pref("browser.startup.homepage", "chrome://browser/content/blanktab.html");
user_pref("browser.newtabpage.enabled", false);

// =============================================================================
// Performance (Betterfox)
// =============================================================================

// Bigger font, canvas, media and network buffers
user_pref("gfx.content.skia-font-cache-size", 20);
user_pref("gfx.canvas.accelerated.cache-size", 512);
user_pref("media.cache_readahead_limit", 3600);
user_pref("media.cache_resume_threshold", 1800);
user_pref("network.buffer.cache.size", 65535);
user_pref("network.buffer.cache.count", 48);
// Decode images in bigger chunks, keep DNS answers for an hour
user_pref("image.mem.decode_bytes_at_a_time", 32768);
user_pref("network.dnsCacheExpiration", 3600);
// More parallel connections, no delay before starting requests
user_pref("network.http.max-connections", 1800);
user_pref("network.http.max-persistent-connections-per-server", 10);
user_pref("network.http.max-urgent-start-excessive-connections-per-host", 5);
user_pref("network.http.request.max-start-delay", 5);
// Fewer reflows while a page loads
user_pref("content.notify.interval", 100000);
// Save the session every minute instead of every 15 seconds
user_pref("browser.sessionstore.interval", 60000);
// No AV1 video: the M2 can't decode it in hardware, so YouTube and others
// send VP9, which the Mac decodes on the GPU instead of the CPU
user_pref("media.av1.enabled", false);

// =============================================================================
// Tracking protection
// =============================================================================

// Strict mode, without the exceptions Firefox adds to unbreak sites
user_pref("browser.contentblocking.category", "strict");
user_pref("privacy.trackingprotection.allow_list.baseline.enabled", false);
user_pref("privacy.trackingprotection.allow_list.convenience.enabled", false);
// Third-party cookies only when partitioned (CHIPS): set as defaults in
// policies.json, since strict mode clears these prefs when set here
// Strip tracking parameters from URLs: Brave's list, via LibreWolf. A pref
// value can't span lines, so the list stays on one long line
user_pref("privacy.query_stripping.strip_list", "__hsfp __hssc __hstc __s _bhlid _branch_match_id _branch_referrer _gl _hsenc _openstat at_recipient_id at_recipient_list bbeml bsft_clkid bsft_uid dclid et_rid fb_action_ids fb_comment_id gbraid fbclid gclid guce_referrer guce_referrer_sig hsCtaTracking irclickid mc_eid ml_subscriber ml_subscriber_hash msclkid mtm_cid oft_c oft_ck oft_d oft_id oft_ids oft_k oft_lk oft_sk oly_anon_id oly_enc_id pk_cid rb_clickid s_cid sc_customer sc_eh sc_uid sfmc_activityid sfmc_id sms_click sms_source sms_uph srsltid ss_email_id syclid ttclid twclid unicorn_click_id vero_conv vero_id vgo_ee wbraid wickedid yclid ymclid ysclid");
user_pref("privacy.query_stripping.allow_list", "urldefense.com");
// Global Privacy Control, no ad attribution, no beacons
user_pref("privacy.globalprivacycontrol.enabled", true);
user_pref("privacy.globalprivacycontrol.pbmode.enabled", true);
user_pref("dom.private-attribution.submission.enabled", false);
user_pref("beacon.enabled", false);
// Cross-origin referers send only scheme, host and port (2); sites can't
// loosen that for links to other sites
user_pref("network.http.referer.XOriginTrimmingPolicy", 2);
user_pref("network.http.referer.disallowCrossSiteRelaxingDefault.top_navigation", true);

// =============================================================================
// Fingerprinting
// =============================================================================

// Resist fingerprinting (RFP): spoofed screen size, coarse timers, fonts you
// installed hidden from sites, and sites always get the light color scheme
user_pref("privacy.resistFingerprinting", true);
// Mozilla's add-ons site can't see or manage installed add-ons
user_pref("privacy.resistFingerprinting.block_mozAddonManager", true);
// Larger rounded size for new windows under RFP
user_pref("privacy.window.maxInnerWidth", 1600);
user_pref("privacy.window.maxInnerHeight", 900);
// No WebGPU, in pages or in the PDF viewer
user_pref("dom.webgpu.enabled", false);
user_pref("pdfjs.enableWebGPU", false);
// WebRTC only goes through the proxy when one is set
user_pref("media.peerconnection.ice.proxy_only_if_behind_proxy", true);

// =============================================================================
// Permissions
// =============================================================================

// Location: beacondb instead of Google, no macOS location services
user_pref("geo.provider.network.url", "https://api.beacondb.net/v1/geolocate");
user_pref("geo.provider.use_corelocation", false);
// Block notification requests (2), no background connection to Mozilla's
// push server
user_pref("permissions.default.desktop-notification", 2);
user_pref("dom.push.enabled", false);
// No permissions pre-granted by Mozilla, no Web Serial
user_pref("permissions.manager.defaultsUrl", "");
user_pref("dom.webserial.enabled", false);
// Local network access asks also before a public site navigates to a local
// address, and before a local address reaches localhost
user_pref("network.lna.allow_top_level_navigation", false);
user_pref("network.lna.local-network-to-localhost.skip-checks", false);
// No web services (Gmail and similar) added as mailto and other link handlers
user_pref("gecko.handlerService.defaultHandlersVersion", 999);
// Sites can't move or resize windows; new windows and popups open as tabs (3)
user_pref("dom.disable_window_move_resize", true);
user_pref("browser.link.open_newwindow", 3);
user_pref("browser.link.open_newwindow.restriction", 0);
// Block audible and inaudible autoplay (5)
user_pref("media.autoplay.default", 5);
// Install and permission buttons only work after 1s (clickjacking)
user_pref("security.dialog_enable_delay", 1000);

// =============================================================================
// HTTPS and certificates
// =============================================================================

// HTTPS-Only Mode, local addresses too, without the HTTP background probe;
// error pages suggest the www. address
user_pref("dom.security.https_only_mode", true);
user_pref("dom.security.https_only_mode.upgrade_local", true);
user_pref("dom.security.https_only_mode_send_http_background_request", false);
user_pref("dom.security.https_only_mode_error_page_user_suggestions", true);
// Strict certificate pinning (2), only Firefox's own root certificates (none
// added to macOS, not even after a MITM error)
user_pref("security.cert_pinning.enforcement_level", 2);
user_pref("security.enterprise_roots.enabled", false);
user_pref("security.certerrors.mitm.auto_enable_enterprise_roots", false);
// Revocation checks with CRLite (2 = enforce) instead of OCSP (0 = off)
user_pref("security.pki.crlite_mode", 2);
user_pref("security.remote_settings.crlite_filters.enabled", true);
user_pref("security.OCSP.enabled", 0);
user_pref("security.OCSP.require", false);
// No EU qualified website certificates (QWACs)
user_pref("security.qwacs.enabled", false);
// Technical details on certificate error pages
user_pref("browser.xul.error_pages.expert_bad_cert", true);
// No unsafe renegotiation, 0-RTT replay, weak cipher or saved TLS sessions
user_pref("security.ssl.require_safe_negotiation", true);
user_pref("security.ssl.treat_unsafe_negotiation_as_broken", true);
user_pref("security.tls.enable_0rtt_data", false);
user_pref("network.http.http3.enable_0rtt", false);
user_pref("security.ssl3.ecdhe_ecdsa_aes_256_sha", false);
user_pref("network.ssl_tokens_cache_persistence", false);
// Post-quantum key exchange (ML-KEM-1024) and signatures (ML-DSA)
user_pref("security.tls.enable_mlkem1024", true);
user_pref("security.tls.enable_mldsa", true);
// Warn about password fields on HTTP pages, local IPs included
user_pref("security.insecure_field_warning.ignore_local_ip_address", false);
// Ask before resending form data to a redirected address
user_pref("network.http.prompt-temp-redirect", true);
// Cross-origin images and scripts can't open login prompts (1)
user_pref("network.auth.subresource-http-auth-allow", 1);
// WebAuthn asks before sharing a security key's attestation
user_pref("security.webauthn.always_allow_direct_attestation", false);
// No CSP violation reports sent to sites
user_pref("security.csp.reporting.enabled", false);
// Punycode for internationalized domains, against lookalike domains
user_pref("network.IDN_show_punycode", true);
// No JavaScript in PDFs
user_pref("pdfjs.enableScripting", false);

// =============================================================================
// Safe Browsing
// =============================================================================

// Google Safe Browsing off, like LibreWolf: no list updates, URL lookups or
// download checks sent to Google
user_pref("browser.safebrowsing.malware.enabled", false);
user_pref("browser.safebrowsing.phishing.enabled", false);
user_pref("browser.safebrowsing.blockedURIs.enabled", false);
user_pref("browser.safebrowsing.downloads.enabled", false);
user_pref("browser.safebrowsing.downloads.remote.enabled", false);
user_pref("browser.safebrowsing.downloads.remote.block_potentially_unwanted", false);
user_pref("browser.safebrowsing.downloads.remote.block_uncommon", false);
user_pref("browser.safebrowsing.downloads.remote.url", "");
user_pref("browser.safebrowsing.provider.google4.gethashURL", "");
user_pref("browser.safebrowsing.provider.google4.updateURL", "");
user_pref("browser.safebrowsing.provider.google4.dataSharingURL", "");
user_pref("browser.safebrowsing.provider.google.gethashURL", "");
user_pref("browser.safebrowsing.provider.google.updateURL", "");

// =============================================================================
// DNS and connections
// =============================================================================

// DNS over HTTPS off (5 = system DNS); Quad9 and dns4all are preset for when
// it's turned on in Settings
user_pref("network.trr.mode", 5);
user_pref("network.trr.uri", "https://dns10.quad9.net/dns-query");
user_pref("network.trr.default_provider_uri", "https://doh.dns4all.eu/dns-query");
user_pref("doh-rollout.enabled", false);
// SOCKS proxies resolve DNS too, so lookups don't leak
user_pref("network.proxy.socks_remote_dns", true);
// No prefetching or speculative connections
user_pref("network.dns.disablePrefetch", true);
user_pref("network.dns.disablePrefetchFromHTTPS", true);
user_pref("network.prefetch-next", false);
user_pref("network.http.speculative-parallel-limit", 0);
user_pref("network.early-hints.preconnect.max_connections", 0);
user_pref("browser.places.speculativeConnect.enabled", false);
user_pref("browser.urlbar.speculativeConnect.enabled", false);
// No connectivity or captive portal checks
user_pref("network.connectivity-service.enabled", false);
user_pref("network.captive-portal-service.enabled", false);
user_pref("captivedetect.canonicalURL", "");
// No region lookups or language pack downloads
user_pref("browser.region.update.enabled", false);
user_pref("app.update.langpack.enabled", false);
user_pref("intl.multilingual.downloadEnabled", false);
user_pref("extensions.getAddons.langpacks.url", "");

// =============================================================================
// Storage and shutdown
// =============================================================================

// On quit, clear cache, cookies, site data and form data; keep history and
// downloads
user_pref("privacy.sanitize.sanitizeOnShutdown", true);
user_pref("privacy.clearOnShutdown_v2.cache", true);
user_pref("privacy.clearOnShutdown_v2.cookiesAndStorage", true);
user_pref("privacy.clearOnShutdown_v2.formdata", true);
user_pref("privacy.clearOnShutdown_v2.browsingHistoryAndDownloads", false);
user_pref("privacy.clearOnShutdown_v2.historyFormDataAndDownloads", false);
user_pref("privacy.clearOnShutdown_v2.downloads", false);
// Clear Recent History defaults to everything (0)
user_pref("privacy.sanitize.timeSpan", 0);
// Cache in memory only (up to 512 MB, files up to 50 MB), media in private
// windows included
user_pref("browser.cache.disk.enable", false);
user_pref("browser.cache.memory.capacity", 524288);
user_pref("browser.cache.memory.max_entry_size", 51200);
user_pref("browser.privatebrowsing.forceMediaMemoryCache", true);
user_pref("media.memory_cache_max_size", 65536);
// Delete temporary files opened from downloads on quit
user_pref("browser.helperApps.deleteTempFileOnExit", true);
// Session restore keeps no form data, scroll positions or cookies (2)
user_pref("browser.sessionstore.privacy_level", 2);

// =============================================================================
// Passwords and forms
// =============================================================================

// No saved passwords, Firefox Relay email masks or form history
user_pref("signon.rememberSignons", false);
user_pref("signon.autofillForms", false);
user_pref("signon.privateBrowsingCapture.enabled", false);
user_pref("signon.firefoxRelay.feature", "disabled");
user_pref("browser.formfill.enable", false);
// No address or credit card autofill
user_pref("extensions.formautofill.addresses.enabled", false);
user_pref("extensions.formautofill.creditCards.enabled", false);
// No Firefox account or Sync
user_pref("identity.fxaccounts.enabled", false);

// =============================================================================
// Downloads
// =============================================================================

// Save to the Downloads folder; ask what to do with new file types
user_pref("browser.download.useDownloadDir", true);
user_pref("browser.download.always_ask_before_handling_new_types", true);
// Downloads start in the temp folder and aren't added to recent files
user_pref("browser.download.start_downloads_in_tmp_dir", true);
user_pref("browser.download.manager.addToRecentDocs", false);

// =============================================================================
// Search and address bar
// =============================================================================

// No search suggestions or engine updates; the address bar shows the URL,
// not the search terms
user_pref("browser.search.suggest.enabled", false);
user_pref("browser.urlbar.suggest.searches", false);
user_pref("browser.search.update", false);
user_pref("browser.urlbar.showSearchTerms.enabled", false);
// Private windows can have their own default engine
user_pref("browser.search.separatePrivateDefault", true);
user_pref("browser.search.separatePrivateDefault.ui.enabled", true);
// No Firefox Suggest: sponsored, trending, weather or partner results
user_pref("browser.urlbar.quicksuggest.enabled", false);
user_pref("browser.urlbar.suggest.quicksuggest.sponsored", false);
user_pref("browser.urlbar.suggest.quicksuggest.nonsponsored", false);
user_pref("browser.urlbar.sponsoredTopSites", false);
user_pref("browser.urlbar.trending.featureGate", false);
user_pref("browser.urlbar.addons.featureGate", false);
user_pref("browser.urlbar.amp.featureGate", false);
user_pref("browser.urlbar.mdn.featureGate", false);
user_pref("browser.urlbar.weather.featureGate", false);
user_pref("browser.urlbar.wikipedia.featureGate", false);
user_pref("browser.urlbar.yelp.featureGate", false);
// Middle-clicking the new tab button doesn't search the clipboard
user_pref("browser.tabs.searchclipboardfor.middleclick", false);

// =============================================================================
// AI
// =============================================================================

// No ML models, AI chatbot, link previews, smart tab groups or ML autofill
user_pref("browser.ml.enable", false);
user_pref("browser.ml.chat.enabled", false);
user_pref("browser.ml.chat.menu", false);
user_pref("browser.ml.linkPreview.enabled", false);
user_pref("browser.tabs.groups.smart.enabled", false);
user_pref("extensions.formautofill.useml", false);
// AI features not listed above default to blocked (Settings > AI Controls)
user_pref("browser.ai.control.default", "blocked");

// =============================================================================
// Telemetry
// =============================================================================

// No telemetry or usage data
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("datareporting.usage.uploadEnabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.server", "data:,");
user_pref("toolkit.telemetry.archive.enabled", false);
user_pref("toolkit.telemetry.newProfilePing.enabled", false);
user_pref("toolkit.telemetry.shutdownPingSender.enabled", false);
user_pref("toolkit.telemetry.updatePing.enabled", false);
user_pref("toolkit.telemetry.bhrPing.enabled", false);
user_pref("toolkit.telemetry.firstShutdownPing.enabled", false);
user_pref("toolkit.telemetry.coverage.opt-out", true);
user_pref("toolkit.coverage.opt-out", true);
user_pref("toolkit.coverage.endpoint.base", "");
user_pref("telemetry.fog.enable_store_submitted_pings", false);
user_pref("identity.fxaccounts.telemetry.clientInfoPing.enabled", false);
user_pref("browser.newtabpage.activity-stream.feeds.telemetry", false);
user_pref("browser.newtabpage.activity-stream.telemetry", false);
user_pref("browser.newtabpage.ping.enabled", false);
user_pref("browser.search.serpEventTelemetryCategorization.enabled", false);
// No studies, remote experiments, extension recommendations or referrals
user_pref("app.normandy.enabled", false);
user_pref("app.normandy.api_url", "");
user_pref("app.shield.optoutstudies.enabled", false);
user_pref("nimbus.rollouts.enabled", false);
user_pref("browser.discovery.enabled", false);
user_pref("browser.referrals.enabled", false);
// No crash or broken site reports
user_pref("breakpad.reportURL", "");
user_pref("browser.crashReports.onDemand", false);
user_pref("browser.tabs.crashReporting.sendReport", false);
user_pref("browser.crashReports.unsubmittedCheck.autoSubmit2", false);
user_pref("extensions.webcompat-reporter.enabled", false);

// =============================================================================
// Ads and onboarding
// =============================================================================

// No sponsored content, stories or Mozilla's default top sites
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
user_pref("browser.newtabpage.activity-stream.default.sites", "");
user_pref("browser.topsites.contile.enabled", false);
user_pref("browser.topsites.useRemoteSetting", false);
// No extension or feature recommendations, no add-on data from Mozilla
user_pref("browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons", false);
user_pref("browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features", false);
user_pref("extensions.getAddons.showPane", false);
user_pref("extensions.htmlaboutaddons.recommendations.enabled", false);
user_pref("extensions.getAddons.cache.enabled", false);
// No in-browser messages, feature tours or messaging experiments from Mozilla
user_pref("browser.newtabpage.activity-stream.asrouter.providers.cfr", "null");
user_pref("browser.newtabpage.activity-stream.asrouter.providers.message-groups", "null");
user_pref("browser.newtabpage.activity-stream.asrouter.providers.messaging-experiments", "null");
user_pref("browser.newtabpage.activity-stream.asrouter.providers.onboarding", "null");
// No Mozilla product promos or UI tours
user_pref("browser.preferences.moreFromMozilla", false);
user_pref("browser.vpn_promo.enabled", false);
user_pref("browser.promo.pin.enabled", false);
user_pref("browser.promo.relay.enabled", false);
user_pref("browser.uitour.enabled", false);
// No welcome, What's New or Terms of Use pages, default browser check or
// about:config warning
user_pref("browser.aboutwelcome.enabled", false);
user_pref("startup.homepage_override_nimbus_disable_wnp", true);
user_pref("browser.startup.homepage_override.mstone", "ignore");
user_pref("termsofuse.bypassNotification", true);
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("browser.aboutConfig.showWarning", false);

// =============================================================================
// DRM, extensions and devtools
// =============================================================================

// No closed-source Widevine DRM (Netflix, Spotify and similar won't play)
user_pref("media.eme.enabled", false);
user_pref("media.gmp-widevinecdm.enabled", false);
// No plugin downloads (Cisco's OpenH264) or update checks for them; video
// calls use the Mac's own H.264 hardware instead
user_pref("media.gmp-provider.enabled", false);
user_pref("media.gmp-gmpopenh264.enabled", false);
user_pref("media.gmp-manager.url", "data:text/plain,");
// Extensions only from the profile and the app (5), not system-wide folders
user_pref("extensions.enabledScopes", 5);
// Extensions offered by other sites need an extra OK before downloading
user_pref("extensions.postDownloadThirdPartyPrompt", false);
// Extensions (uBlock Origin) also run on Mozilla's sites; their resources are
// isolated from pages
user_pref("extensions.webextensions.restrictedDomains", "");
user_pref("privacy.antitracking.isolateContentScriptResources", true);
// No remote debugging
user_pref("devtools.debugger.remote-enabled", false);
