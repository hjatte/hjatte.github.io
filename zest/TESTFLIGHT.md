# Putting Zest on TestFlight (test on your own iPhone & iPad)

TestFlight installs the app wirelessly through Apple's **TestFlight** app — no
cables, no "trust developer" steps. You need your **paid** Apple Developer
Program membership (you have one).

Do these in order. It's a lot the first time, but most of it is one-time setup.

---

## 0. Get the latest code

Re-download the ZIP (it now includes the app icon and upload fixes):
GitHub → branch `claude/personalized-news-feed-iphone-DuhdR` → **Code → Download
ZIP** → unzip → double-click **`Zest.xcodeproj`**.

## 1. Sign in to Xcode with your Apple ID (one-time)

- Xcode menu → **Settings** → **Accounts** → **+** → **Apple ID** → sign in with
  the Apple ID that has your Developer Program membership.

## 2. Set the Team and bundle ID (one-time)

1. Click the blue **Zest** icon at the top of the left sidebar.
2. Select the **Zest** target → **Signing & Capabilities** tab.
3. Tick **Automatically manage signing**.
4. **Team** → choose your developer team.
5. **Bundle Identifier** is `com.hjatte.zest`. If Xcode complains it's taken or
   invalid, change it to something unique, e.g. `com.harryattenborough.zest`.
   Xcode will register it with Apple for you (a green tick appears).

## 3. Create the app record in App Store Connect (one-time)

1. Go to <https://appstoreconnect.apple.com> → **Apps** → **+** → **New App**.
2. Fill in:
   - **Platform:** iOS
   - **Name:** what shows on the store. Must be unique across the whole App
     Store — if "Zest" is taken, use e.g. "Zest News". (This is separate from
     the icon label.)
   - **Primary Language:** English (UK)
   - **Bundle ID:** pick `com.hjatte.zest` from the dropdown (it appears here
     because Xcode registered it in step 2).
   - **SKU:** any private code, e.g. `zest-001`.
3. Click **Create**. (If prompted to accept agreements, do that first under
   Business / Agreements, Tax, and Banking.)

## 4. Archive the app

1. At the **top of Xcode**, where it shows the device, click it and choose
   **Any iOS Device (arm64)**. ⚠️ You can't archive while a Simulator is
   selected — the **Archive** menu stays greyed out until you pick this.
2. Menu: **Product → Archive**. Wait a minute or two for it to build.
3. The **Organizer** window opens with your new archive listed.

## 5. Upload to App Store Connect

1. In the Organizer, click **Distribute App**.
2. Choose **App Store Connect** → **Next**.
3. Choose **Upload** → **Next** (accept the default options; keep "automatically
   manage signing").
4. Click **Upload**. Wait for **"Upload Successful"**.

## 6. Turn on TestFlight and install on your devices

1. Back in App Store Connect → your app → **TestFlight** tab.
2. Your build shows **"Processing"** for a few–several minutes. Grab a tea.
3. When it's ready: under **Internal Testing**, create a group (e.g. "Me"),
   click **+** to add the build, and add yourself as a tester (your Apple ID
   email — you're already on your team).
4. On your **iPhone/iPad**: install the **TestFlight** app from the App Store,
   sign in with the **same Apple ID**, and Zest will be there to install. 🎉

---

## Common first-time snags

| What you see | Fix |
|---|---|
| **Archive** menu is greyed out | Select **Any iOS Device (arm64)** at the top, not a Simulator. |
| "No signing certificate" / "Add account" | Do step 1 (sign in), then pick your Team in step 2. |
| Bundle ID "not available" | Change it to something unique like `com.harryattenborough.zest`, then re-pick it in App Store Connect. |
| App **Name** already exists | Choose a different store name in step 3 (e.g. "Zest News"). |
| Build stuck "Processing" a long time | Normal; can take 10–30 min the first time. It emails you when ready. |
| Asked about **export compliance** | We set the flag to "no non-exempt encryption", so just answer **No** if it still asks. |

## Next upload

For every new build after the first, bump the **build number** so Apple accepts
it: open `project.yml`/Xcode target settings and increase
`CURRENT_PROJECT_VERSION` (1 → 2 → 3 …). Then Archive and Upload again.
