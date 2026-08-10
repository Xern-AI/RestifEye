# Distributing RestifEye

A step-by-step checklist for listing RestifEye everywhere people look for Linux apps.
Every step is one concrete action. Steps marked ✅ are already done — skip them.

---

## Assets (ready to use)

These are already prepared. Use them when filling out forms.

### Logo

✅ Exported to `docs/assets/icon-512.png` (512×512 PNG).

### Text blurbs — copy-paste these into every submission form

**Tagline (short, ≤80 characters):**
```
Break reminders that keep you fit
```

**One-liner (≤160 characters):**
```
Free break reminder for Linux with guided eye exercises, stretches, and posture resets. Never interrupts meetings.
```

**Paragraph description:**
```
RestifEye reminds you to rest your eyes and move your body at healthy intervals.
Every break shows an animated exercise - eye movements, neck stretches, shoulder
rolls, or full-body moves like squats and lunges - matched to your intensity
setting (seated-only for the office, anything-goes at home).

It detects when you're in a call and waits.
It notices when you've already stepped away and credits you the break.
It warns 30 seconds before taking your screen.
It tracks your screen time and break patterns locally, with weekly advice based on your own data.

No accounts, no cloud, no telemetry.
```

**What makes RestifEye different from other break apps:**
```
- Guided exercises (animated), not just a countdown or text tip
- Meeting detection — holds breaks when your mic or camera is active
- Exercise intensity settings — seated-only for the office, full-body at home
- Screen-time analytics with personalized advice
- Tray icon that shows how your day is going at a glance
- Credits breaks you already took (walked away, locked screen)
```

**Competitor list (for "alternative to" fields):**
```
Stretchly, Safe Eyes, Workrave, BreakTimer, RSIBreak, Stretch Break, Time Out
```

### Screenshots — you need to take these

- [x] Open RestifEye on your machine.
- [x] Take screenshots of: **break overlay with exercise** (most important!), **dashboard**, **analytics**, **settings**.
- [x] Save them somewhere easy to find (e.g. `~/Pictures/restifeye/`).

### Demo GIF — optional, do later if you want

- [ ] Use GNOME screen recorder (Super + Shift + R) or install `peek` (`sudo dnf install peek`).
- [ ] Record 30 seconds: notification → break overlay with exercise animation → back to desktop.
- [ ] Save as GIF.

---

## Week 1: Linux directories + evergreen listings

### Task 1: AppImageHub

AppImageHub auto-discovers your AppImage from GitHub Releases. You submit one file with your repo URL.

- [x] Go to: https://github.com/AppImage/appimage.github.io
- [x] Click **Fork** (top right).
- [x] In your fork, go to the `data/` folder.
- [x] Click **Add file** → **Create new file**.
- [x] Name the file exactly: `RestifEye`
- [x] Paste this single line as the contents:
  ```
  https://github.com/Xern-AI/RestifEye
  ```
- [x] Click **Commit new file**.
- [x] Go back to the top of your fork. Click **Contribute** → **Open pull request**.
- [x] Title: `Add RestifEye`
- [x] Click **Create pull request**.
- [ ] Wait for the bot to auto-test (1–7 days).

### Task 2: AlternativeTo

- [x] Go to: https://alternativeto.net → **Sign Up** → confirm email.
- [x] Click your profile icon → **Suggest new application**.
- [x] Fill in:
  - **Name:** `RestifEye`
  - **Tagline:** `Break reminders that keep you fit`
  - **URL:** `https://github.com/Xern-AI/RestifEye`
  - **Description:** Paste the paragraph description from above.
  - **License:** Select `Proprietary` (closest match for PolyForm Shield)
  - **Cost:** `Free`
  - **Platform:** Check `Linux`
  - **Tags:** `break reminder`, `eye exercises`, `stretching`, `RSI`, `screen time`, `health`, `fitness`, `productivity`
- [x] Upload `docs/assets/icon-512.png` as the logo.
- [x] Upload your screenshots (break overlay with exercise first!).
- [x] Click **Submit**. Wait for approval (days to weeks).
- [x] After approval, suggest RestifEye as an alternative to each competitor:
  - [x] Search for `Stretchly` → open its page → click **Suggest alternative** → type `RestifEye` → submit.
  - [x] Repeat for: `Safe Eyes`, `Workrave`, `BreakTimer`, `RSIBreak`, `Time Out`.

### Task 3: SourceForge

