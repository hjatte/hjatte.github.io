# Getting Zest running — a total beginner's guide

No prior experience needed. You have a Mac, an iPhone and an iPad — that's
everything required. The **Mac builds the app**; you can then try it on the
**simulator** (a pretend iPhone on your Mac) or on your **real iPhone/iPad**.

There is no way to build a native iPhone app on the phone itself — this is the
same process behind every App Store app, including your existing ones.

---

## Step 1 — Install Xcode (once)

1. Open the **App Store** on your Mac.
2. Search for **Xcode**. Install it. (It's free but large — a few GB — so this
   can take a while. Let it finish.)
3. Open Xcode once after installing. If it asks to "install additional
   components", say yes.

## Step 2 — Get this code onto your Mac

1. In a web browser, go to your repository on GitHub:
   `https://github.com/hjatte/hjatte.github.io`
2. Near the top there's a branch dropdown (it usually says `main`). Click it and
   choose **`claude/personalized-news-feed-iphone-DuhdR`** — that's the branch
   with the app.
3. Click the green **`< > Code`** button → **Download ZIP**.
4. In your **Downloads** folder, double-click the ZIP to unzip it. You'll get a
   folder; inside it is a folder called **`zest`**. That's the app.

## Step 3 — Open the project (just double-click)

Inside the `zest` folder, find **`Zest.xcodeproj`** (its icon is a blue Xcode
blueprint). **Double-click it.** Xcode opens with the whole app loaded. That's it
— no Terminal, no extra tools.

> The first time, Xcode might show a small "trust"/"open" prompt because the
> project came from the internet — click **Trust** / **Open**.

> Note: this easy project contains the **app** (everything you swipe and read).
> The optional Home-Screen **widget** is added in a later step using the advanced
> setup, once you're comfortable — it isn't needed to try the app.

## Step 4 — Run it on the pretend iPhone (simulator)

1. Xcode is now open. At the **top middle** there's a bar; on its right is a
   device name. Click it and pick any **iPhone** (e.g. "iPhone 15").
2. Press the **▶ Play** button (top-left), or press **⌘ + R**.
3. The first build takes a minute. A simulated iPhone opens and **Zest launches**.
   Swipe through the cards to teach it your taste, then browse your feed. 🎉

That's the whole loop — no Apple account needed for the simulator.

## Step 5 — Put it on your real iPhone (optional)

1. Plug your iPhone into the Mac with a cable. Tap **Trust** on the phone.
2. In Xcode, click the device name at the top and choose **your iPhone**.
3. Xcode may say you need to set a "Team":
   - Click the blue **Zest** project icon in the left sidebar.
   - Select the **Zest** target → **Signing & Capabilities** tab.
   - Tick **Automatically manage signing** and pick your name/Apple ID under
     **Team**. Do the same for the **ZestWidgetExtension** target.
4. Press **▶ Play**. The first time, your iPhone may say the developer is
   untrusted — go to **Settings → General → VPN & Device Management** on the
   phone and tap **Trust**.

## Step 6 — Add the widget (optional)

Once the app has run on your phone at least once:
1. Long-press an empty part of the Home Screen until icons wiggle.
2. Tap the **+** (top-left) → search **Zest** → add the widget.
   It shows your top personalised stories; tapping one opens the app.

---

## Frequently confused things

- **"Create PR" button** — ignore it. It's just GitHub's "merge this into my
  main project" step. Your code is already saved on the branch; you don't need
  a PR to build or test the app.
- **Simulator vs real phone** — start with the simulator (Step 4); it's the
  fastest way to see it working and needs no account setup.
- **It works for everyone** — there's no API key or login. Zest reads free,
  public news feeds, so anyone who installs it just gets news straight away.

Stuck on any step? Note which step number and what you see on screen, and it can
be sorted quickly.
