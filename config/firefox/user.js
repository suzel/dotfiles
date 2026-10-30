// =============================================================================
// Firefox user.js
// =============================================================================
// Hardened Firefox based on LibreWolf, arkenfox and Betterfox.
// Applied on every start: edit here, then restart Firefox.
// =============================================================================

// UI
user_pref("ui.prefersReducedMotion", 1);
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("widget.macos.titlebar-blend-mode.behind-window", true);
user_pref("browser.tabs.allow_transparent_browser", true);
user_pref("browser.nova.enabled", false);
user_pref("browser.uidensity", 1);
user_pref("full-screen-api.transition-duration.enter", "0 0");
user_pref("full-screen-api.transition-duration.leave", "0 0");
user_pref("sidebar.verticalTabs", true);
user_pref("sidebar.visibility", "expand-on-hover");
user_pref("browser.toolbars.bookmarks.visibility", "never");
user_pref("browser.display.background_color.dark", "#1e2127");
user_pref("general.smoothScroll", false);
user_pref("layout.spellcheckDefault", 0);
user_pref("browser.warnOnQuitShortcut", false);
user_pref("browser.translations.automaticallyPopup", false);
user_pref("browser.startup.page", 0);
user_pref("browser.startup.homepage", "chrome://browser/content/blanktab.html");
user_pref("browser.newtabpage.enabled", false);

// Performance (Betterfox)
user_pref("gfx.content.skia-font-cache-size", 20);
user_pref("gfx.canvas.accelerated.cache-size", 512);
user_pref("media.cache_readahead_limit", 3600);
user_pref("media.cache_resume_threshold", 1800);
user_pref("network.buffer.cache.size", 65535);
user_pref("network.buffer.cache.count", 48);
user_pref("image.mem.decode_bytes_at_a_time", 32768);
user_pref("network.dnsCacheExpiration", 3600);
user_pref("network.http.max-connections", 1800);
user_pref("network.http.max-persistent-connections-per-server", 10);
user_pref("network.http.max-urgent-start-excessive-connections-per-host", 5);
user_pref("network.http.request.max-start-delay", 5);
user_pref("content.notify.interval", 100000);
user_pref("browser.sessionstore.interval", 60000);
user_pref("media.av1.enabled", false);

// Tracking protection
user_pref("browser.contentblocking.category", "strict");
user_pref("privacy.trackingprotection.allow_list.baseline.enabled", false);
user_pref("privacy.trackingprotection.allow_list.convenience.enabled", false);
user_pref(
  "privacy.query_stripping.strip_list",
  "__hsfp __hssc __hstc __s _bhlid _branch_match_id _branch_referrer _gl _hsenc _openstat at_recipient_id at_recipient_list bbeml bsft_clkid bsft_uid dclid et_rid fb_action_ids fb_comment_id gbraid fbclid gclid guce_referrer guce_referrer_sig hsCtaTracking irclickid mc_eid ml_subscriber ml_subscriber_hash msclkid mtm_cid oft_c oft_ck oft_d oft_id oft_ids oft_k oft_lk oft_sk oly_anon_id oly_enc_id pk_cid rb_clickid s_cid sc_customer sc_eh sc_uid sfmc_activityid sfmc_id sms_click sms_source sms_uph srsltid ss_email_id syclid ttclid twclid unicorn_click_id vero_conv vero_id vgo_ee wbraid wickedid yclid ymclid ysclid",
);
user_pref("privacy.query_stripping.allow_list", "urldefense.com");
user_pref("privacy.globalprivacycontrol.enabled", true);
user_pref("privacy.globalprivacycontrol.pbmode.enabled", true);
user_pref("dom.private-attribution.submission.enabled", false);
user_pref("beacon.enabled", false);
user_pref("network.http.referer.XOriginTrimmingPolicy", 2);
user_pref(
  "network.http.referer.disallowCrossSiteRelaxingDefault.top_navigation",
  true,
);

// Fingerprinting
user_pref("privacy.resistFingerprinting", true);
user_pref("privacy.resistFingerprinting.block_mozAddonManager", true);
user_pref("privacy.window.maxInnerWidth", 1600);
user_pref("privacy.window.maxInnerHeight", 900);
user_pref("dom.webgpu.enabled", false);
user_pref("pdfjs.enableWebGPU", false);
user_pref("media.peerconnection.ice.proxy_only_if_behind_proxy", true);

// Permissions
user_pref("geo.provider.network.url", "https://api.beacondb.net/v1/geolocate");
user_pref("geo.provider.use_corelocation", false);
user_pref("permissions.default.desktop-notification", 2);
user_pref("dom.push.enabled", false);
user_pref("permissions.manager.defaultsUrl", "");
user_pref("dom.webserial.enabled", false);
user_pref("network.lna.allow_top_level_navigation", false);
user_pref("network.lna.local-network-to-localhost.skip-checks", false);
user_pref("gecko.handlerService.defaultHandlersVersion", 999);
user_pref("dom.disable_window_move_resize", true);
user_pref("browser.link.open_newwindow", 3);
user_pref("browser.link.open_newwindow.restriction", 0);
user_pref("media.autoplay.default", 5);
user_pref("security.dialog_enable_delay", 1000);