- [ ] Go to: https://sourceforge.net → **Join** → confirm email.
- [ ] Click **Create a Project**.
- [ ] Fill in:
  - **Name:** `RestifEye`
  - **URL slug:** `restifeye`
  - **Description:** Paste the paragraph description.
  - **Category:** `Desktop Environment` or `Productivity`
  - **License:** `Other/Proprietary License`
  - **OS:** `Linux`
- [ ] Click **Create**.
- [ ] On your project page, click **Files** → **Add Folder** → name it the version (e.g. `v0.1.1`).
- [ ] Upload the three release files (AppImage, .deb, .rpm) from your latest GitHub Release.
- [ ] Click the **ℹ️** icon next to the AppImage → **Select as default download**.

### Task 4: Snap Store (optional — most technical, skip if low energy)

- [ ] Go to: https://snapcraft.io/account → create an Ubuntu One account → confirm email.
- [ ] Install snapcraft:
  ```sh
  sudo dnf install snapd
  sudo ln -s /var/lib/snapd/snap /snap
  sudo snap install snapcraft --classic
  ```
- [ ] Log in: `snapcraft login` (opens browser).
- [ ] Register the name: `snapcraft register restifeye`
- [ ] Build: `snapcraft` (run from the repo root — takes 10–20 min first time).
- [ ] Upload: `snapcraft upload restifeye_*.snap --release stable`
- [ ] Go to https://snapcraft.io/restifeye → **Settings** → upload icon, screenshots, description.

---

## Week 2: Community posts + social media

### Task 5: Reddit — r/linux

- [ ] Go to: https://www.reddit.com/r/linux/ → **Create Post**.
- [ ] Title: `I made a break reminder that shows you actual exercises instead of a blank countdown`
- [ ] Paste this as the post body:

```
I kept uninstalling break reminder apps. They'd either:
- Interrupt me mid-call
- Show me a blank screen with a countdown and expect me to... do what?
- Nag me right after I'd walked to the kitchen and back

So I built RestifEye. Two things make it different:

1. Every break shows an animated exercise — eye movements, neck
   stretches, shoulder rolls, posture resets, squats, lunges. You pick
   your intensity (seated-only for the office, full-body at home).

2. It actually knows when you're busy. Mic or camera active? It waits.
   Already walked away from your desk? It credits you the break.

Other stuff:
- 30-second warning before every break (Start / Snooze / Skip)
- Screen-time analytics with weekly advice
- Tray icon that changes face based on how your day is going
- No accounts, no telemetry, everything stays on your machine

AppImage, DEB, and RPM:
https://github.com/Xern-AI/RestifEye

Happy to answer any questions.
```

- [ ] Attach your best screenshot (break overlay showing an exercise).
- [ ] Post. Stay online for 2–3 hours and reply to every comment.

### Task 6: Reddit — r/Fedora

- [ ] Go to: https://www.reddit.com/r/Fedora/ → **Create Post**.
- [ ] Title: `RestifEye — break reminder with guided exercises, RPM available`
- [ ] Paste:

```
Built a break reminder that shows you animated exercises during
breaks instead of a blank countdown. Eye exercises, stretches,
posture resets — intensity is configurable.

It also detects when your mic/camera is active and holds the break
until your call ends.

RPM and AppImage:
https://github.com/Xern-AI/RestifEye/releases

Install: sudo dnf install ./RestifEye-*.rpm

Heads up: GNOME needs the AppIndicator extension for the tray icon.
KDE/XFCE/Cinnamon work out of the box.
```

- [ ] Post. Reply to all comments.

### Task 7: Hacker News — Show HN

- [ ] Go to: https://news.ycombinator.com → create an account if you don't have one.
- [ ] Spend a few days upvoting and commenting on other posts first (new empty accounts look spammy).
- [ ] When ready, click **submit**.
- [ ] Title: `Show HN: RestifEye – Break reminder with guided exercises, meeting detection, screen-time analytics`
- [ ] URL: `https://github.com/Xern-AI/RestifEye`
- [ ] Leave the text field empty.
- [ ] Best time to post: **Tuesday–Thursday, 5:30–7:30 PM IST** (8–10 AM US Eastern).
- [ ] Stay online 4 hours. Reply to every comment in detail.

### Task 8: LinkedIn

- [ ] Open LinkedIn → click **Start a post**.
- [ ] Paste this:

```
I shipped something small for myself and figured others might want it.

I spend 10+ hours a day at a screen. Every break reminder app I tried
either interrupted my calls or showed me a blank countdown and hoped
I'd figure out what to do with it.

RestifEye is different in two ways:

1. Every break shows a guided exercise — eye movements, stretches,
   posture resets. You set the intensity: seated-only if you're in a
   shared office, squats and lunges if you're working from home.

2. It knows when you're in a call (detects mic/camera) and waits.
   And if you already took a walk, it credits you the break instead
   of nagging you the moment you sit back down.

It also tracks your screen time locally and gives you weekly advice
based on your own patterns. No accounts, no cloud.

Free for Linux: https://github.com/Xern-AI/RestifEye

If your back hurts by 4pm, give it a try.
```

