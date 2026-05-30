# Zesty — project guide for Claude Code

Zesty is a personalised news app for iPhone & iPad (SwiftUI, iOS 17+). It learns
the reader's interests, optimises for *reading completion* (not clicks), and
deliberately breaks the filter bubble. No backend — everything is on-device,
with iCloud key-value sync. This file orients a Claude Code session working on
the repo. **Currently at build 25.**

## Where things live

Everything is under `zest/`:

- `zest/Zest.xcodeproj` — **generated**, committed so it opens by double-click.
- `zest/.gen_xcodeproj.py` — the generator. **Do not hand-edit `project.pbxproj`.**
  Edit this script, then run `python3 zest/.gen_xcodeproj.py` to regenerate.
- `zest/project.yml` — XcodeGen spec (kept in sync; alternate generator).
- `zest/Zest/` — the app (App, Models, Engine, Services, ViewModels, Views).
- `zest/Shared/` — code shared with the (not-yet-included) widget.
- `zest/Zest/Resources/Readability.js` — bundled Mozilla Readability for the reader.
- `zest/ZestWidget/`, `zest/ZestTests/` — widget + tests (NOT in the single-target
  generated project; app-only for build reliability).

## Critical workflow rules

1. **Add/remove a Swift file** → update `SOURCES` in `.gen_xcodeproj.py`, then
   regenerate. Forgetting → "Cannot find <Type> in scope".
2. **Every change for TestFlight** → bump `CURRENT_PROJECT_VERSION` in both
   `.gen_xcodeproj.py` and `project.yml`, then regenerate. (Apple rejects
   duplicate build numbers.)
3. After regenerating, sanity-check the pbxproj: all 24-hex IDs referenced are
   defined, braces balanced. (The generator does this implicitly; a quick Python
   check is wise after edits.)
4. App is single-target on purpose (no widget/tests target).

## Architecture

- **Learning engine** (`Zest/Engine/`):
  - `InterestProfile` — tag→weight with exponential decay + impression fade.
  - `InterestStore` (`.shared`) — source of truth; persistence + **iCloud KVS**
    sync; tracks `seenIDs` (read), `shownIDs` (scrolled past), `pinnedTags`.
    Decay runs on an **active-day clock** (`decayNow`): half-life counts only
    days the app is opened, not calendar days.
  - `FeedRanker` — score = interest + pinned boost + **recency (real wall-clock
    time!)** − seen penalty + bubble-aware exploration; then **MMR diversity**
    and a **civic quota**. `decayDate` is ONLY for interest decay; recency uses
    `Date()`.
  - `TopicGraph` — curated clusters of news topics → 0–1 "bubble distance" for
    serendipity/exploration. (Hand-curated; MIND is *not* wired in.)
  - Signals (`InteractionEvent`): **completion-first** — `openArticle` = 0
    (a click is gameable), `readToEnd` (~70% scrolled, tracked in the reader)
    = +10. Onboarding like/dislike ±. `hideArticle` = strong negative.
- **News** (`Zest/Services/`): `RSSClient` aggregates ~75 free feeds
  (`FeedCatalog`) with a browser User-Agent (avoids bot-blocking), capped
  concurrency, per-feed failures swallowed. `RSSParser` (RSS+Atom).
  `FeedViewModel` caches the ranked feed (instant + offline), drops read and
  scrolled-past stories on refresh (unless strongly matching).
- **Ads**: AdMob native ads via `NativeAdLoader` + `NativeAdCardView`, every 8
  stories. SDK is the **GoogleMobileAds Swift Package pinned to exact 11.13.0**
  (GAD-prefixed API) with a committed `Package.resolved`. `AdConfig.useTestAds
  = true` (test ads) until live. App id in `Info.plist` (`GADApplicationIdentifier`).
- **Theming**: `Flavour` (6 light + 6 dark) in `ThemeSettings`; picked in
  `FlavourPickerView` (first launch + Settings); applied app-wide via `.tint` +
  `.preferredColorScheme` in `RootView`.
- **Reader**: `ArticleReaderView` (`Views/SafariView.swift`) — custom WKWebView
  that extracts a clean article via Readability; Reader/Web setting + per-article
  toggle; light/dark toggle; tracks read fraction for the completion signal.
- **UI**: Feed has a "Zesty News" header with a drawn lemon refresh button,
  "Why am I seeing this?" (long-press), a "Beyond your bubble" section/badges,
  a learning toast after reading, and a "You're all caught up" footer. Tabs:
  **Feed · Interests · Settings**. Interests tab (`TopicsView`) shows learned
  interests with Yes/Less/Not-interested + pin + suggestions. Settings has
  flavour, reader mode, a **Serendipity dial**, sources, reset.

## Onboarding flow

`RootView` gates: pick a flavour → welcome card → swipe a fixed list of **10
varied sample stories** (`Article.onboardingSamples`, no network) → "you're all
set". No lemon emojis/graphics by request.

## Build / run / ship

- Open `zest/Zest.xcodeproj`, pick an iPhone simulator, ⌘R.
- First build resolves the GoogleMobileAds package (needs network). If "Missing
  package product 'GoogleMobileAds'": File → Packages → Reset Package Caches.
- TestFlight: device = "Any iOS Device", Product → Archive → Distribute →
  App Store Connect → Upload. ASC app is "Zest News"; display name "Zesty";
  bundle id `com.hjatte.zest`.

## Cannot be done from a cloud container

Building, archiving and TestFlight uploads require Xcode on the Mac. A cloud
session can only edit code and push to GitHub. MIND and most non-GitHub hosts
are network-blocked in the cloud sandbox.
