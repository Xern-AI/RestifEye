# BreakTime

**Break reminders that respect your flow.** A free, open-source break and eye-rest reminder for Linux, by Xernai.

BreakTime nudges you to rest your eyes and move your body at healthy intervals — without being annoying and without breaking on Wayland. It notices when you're in a call and waits. It notices when you already stepped away and credits you the break. It warns you 30 seconds before taking over your screen, and when it does, it shows you one simple exercise to do.

## Why another break app?

Existing options are either unreliable on modern Linux (Wayland) or so pushy that people uninstall them. BreakTime's design rules:

- **Never yank the screen** — a 30-second heads-up notification always comes first.
- **Never interrupt a meeting** — microphone/camera use and Do Not Disturb defer breaks automatically (capped, so it can't be gamed).
- **Never demand a break you already took** — walking away, locking the screen, or suspending counts.
- **Strict when it matters** — snoozing is allowed but budgeted; when the budget runs out, the break happens.

## Features

- Two-tier breaks: short eye breaks (20-20-20 rule) and longer movement breaks, independently configurable
- A random illustrated exercise with each break (eye exercises, stretches, posture resets)
- Automatic screen-time and work-pattern tracking — fully local
- Weekly / monthly / yearly analytics with practical, data-driven advice
- Work hours and quiet hours, so it only runs when you want it to
- Material 3 design, light and dark

## Install

Coming with v1.0: AppImage and RPM downloads from [Releases](../../releases), plus a Fedora COPR repository. Until then, build from source below.

## Building from source

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install/linux) (stable) and the Linux desktop toolchain (`clang`, `cmake`, `ninja-build`, `gtk3-devel` on Fedora).

```sh
flutter pub get
flutter build linux --release
# binary: build/linux/x64/release/bundle/breaktime
```

## Privacy

All data stays on your machine. No accounts, no telemetry, no network calls except an optional weekly update check against GitHub Releases. See [PRIVACY.md](PRIVACY.md).

## Platform support

| Environment | Status |
|---|---|
| Fedora / GNOME (Wayland & X11) | Tier 1 — fully supported |
| KDE Plasma, other X11 desktops | Tier 2 — supported, best-effort |
| wlroots compositors (Sway, Hyprland) | Planned (idle detection needs `ext-idle-notify-v1`) |

Honest note on strict mode: Wayland by design prevents any normal app from truly locking your input. BreakTime's strict mode is an aggressive full-screen takeover with refocus-on-blur plus compliance tracking — not a hard input grab. We'd rather be honest than promise what the platform forbids.

## Contributing

Contributions welcome — see [CONTRIBUTING.md](CONTRIBUTING.md). All commits require DCO sign-off (`git commit -s`).

## License & trademark

Code is licensed under [GPL-3.0](LICENSE). The **BreakTime** and **Xernai** names and logos are trademarks of the project owner and may **not** be used by derivative works or forks without written permission. Forks must use a different name and branding.
