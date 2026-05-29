# Zesty — project guide for Claude Code

Zesty is a personalised news app for iPhone & iPad (SwiftUI, iOS 17+). It learns
the user's interests and builds a relevance-ranked feed from free RSS sources,
with native ads, theming, and iCloud sync. This file orients a Claude Code
session working on the repo locally.

## Where things live

Everything is under `zest/`:

- `zest/Zest.xcodeproj` — **generated**, committed so it opens by double-click.
- `zest/.gen_xcodeproj.py` — the generator. **Do not hand-edit `project.pbxproj`.**
  Edit this script, then run `python3 zest/.gen_xcodeproj.py` to regenerate.
- `zest/project.yml` — XcodeGen spec (alternate generator, kept in sync).
- `zest/Zest/` — the app (App, Models, Engine, Services, ViewModels, Views).
- `zest/Shared/` — code shared with the (not-yet-included) widget.
- `zest/ZestWidget/`, `zest/ZestTests/` — widget + tests (NOT in the single-target
  generated project; app-only for reliability).
- Guides: `README.md`, `GETTING_STARTED.md`, `TESTFLIGHT.md`.

## Critical workflow rules

1. **Adding/removing a Swift file** → add its path to `SOURCES` in
   `.gen_xcodeproj.py`, then regenerate. Forgetting this causes
   "Cannot find <Type> in scope" build errors.
2. **Every change destined for TestFlight** → bump `CURRENT_PROJECT_VERSION`
   in both `.gen_xcodeproj.py` and `project.yml`, then regenerate. Apple rejects
   duplicate build numbers. (Currently at build 9.)
3. After regenerating, sanity-check the pbxproj: all 24-hex IDs referenced are
   defined, and `{`/`}` are balanced.
4. The app target is single-target on purpose (no widget/tests target) to keep
   the hand-generated project reliable.

## Key conventions

- **Theming**: `Flavour` (Services/ThemeSettings.swift) sets accent + light/dark;
  applied app-wide in `RootView` via `.tint` + `.preferredColorScheme`. Picked in
  `FlavourPickerView` (first-launch + Settings).
- **Learning engine**: `InterestProfile` (tag weights, exponential decay,
  impression fade), `InterestStore` (persistence + iCloud key-value sync, single
  source of truth, `.shared`), `FeedRanker` (interest + recency + pinned + a
  little exploration; pinned topics get a large non-decaying boost).
- **News**: `RSSClient` aggregates ~75 free feeds (`FeedCatalog`), browser-style
  request headers to avoid bot-blocking, capped concurrency, per-feed failures
  swallowed. `FeedViewModel` caches the ranked feed (offline + instant load) and
  drops already-read articles on refresh.
- **Ads**: AdMob native ads via `NativeAdLoader` + `NativeAdCardView`, mixed into
  the feed every 8 stories. `AdConfig.useTestAds = true` while on TestFlight —
  flip to false only once live on the App Store. App ID is in `Info.plist`
  (`GADApplicationIdentifier`).
- **Reader**: `ArticleReaderView` (Views/SafariView.swift) is a WKWebView with a
  Back button (bottom-left) and Share (bottom-right).

## Build / run / ship

- Open `zest/Zest.xcodeproj`, pick an iPhone simulator, ⌘R.
- TestFlight: device = "Any iOS Device", Product → Archive → Distribute →
  App Store Connect → Upload. App is "Zest News" in App Store Connect; display
  name is "Zesty"; bundle id `com.hjatte.zest`.
- The Google Mobile Ads SDK is an SPM dependency; first build resolves it
  (needs network). If "Missing package product 'GoogleMobileAds'": File →
  Packages → Reset Package Caches.

## Cannot be done from a cloud container

Building, archiving, and TestFlight uploads require Xcode on the Mac — do those
locally. A cloud session can only edit code and push to GitHub.
