# Contributing to RestifEye

Thanks for your interest! Contributions are welcome under the rules below.

## Developer Certificate of Origin (required)

Every commit must be signed off:

```sh
git commit -s
```

This adds a `Signed-off-by:` line certifying the [Developer Certificate of Origin](https://developercertificate.org/): that you wrote the change or otherwise have the right to submit it under the project's license, and that you understand the project owner retains the right to dual-license the codebase (this is what allows the project to fund itself through paid builds on other platforms while the Linux version stays free and GPL). **Pull requests without sign-off on every commit will not be merged.**

## Ground rules

- **Small, focused PRs.** One concern per pull request.
- **Tests required** for engine, data, and service logic. UI changes should include widget tests where behavior changed.
- **CI must be green**: `dart format --set-exit-if-changed .`, `flutter analyze`, `flutter test`.
- **Architecture boundaries are enforced in review:**
  - `lib/core/` is pure Dart — no Flutter, no D-Bus, no I/O imports.
  - Platform integrations live behind the interfaces in `lib/platform/interfaces/` — the UI and engine never call D-Bus directly.
  - Viewmodels own state; widgets stay dumb.
- **Keep files small.** Split by responsibility rather than growing a file past ~300 lines.

## Development

```sh
flutter pub get
flutter test          # unit + widget tests, no native toolchain needed
flutter run -d linux  # needs clang/cmake/ninja/gtk3-devel
```

A dev mode with accelerated timers and fake system signals is available for exercising break flows without waiting real intervals (see `lib/platform/fake/`).

## Reporting bugs

Please include: distro + version, desktop environment, session type (`echo $XDG_SESSION_TYPE`), app version, and reproduction steps.
