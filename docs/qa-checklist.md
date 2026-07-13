# Pre-release QA checklist

Run on: Fedora GNOME Wayland (Tier 1), Fedora KDE, any X11 session.
Use dev mode for timing checks: `BREAKTIME_DEV=1 flutter run -d linux`.

## Break flow
- [ ] Pre-break notification appears with Start now + Snooze + Skip actions
- [ ] Notification Snooze postpones; Start now opens the overlay immediately
- [ ] Notification Skip cancels the cycle; after the skip budget (default 2
      in a row) the Skip action disappears until a break is completed
- [ ] Overlay has no Snooze button (snoozing is notification-only)
- [ ] Settings → "Full-screen breaks" off → break opens as a normal window;
      strict breaks still take the full screen
- [x] Overlay goes fullscreen + always-on-top on break start
- [x] Exercise name, animation, and steps render; countdown ring progresses
- [x] Snooze button shows remaining budget and decrements per use
- [ ] After budget exhausted: no snooze button, overlay is strict
- [ ] Strict overlay refocuses when clicking another window (best-effort)
- [x] Hold-to-skip requires a full 3-second hold; short press does nothing
- [ ] "Can't do this one" swaps the exercise and never shows it again
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
- [ ] Dashboard countdown ticks; screen time grows during use
- [ ] Next day: analytics shows yesterday's rollup; advice updates
- [ ] Data lives in ~/.local/share/breaktime/ and nowhere else

## App behavior
- [ ] Launching from the app drawer while running presents the existing
      window — exactly one process, one overlay, one notification
- [ ] Window close hides to background; engine keeps running; a one-time
      "still running" notification appears on first hide
- [ ] Tray icon visible (KDE/XFCE natively; GNOME needs the AppIndicator
      extension); menu Open / Pause / Quit all work; Pause stays in sync
      with the Settings toggle
- [ ] Dashboard shows the long-break countdown as the secondary line
- [ ] First run creates ~/.config/autostart entry automatically; disabling
      the Settings toggle removes it and it stays off after restart
- [ ] Relaunch mid-cycle restores timer state (snapshot)
- [ ] Settings changes apply immediately and survive restart
- [ ] Autostart toggle creates/removes ~/.config/autostart entry
- [ ] Onboarding shows once; Skip works
- [ ] Light + dark theme both render correctly

## Packaging
- [ ] AppImage launches on a clean Fedora VM (no Flutter installed)
- [ ] RPM installs; app appears in the grid with icon; `breaktime` on PATH
- [ ] `appstreamcli validate` passes on the metainfo
- [ ] No network traffic except the update check (verify with a monitor)