// HTTPS and certificates
user_pref("dom.security.https_only_mode", true);
user_pref("dom.security.https_only_mode.upgrade_local", true);
user_pref("dom.security.https_only_mode_send_http_background_request", false);
user_pref("dom.security.https_only_mode_error_page_user_suggestions", true);
user_pref("security.cert_pinning.enforcement_level", 2);
user_pref("security.enterprise_roots.enabled", false);
user_pref("security.certerrors.mitm.auto_enable_enterprise_roots", false);
user_pref("security.pki.crlite_mode", 2);
user_pref("security.remote_settings.crlite_filters.enabled", true);
user_pref("security.OCSP.enabled", 0);
user_pref("security.OCSP.require", false);
user_pref("security.qwacs.enabled", false);
user_pref("browser.xul.error_pages.expert_bad_cert", true);
user_pref("security.ssl.require_safe_negotiation", true);
user_pref("security.ssl.treat_unsafe_negotiation_as_broken", true);
user_pref("security.tls.enable_0rtt_data", false);
user_pref("network.http.http3.enable_0rtt", false);
user_pref("security.ssl3.ecdhe_ecdsa_aes_256_sha", false);
user_pref("network.ssl_tokens_cache_persistence", false);
user_pref("security.tls.enable_mlkem1024", true);
user_pref("security.tls.enable_mldsa", true);
user_pref("security.insecure_field_warning.ignore_local_ip_address", false);
user_pref("network.http.prompt-temp-redirect", true);
user_pref("network.auth.subresource-http-auth-allow", 1);
user_pref("security.webauthn.always_allow_direct_attestation", false);
user_pref("security.csp.reporting.enabled", false);
user_pref("network.IDN_show_punycode", true);
user_pref("pdfjs.enableScripting", false);

// Safe Browsing
user_pref("browser.safebrowsing.malware.enabled", false);
user_pref("browser.safebrowsing.phishing.enabled", false);
user_pref("browser.safebrowsing.blockedURIs.enabled", false);
user_pref("browser.safebrowsing.downloads.enabled", false);
user_pref("browser.safebrowsing.downloads.remote.enabled", false);
user_pref(
  "browser.safebrowsing.downloads.remote.block_potentially_unwanted",
  false,
);
user_pref("browser.safebrowsing.downloads.remote.block_uncommon", false);
user_pref("browser.safebrowsing.downloads.remote.url", "");
user_pref("browser.safebrowsing.provider.google4.gethashURL", "");
user_pref("browser.safebrowsing.provider.google4.updateURL", "");
user_pref("browser.safebrowsing.provider.google4.dataSharingURL", "");
user_pref("browser.safebrowsing.provider.google.gethashURL", "");
user_pref("browser.safebrowsing.provider.google.updateURL", "");

// DNS and connections
user_pref("network.trr.mode", 5);
user_pref("network.trr.uri", "https://dns10.quad9.net/dns-query");
user_pref(
  "network.trr.default_provider_uri",
  "https://doh.dns4all.eu/dns-query",
);
user_pref("doh-rollout.enabled", false);
user_pref("network.proxy.socks_remote_dns", true);
user_pref("network.dns.disablePrefetch", true);
user_pref("network.dns.disablePrefetchFromHTTPS", true);
user_pref("network.prefetch-next", false);
user_pref("network.http.speculative-parallel-limit", 0);
user_pref("network.early-hints.preconnect.max_connections", 0);
user_pref("browser.places.speculativeConnect.enabled", false);
user_pref("browser.urlbar.speculativeConnect.enabled", false);
user_pref("network.connectivity-service.enabled", false);
user_pref("network.captive-portal-service.enabled", false);
user_pref("captivedetect.canonicalURL", "");
user_pref("browser.region.update.enabled", false);
user_pref("app.update.langpack.enabled", false);
user_pref("intl.multilingual.downloadEnabled", false);
user_pref("extensions.getAddons.langpacks.url", "");

// Storage and shutdown
user_pref("privacy.sanitize.sanitizeOnShutdown", true);
user_pref("privacy.clearOnShutdown_v2.cache", true);
user_pref("privacy.clearOnShutdown_v2.cookiesAndStorage", true);
user_pref("privacy.clearOnShutdown_v2.formdata", true);
user_pref("privacy.clearOnShutdown_v2.browsingHistoryAndDownloads", false);
user_pref("privacy.clearOnShutdown_v2.historyFormDataAndDownloads", false);
user_pref("privacy.clearOnShutdown_v2.downloads", false);
user_pref("privacy.sanitize.timeSpan", 0);
user_pref("browser.cache.disk.enable", false);
user_pref("browser.cache.memory.capacity", 524288);
user_pref("browser.cache.memory.max_entry_size", 51200);
user_pref("browser.privatebrowsing.forceMediaMemoryCache", true);
user_pref("media.memory_cache_max_size", 65536);
user_pref("browser.helperApps.deleteTempFileOnExit", true);
user_pref("browser.sessionstore.privacy_level", 2);

