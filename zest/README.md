# Zest — a personalised news app for iPhone & iPad

A SwiftUI universal app (iOS 17+) that learns what you like and builds you a
personalised, scrollable news feed by aggregating **free, open RSS feeds from
many publishers** (BBC, The Guardian, NPR, Al Jazeera, Sky News, The Verge,
TechCrunch, Ars Technica…) — plus a Home Screen widget showing your top stories.

No API key, no account, no per-user setup: it works for everyone out of the box.

It's the idea you described: a Google-app-style feed, a Tinder-style swipe deck
to learn your taste, a weighted interest model that goes **up when you click**
and **fades when you don't**, and a widget on the leftmost Home Screen page.

---

## ⚠️ One honest limitation up front

iOS **widgets cannot scroll** — Apple renders them as static snapshots
(WidgetKit), so the "old Android Google Now feed living inside the widget"
isn't possible on iPhone. Zest does the closest thing iOS allows:

- The **widget** shows your **top personalised headlines** (small / medium / large).
- Tapping a headline deep-links straight into the app.
- The **full scrollable feed** lives in the app, one swipe + tap away.

Everything else you asked for is here and works.

---

## What's implemented

| Your request | How it works |
|---|---|
| Personalised feed like the Google app | `FeedView` + `FeedRanker` rank real articles by your interests |
| Swipe deck (like Tinder) to learn taste | `OnboardingView` / `SwipeCardView`, seeded from a big shuffled batch of real stories |
| Return any time to refine | The **Tune** tab re-opens the deck whenever you want |
| Click → weights go up (e.g. `uk +10`, `politics +10`) | `InterestEngine`: opening an article adds **+10** to each of its tags |
| Ever-changing algorithm | Exponential **time-decay** (adjustable half-life) continuously fades scores |
| Things fade if shown but never clicked | **Impression penalty** nudges ignored topics down; `prune()` drops dead ones |
| Scrollable widget on the left Home Screen | Widget shows top stories in Today View (can't scroll — see note above) |
| Multiple news sources, free, for everyone | `RSSClient` aggregates ~25 free RSS/Atom feeds; no key, dead feeds skipped |
| Choose your sources | Settings → News sources lets anyone toggle publishers on/off |

---

## Project layout

```
zest/
├─ project.yml              # XcodeGen spec — generates Zest.xcodeproj
├─ Shared/                  # code compiled into BOTH app and widget
│  ├─ Store/AppGroup.swift      # App Group id + URL scheme
│  ├─ Store/SharedStore.swift   # app ↔ widget data hand-off
│  └─ Models/WidgetHeadline.swift
├─ Zest/                    # the app
│  ├─ App/                  # @main, Info.plist, entitlements, privacy manifest
│  ├─ Models/Article.swift, NewsSource.swift
│  ├─ Engine/               # ⭐ the learning algorithm
│  │  ├─ InterestProfile.swift  # weights + decay + impression fade + prune
│  │  ├─ InterestStore.swift    # persistence + single source of truth
│  │  ├─ InteractionEvent.swift # point deltas (+10 on click, etc.)
│  │  └─ FeedRanker.swift       # scores & orders the feed
│  ├─ Services/             # ⭐ the multi-source news layer
│  │  ├─ NewsAPIClient.swift    # pluggable provider protocol
│  │  ├─ RSSClient.swift        # aggregates many feeds, resilient to failures
│  │  ├─ RSSParser.swift        # RSS 2.0 + Atom parser (Foundation XMLParser)
│  │  ├─ FeedCatalog.swift      # the built-in list of free feeds
│  │  └─ SourceSettings.swift   # which sources are switched on
│  ├─ ViewModels/
│  └─ Views/                # Feed, Onboarding/Swipe, Interests, Settings
├─ ZestWidget/             # WidgetKit extension
└─ ZestTests/              # unit tests for the engine
```

---

## Setup (about 5 minutes)

You need a Mac with **Xcode 15+**.

### 1. Install XcodeGen and generate the project
The Xcode project is generated from `project.yml` (so it's reproducible and
diff-friendly rather than a giant binary file).

```bash
brew install xcodegen
cd zest
xcodegen generate
open Zest.xcodeproj
```

### 2. (Nothing to configure for news)
There's no API key or account. Zest pulls free RSS feeds, so it works
immediately. Users can toggle which publishers to include in **Settings →
News sources**.

### 3. Set signing + the App Group
In Xcode, for **both** the `Zest` and `ZestWidgetExtension` targets:

1. **Signing & Capabilities → Team**: pick your Apple Developer team.
2. Change the bundle IDs from `com.hjatte.zest*` to your own prefix if you like
   (update `AppGroup.identifier` and both `.entitlements` files to match).
3. Make sure **App Groups** capability is on for both targets with the **same**
   group id (`group.com.hjatte.zest` by default).

### 4. Run
Pick the `Zest` scheme and run on a simulator or device. First launch drops you
into the swipe deck; finish it and you land on your feed. Long-press the Home
Screen → add the **Zest** widget to your Today View / Home Screen.

---

## How the learning algorithm works

The whole "brain" is in `Zest/Engine/`. In plain terms:

1. **Tagging.** Every article is reduced to interest tokens from its feed
   category, the publisher, and any `<category>` tags in the feed item. A UK
   politics story becomes `["uk", "politics", "news", …]` — so "uk" and
   "politics" are tracked separately, exactly like your example.

2. **Scoring.** Each tag has a score. Interactions move it:
   - open/click an article → **+10** to each tag (strongest signal)
   - read to the end → +4
   - swipe right in the deck → +6, swipe left → −4
   - "show me less" → −12

3. **Decay (the "ever-changing" part).** Scores decay exponentially with a
   **half-life** (default 14 days, adjustable on the Interests tab). Stop
   engaging with a topic and it bleeds toward zero on its own.

4. **Fade-out of ignored topics.** Every time stories are shown, their tags get
   a small **impression penalty** — scaled by how rarely you click them. Topics
   you keep seeing but never tap fade faster, then `prune()` deletes them.

5. **Ranking.** The feed scores each article = Σ(tag scores) + a freshness bonus
   − a seen-before penalty + a little **exploration randomness**, so the feed
   never collapses to one topic and faded interests can resurface.

Run the unit tests (`⌘U`, the `ZestTests` target) to see all of this verified.

---

## Adding / changing sources

- **Add a feed:** drop another `source(...)` line into `FeedCatalog.swift`.
  That's it — it shows up in Settings and the aggregator picks it up.
- **Different provider entirely:** `NewsAPIClient` is a protocol and `RSSClient`
  is the default. Write another conformer (a JSON API, your own backend, etc.)
  and change one line in `ZestApp.swift`:

```swift
private let client: NewsAPIClient = RSSClient()   // ← swap me
```

---

## Before you ship to the App Store

- **Feed terms & attribution.** RSS feeds are free to read, but each publisher
  has its own terms; most expect you to link back to the original article
  (Zest does — tapping a story opens the publisher's page). Review each
  publisher's RSS/terms before a commercial release, and consider showing the
  source name prominently (Zest shows it as the article's section/pillar).
- **App Icon.** The asset catalog has a placeholder `AppIcon` slot; drop in a
  1024×1024 icon.
- **Privacy manifest.** `PrivacyInfo.xcprivacy` is included (declares no
  tracking; UserDefaults reason `CA92.1`). Zest keeps the interest model only
  in the on-device App Group container.
- Bump `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` in `project.yml` per release.

---

## Renaming the app

"Zest" is just a placeholder (citrus, to match Pomelo/Tangerine 🍊). To rename,
change the display names in the two `Info.plist` files, the bundle IDs +
`AppGroup.identifier` + both `.entitlements`, and the `name:` in `project.yml`,
then re-run `xcodegen generate`.
