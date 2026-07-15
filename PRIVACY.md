# RestifEye Privacy Policy

**Everything stays on your machine.**

- RestifEye records activity data (active/idle/locked time slices, break outcomes, exercise history) solely to power your own dashboard, analytics, and advice.
- All data is stored locally in an SQLite database at `~/.local/share/RestifEye/`. It never leaves your computer.
- There are **no accounts, no telemetry, no analytics services, and no third-party SDKs**.
- The **only** network request the app can make is an optional weekly update check against the public GitHub Releases API (`api.github.com`). It sends no personal data and can be disabled in Settings.
- RestifEye checks *whether* your microphone or camera is in use (via PipeWire) to avoid interrupting calls. It cannot and does not access audio or video content.
- Deleting your data is as simple as deleting the folder above, or using *Settings → Reset all data*.

The source code is GPL-3.0 licensed — you can verify every claim above by reading it.
