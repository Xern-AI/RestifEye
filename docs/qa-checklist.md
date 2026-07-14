# Pre-release QA checklist

Run on: Fedora GNOME Wayland (Tier 1), Fedora KDE, any X11 session.
Use dev mode for timing checks: `BREAKTIME_DEV=1 flutter run -d linux`.
Dev mode: eye breaks every 1 min, movement breaks every 6 min.

## Round-2 regressions (verify these first)
- [ ] **Sit out a whole movement break** (walk away, don't touch the keyboard
      for its full length) → on return the overlay is gone, the window is
      back to normal size **with its title bar, and closes/quits normally**.
      This is the bug that trapped the app full-screen and unquittable.
- [ ] Sitting out a break is counted **once** — not as a completed break *and*
      an away credit (check Analytics "breaks taken" doesn't jump by 2)
- [ ] **Restart the app mid-cycle**, then wait for the next break: the
      notification **has a Snooze button** and the break is *not* strict
- [ ] `Esc` leaves full-screen when no break is running; `Ctrl+Q` always quits
- [ ] Pause during a break → the break ends and the window is released
- [ ] Eye-break notification appears on **every** cycle (was silently swallowed
      after the first orphaned notification)
- [ ] Only ever one BreakTime notification on screen at a time (no stacking)

## Sounds
- [ ] Warning, break start and break end each make a sound
- [ ] Settings → Sounds off → silence, and it survives a restart
- [ ] On a machine with no `canberra-gtk-play`/`paplay`/`pw-play`: app still
      runs, just silently

## Pause
- [ ] Dashboard → Pause breaks → 30 min → card counts down
- [ ] It **auto-resumes** when the timer runs out, untouched
- [ ] A timed pause survives an app restart; an expired one does not
- [ ] "Until I resume" pauses indefinitely; Resume brings breaks back

## Tray (GNOME needs a shell extension — there is no other way in)
- [ ] With the AppIndicator extension **disabled**: Settings → Tray icon names
      the exact extension and offers Enable
- [ ] Clicking Enable makes the icon appear top-right next to battery/wi-fi,
      with no terminal and no logout
- [ ] Hovering the icon says "BreakTime"
- [ ] With no tray available, closing the window still tells you how to get
      the app back

## Break flow
- [x] Pre-break notification appears with Start now + Snooze + Skip actions
- [x] Notification Snooze postpones; Start now opens the overlay immediately
- [x] Notification Skip cancels the cycle; after the skip budget (default 2
      in a row) the Skip action disappears until a break is completed
- [x] Overlay has no Snooze button (snoozing is notification-only)
- [x] Settings → "Full-screen breaks" off → break opens as a normal window;
      strict breaks still take the full screen
- [x] Overlay goes fullscreen + always-on-top on break start
- [x] Exercise name, animation, and steps render; countdown ring progresses
- [x] Snooze button shows remaining budget and decrements per use
- [x] After budget exhausted: no snooze button, overlay is strict
- [ ] Strict overlay refocuses when clicking another window (best-effort)
- [x] Hold-to-skip requires a full 3-second hold; short press does nothing
- [x] "Can't do this exercise" swaps the exercise and never shows it again
- [x] Break completes on its own and overlay closes; window restores

## Situation awareness
- [ ] Start a mic call (any app) → due break defers; ends → short re-warn
- [ ] Enable GNOME Do Not Disturb → break defers
- [ ] Deferral cap: stay "busy" >15 min → break forces through
- [ ] Lock screen ≥ long-break length → long break credited on unlock
- [ ] Walk away (no lock) ≥ 2 min → micro break credited on return
- [ ] Suspend/resume → credited, timers sane afterwards
- [ ] Outside configured work hours → engine paused; resumes at window start

## Tracking & analytics
- [x] Dashboard countdown ticks; screen time grows during use
- [x] Next day: analytics shows yesterday's rollup; advice updates
- [ ] Data lives in ~/.local/share/breaktime/ and nowhere else
- [ ] Dashboard shows active / at-computer / idle / away, and they add up
- [ ] Idle time grows when you stop typing but stay at the machine;
      away time grows when you lock the screen
- [ ] Upgrading over an existing database keeps old history (schema v1 → v2)

## App behavior
- [x] Launching from the app drawer while running presents the existing
      window — exactly one process, one overlay, one notification
- [ ] Window close hides to background; engine keeps running; a one-time
      "still running" notification appears on first hide
- [ ] Tray icon visible (KDE/XFCE natively; GNOME needs the AppIndicator
      extension); menu Open / Pause / Quit all work; Pause stays in sync
      with the Settings toggle
- [x] Dashboard shows the long-break countdown as the secondary line
- [ ] First run creates ~/.config/autostart entry automatically; disabling
      the Settings toggle removes it and it stays off after restart
- [x] Relaunch mid-cycle restores timer state (snapshot)
- [x] Settings changes apply immediately and survive restart
- [ ] Autostart toggle creates/removes ~/.config/autostart entry
- [x] Onboarding shows once; Skip works
- [ ] Light + dark theme both render correctly

## Packaging
- [ ] AppImage launches on a clean Fedora VM (no Flutter installed)
- [ ] RPM installs; app appears in the grid with icon; `breaktime` on PATH
- [ ] `appstreamcli validate` passes on the metainfo
- [ ] No network traffic except the update check (verify with a monitor)