- [ ] Attach 1–2 screenshots (exercise during break + analytics).
- [ ] Post.

### Task 9: Twitter / X

- [ ] Open Twitter → compose a new post.
- [ ] Paste this:

```
most break reminder apps show you a blank countdown and hope you
stretch.

RestifEye shows you an actual exercise — eye movements, neck rolls,
posture resets, even squats.

it also waits for your calls to end and credits breaks you already
took.

free for linux: github.com/Xern-AI/RestifEye
```

- [ ] Attach a screenshot of the break overlay with an exercise.
- [ ] Post.
- [ ] Reply to your own post with a thread:

```
what makes it different from stretchly / safe eyes / workrave:

→ animated exercises, not text tips
→ detects active mic/camera and holds the break
→ intensity setting (office vs home)
→ screen-time analytics + weekly advice
→ tray icon that shows how your day is going

no accounts. no cloud. no telemetry.
```

---

## Week 3: Product Hunt + batch submissions

### Task 10: Product Hunt

**Do these prep steps 1–2 weeks before your planned launch day:**

- [ ] Go to: https://www.producthunt.com → **Sign up** (use real name and photo).
- [ ] Wait 7 days. During that time, browse daily. Upvote 2–3 products. Leave 1–2 real comments.
- [ ] Prepare your listing page:
  - Thumbnail: use `docs/assets/icon-512.png`
  - Gallery: upload 4–5 screenshots (exercise overlay first)
  - Tagline: `Break reminders that keep you fit`
  - Description: use the paragraph blurb + a "Why I built this" paragraph
  - Topics: `Productivity`, `Developer Tools`, `Health & Fitness`
  - Demo GIF if you have one

**On launch day (pick a Tuesday, Wednesday, or Thursday):**

- [ ] Go to https://www.producthunt.com/posts/new → fill in all details → schedule or publish.
- [ ] Share the PH link with friends and ask them to leave a genuine comment (not just "nice!").
- [ ] Stay online from 12:30 PM IST to 8 PM IST. Reply to every comment within minutes.
- [ ] Share the PH link on your Twitter and LinkedIn.

### Task 11: Batch submissions (15 min each, no follow-up needed)

**Slant:**
- [ ] Go to: https://www.slant.co → search "best break reminder apps for Linux".
- [ ] If the question exists → click **Add option** → add RestifEye.
- [ ] If it doesn't → click **Ask a question** → create it → add RestifEye.

**LibHunt:**
- [ ] Go to: https://www.libhunt.com/ → click **Submit**.
- [ ] Enter: `https://github.com/Xern-AI/RestifEye` → fill in category → submit.

**Awesome lists (GitHub pull requests):**
- [ ] Go to: https://github.com/luong-komorebi/Awesome-Linux-Software → **Fork**.
- [ ] Find the "Health" or "Productivity" section in the README.
- [ ] Add this line:
  ```
  - [RestifEye](https://github.com/Xern-AI/RestifEye) - Break reminders with guided exercises, meeting detection, and screen-time analytics.
  ```
- [ ] Open a pull request.

---

## Platforms that are BLOCKED by your license

| Platform | Why | What to do |
|---|---|---|
| **Flathub** | Requires OSI/FSF license + AI-code policy | Skip |
| **Fedora COPR** | Requires FOSS | Skip — RPM from GitHub Releases works fine |
| **Fedora official repos** | Requires FOSS + Fedora packaging review | Skip |

If users start asking for Flathub/COPR, revisit dual-licensing later.

---

## Progress tracker

Copy this somewhere you can check things off:

```
ASSETS
[x] Logo (docs/assets/icon-512.png)
[x] Text blurbs (in this doc)
[ ] Screenshots (exercise overlay, dashboard, analytics, settings)
[ ] Demo GIF (optional)

WEEK 1
[ ] AppImageHub PR
[ ] AlternativeTo listing
[ ] SourceForge project

WEEK 2
[ ] Reddit r/linux
[ ] Reddit r/Fedora
[ ] Hacker News Show HN
[ ] LinkedIn post
[ ] Twitter post + thread

WEEK 3
[ ] Product Hunt launch
[ ] Slant
[ ] LibHunt
[ ] Awesome-Linux-Software PR

OPTIONAL
[ ] Snap Store
```
