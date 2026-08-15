# RestifEye — Capability Sheet

*What the product does and why it's better. Read aloud in interviews, pitches, listings. One page. Not documentation — this is the retrieval index.*

## One-liner

Break reminders for Linux that read the room instead of nagging you.

## 60-second version

RestifEye reminds you to rest your eyes and move, on a schedule that adapts to what you're actually doing. If you're on a call, it waits. If you're watching a film, it holds. If you already got up and walked away, it counts that and doesn't ask again. When a break is genuinely due it warns you thirty seconds ahead, then shows one illustrated exercise to do. It works properly on Wayland, where most break apps quietly stop detecting whether you're at the computer at all. Everything is stored on your machine — no account, no telemetry, no server.

## Feature inventory

*Exhaustive. Nothing here gets pruned for brevity — small features are exactly what gets forgotten.*

**Scheduling that adapts**
- Two independent break cycles — short eye breaks (20-20-20) and longer movement breaks — that merge when they'd otherwise collide within minutes of each other. *Non-trivial: two interleavable cycles sharing one screen, one budget per cycle.*
- Meeting deferral: microphone or camera in use, or Do Not Disturb on, postpones a break — capped at 15 minutes so it can't be gamed. *Non-trivial: camera/mic state read from PipeWire, DND from gsettings; the cap is measured from the immutable cycle due-time, not from the deferral.*
- Media and presentation pause: breaks hold while something on screen must not be interrupted. *Non-trivial: built on idle inhibitors rather than audio — video players, fullscreen browser video, slide tools and games take one, background music does not, so a playlist can't suppress breaks all day. Timers are not reset on resume: two hours of video is still two hours of screen time.*
- Natural-break credit: walking away, locking the screen or suspending counts as the break you were about to be asked for. *Non-trivial: away spans remember whether they were a lock or an idle, and can never be backdated before the last break ended — otherwise sitting out a break gets credited twice.*
- 30-second pre-break warning, always, before anything takes the screen. *Non-trivial: the warning is taken back down by whatever ends it — the break starting, a snooze, a skip, a pause, a film starting, work hours closing, a settings change. It is reconciled against the engine's live state every second rather than fired off events, so it can never be left sitting in your notification tray after the moment it was about has passed.*
- Snooze with a strict budget, tracked separately per break kind. *Non-trivial: one shared counter let a 3-snooze budget stretch to 5 by interleaving the two cycles.*
- Skip with its own budget of consecutive skips, reset by any break actually taken.
- Work hours and work days: it only runs when you want it to, including overnight windows that cross midnight. One button resets the window back to all day. *Non-trivial: a start time equal to the end time is read as "all day", not as a zero-length window, so there is no way to narrow your hours into a state where the app silently stops working and you can't tell why.*
- Timed pause from the dashboard — 30 min / 1 h / 2 h / 3 h / indefinite — on the wall clock, so "2 hours" survives a suspend.
- Crash-safe: the schedule is snapshotted and restored, so a restart doesn't hand you a fresh 20 minutes.

**The break itself**
- 52 illustrated exercises, drawn in code rather than shipped as assets, themed light and dark: 10 for the eyes and 42 for the body, every one with its own looping animation. *Non-trivial: the figures are posed by joint angles, so the same skeleton draws a side stretch and a plank; nothing is a picture file, so it stays crisp at any size and adds nothing to the download.*
- Three intensity tiers with a user ceiling — seated only, standing stretches, or anything you would do at home in your own room (planks, push-ups, skipping, floor work). *Non-trivial: a squat is impossible in an open-plan office, and an overlay suggesting the impossible teaches people to dismiss overlays.*
- "Can't do this one" opts an exercise out permanently and swaps in another.
- Windowed or full-screen breaks, your choice; strict breaks are always full-screen.
- Strict mode with a logged 3-second hold-to-escape, once the snooze budget is gone.
- A break started from the tray ends back in the tray — the window goes back to whatever it was doing.
- Optional sound, one mechanism, one setting.

**The tray icon that reads the day**
- An expressive face whose colour *and* shape track how the day is going: seven moods, from "taking your breaks" to "several breaks skipped". *Non-trivial: colour is never the only signal — every mood changes the eyes or mouth too, for colour-vision deficiency and monochrome tray themes — and the tooltip says the mood in words.*
- Judged on a rolling 2-hour window, not day totals, so a bad morning doesn't colour the icon until midnight and a good afternoon can earn it back.
- Asymmetric hysteresis: praise instantly, warn slowly. A single skipped break never turns the icon red.
- Drawn at runtime at five panel sizes, with a short acknowledgement pulse on change — never an idle animation.
- Full tray menu (Open / Pause / Quit) implemented directly over D-Bus.
- Detects GNOME's missing status area and offers to install the required extension in one click.

**Insight**
- Fully local screen-time and work-pattern tracking, recorded every second.
- Weekly / monthly / yearly analytics: active time, idle, away, at-computer, longest focus stretch, workday span.
- Rule-based advice derived from your own rollups.
- Exercise log, break-compliance history.