// Passwords and forms
user_pref("signon.rememberSignons", false);
user_pref("signon.autofillForms", false);
user_pref("signon.privateBrowsingCapture.enabled", false);
user_pref("signon.firefoxRelay.feature", "disabled");
user_pref("browser.formfill.enable", false);
user_pref("extensions.formautofill.addresses.enabled", false);
user_pref("extensions.formautofill.creditCards.enabled", false);
user_pref("identity.fxaccounts.enabled", false);

// Downloads
user_pref("browser.download.useDownloadDir", true);
user_pref("browser.download.always_ask_before_handling_new_types", true);
user_pref("browser.download.start_downloads_in_tmp_dir", true);
user_pref("browser.download.manager.addToRecentDocs", false);

// Search and address bar
user_pref("browser.search.suggest.enabled", false);
user_pref("browser.urlbar.suggest.searches", false);
user_pref("browser.search.update", false);
user_pref("browser.urlbar.showSearchTerms.enabled", false);
user_pref("browser.search.separatePrivateDefault", true);
user_pref("browser.search.separatePrivateDefault.ui.enabled", true);
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
user_pref("browser.tabs.searchclipboardfor.middleclick", false);

// AI
user_pref("browser.ml.enable", false);
user_pref("browser.ml.chat.enabled", false);
user_pref("browser.ml.chat.menu", false);
user_pref("browser.ml.linkPreview.enabled", false);
user_pref("browser.tabs.groups.smart.enabled", false);
user_pref("extensions.formautofill.useml", false);
user_pref("browser.ai.control.default", "blocked");

// Telemetry
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
user_pref("app.normandy.enabled", false);
user_pref("app.normandy.api_url", "");
user_pref("app.shield.optoutstudies.enabled", false);
user_pref("nimbus.rollouts.enabled", false);
user_pref("browser.discovery.enabled", false);
user_pref("browser.referrals.enabled", false);
user_pref("breakpad.reportURL", "");
user_pref("browser.crashReports.onDemand", false);
user_pref("browser.tabs.crashReporting.sendReport", false);
user_pref("browser.crashReports.unsubmittedCheck.autoSubmit2", false);
user_pref("extensions.webcompat-reporter.enabled", false);

// Ads and onboarding
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
user_pref("browser.newtabpage.activity-stream.default.sites", "");
user_pref("browser.topsites.contile.enabled", false);
user_pref("browser.topsites.useRemoteSetting", false);
user_pref(
  "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons",
  false,
);
user_pref(
  "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features",
  false,
);
user_pref("extensions.getAddons.showPane", false);
user_pref("extensions.htmlaboutaddons.recommendations.enabled", false);
user_pref("extensions.getAddons.cache.enabled", false);
user_pref("browser.newtabpage.activity-stream.asrouter.providers.cfr", "null");
user_pref(
  "browser.newtabpage.activity-stream.asrouter.providers.message-groups",
  "null",
);
user_pref(
  "browser.newtabpage.activity-stream.asrouter.providers.messaging-experiments",
  "null",
);
user_pref(
  "browser.newtabpage.activity-stream.asrouter.providers.onboarding",
  "null",
);
user_pref("browser.preferences.moreFromMozilla", false);
user_pref("browser.vpn_promo.enabled", false);
user_pref("browser.promo.pin.enabled", false);
user_pref("browser.promo.relay.enabled", false);
user_pref("browser.uitour.enabled", false);
user_pref("browser.aboutwelcome.enabled", false);
user_pref("startup.homepage_override_nimbus_disable_wnp", true);
user_pref("browser.startup.homepage_override.mstone", "ignore");
user_pref("termsofuse.bypassNotification", true);
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("browser.aboutConfig.showWarning", false);

// DRM, extensions and devtools
user_pref("media.eme.enabled", false);
user_pref("media.gmp-widevinecdm.enabled", false);
user_pref("media.gmp-provider.enabled", false);
user_pref("media.gmp-gmpopenh264.enabled", false);
user_pref("media.gmp-manager.url", "data:text/plain,");
user_pref("extensions.enabledScopes", 5);
user_pref("extensions.postDownloadThirdPartyPrompt", false);
user_pref("extensions.webextensions.restrictedDomains", "");
user_pref("privacy.antitracking.isolateContentScriptResources", true);
user_pref("devtools.debugger.remote-enabled", false);