**The Linux details nobody else got right**
- Wayland-native idle detection via Mutter's IdleMonitor, with a logind fallback.
- Single-instance: launching again presents the existing window instead of starting a second engine.
- Runs from the tray with autostart on by default — applied exactly once, never re-forced after you opt out.
- Ships as an AppImage with zero extra runtime dependencies (the tray and sound paths are hand-rolled rather than pulling in appindicator or an audio plugin), plus an RPM.
- Optional weekly update check against GitHub Releases. That is the only network call in the app.
- Settings shows the exact version and build you are running, read from the shipped bundle — so a bug report always carries the right version, and the update check compares against what is actually installed rather than a number someone forgot to bump.

## Competitive edge

*Checked against public docs, July 2026. Say "last I checked" when quoting these — they move.*

| | RestifEye | Stretchly | Workrave | Safe Eyes |
|---|---|---|---|---|
| Wayland idle detection | Mutter IdleMonitor + logind fallback | Electron idle; weak on Wayland | X11-era, effectively unsupported | Yes — `ext-idle-notify` (Smart Pause) |
| Waits for meetings | Mic/camera **and** DND, capped at 15 min | Manual postpone; pauses on DND | No | Fullscreen-window rule only |
| Waits for video / presentations | Any app holding an idle inhibitor | No | No | Fullscreen active window |
| Credits a break you already took | Yes — logged as taken (idle, lock, suspend) | No | Idle resets the timer | Smart Pause stops the timer |
| Ambient status without a window | 7-mood expressive tray face | Static icon | Static icon | Static icon |
| Illustrated exercises | 52, 3 intensity tiers | Text ideas | Basic figures | Text instructions |
| Local-only, no telemetry | Yes | Yes | Yes | Yes |
| Runtime dependencies | None (AppImage) | Electron | GTK | Python + GTK |

Honest read: Safe Eyes is the closest competitor and is genuinely good on Wayland idle. The gap is *situational awareness* — it pauses on a fullscreen window; RestifEye reads mic, camera, DND and idle inhibitors, credits breaks you took by walking away, and never resets a timer just because you watched something.

## Numbers

- **186 automated tests**, `flutter analyze --fatal-infos` clean, pure-Dart engine core testable with no compositor, database or window.
- **1 Hz** deterministic engine tick; monotonic clock for all interval maths, wall clock only where wall clock is the right answer.
- **52** exercises across 3 intensity tiers (10 eye, 42 movement); **7** tray moods; **5** rendered icon sizes (22–64 px).
- **2-hour** mood horizon; **3-sample** escalation hysteresis; **15-minute** deferral cap; **30-second** pre-break warning.
- **Zero** network calls except an optional weekly update check. **Zero** runtime dependencies in the AppImage.
- Screen activity recorded at **1-second** resolution, aggregated into daily rollups.

## Hardest problem solved

The app crashed, intermittently, only when a break ended — and only after a change that had nothing obviously to do with crashing.

Two coredumps told the same story: `wl_proxy_get_version`, called from `gdk_wayland_window_get_egl_surface`, from `gdk_cairo_draw_from_gl`, inside GTK's draw handler. GTK was painting the app's GL texture into a window whose Wayland surface had already been destroyed. On Wayland, hiding a window frees that surface immediately — so anything the toolkit still had queued to draw was writing into freed memory.

The change that introduced it was innocuous: a break that started from the tray should end back in the tray, so the window now hides itself when a break finishes. The reason it only crashed *there* is that break end is the one moment where a frame is guaranteed to be in flight — the exercise illustration animates continuously, and dropping full-screen a step earlier adds a resize burst on top. The same hide had existed for months on the "close to tray" path and never crashed once, because an idle app has nothing queued to draw.

The fix was to stop treating the hide as an action and start treating it as a desire: it is held until the renderer reports no scheduled frame, and retried on the next one-second tick if it is not. Crashes dropped from routine to about one a fortnight.

They did not stop. Four weeks later, two more coredumps with identical stacks — and the interesting part is *why the fix was right and still insufficient*. The signal it waited on, `hasScheduledFrame`, reports whether the framework intends to build another frame. But the crash happens two stages further down, in the toolkit's frame clock, drawing a frame the rasteriser had already handed over. The flag goes quiet while that frame is still travelling. No amount of polling helps, because nothing on the framework side can see the toolkit's paint queue at all — the honest conclusion was that the question was unanswerable, not that it had been asked badly.

So the second fix stopped asking. The hide now waits out three consecutive quiet one-second ticks — roughly three seconds, against a pipeline that empties in about two frames — and is never performed on the same tick that decided it. Reading the window plugin's source during that work turned up a second hazard for free: it resizes the window *after* unmapping it, which re-queues toolkit work on something that no longer exists. The same wait defuses that too.

The part worth defending in an interview is the fix that was rejected. There is a provably correct version: unmap from a low-priority idle callback in the C runner, below the toolkit's redraw priority, so queued paints must finish first. It was turned down because it is untestable C whose failure mode — a window that never comes back from the tray — is worse than the once-a-fortnight crash it prevents. Correctness is not the only axis.

The confirming detail: the last break in the database completed at 23:21:56, and the coredump is stamped 23:21:56.

## 10-second answer

I built a break reminder for Linux that actually knows when you're busy — it waits through meetings and films, credits the breaks you already took by walking away, and tells you how your day is going through a face in the system tray.
