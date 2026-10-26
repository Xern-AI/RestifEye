# RestifEye Privacy Policy

**Everything stays on your machine.**

- RestifEye records activity data (active/idle/locked time slices, break outcomes, exercise history) solely to power your own dashboard, analytics, and advice.
- All data is stored locally in an SQLite database: `~/.local/share/RestifEye/` on Linux, and RestifEye's own app data folder on Windows (`%APPDATA%\RestifEye`, which Windows keeps inside the app's private storage when it is installed from the Microsoft Store). It never leaves your computer.
- On Windows, RestifEye also keeps a plain-text diagnostic log in a `logs` folder next to that database, with the newest seven days kept. It records only what the app itself did (for example "break started"), never what you type or which websites you visit, and it is only sent anywhere if you choose to send it.
- There are **no accounts, no telemetry, no analytics services, and no third-party SDKs**.
- On Linux, the **only** network request the app can make is an optional weekly update check against the public GitHub Releases API (`api.github.com`). It sends no personal data and can be disabled in Settings. On Windows there is no update check; updates come through the Microsoft Store.
- RestifEye checks *whether* your microphone or camera is in use (via PipeWire on Linux, and the microphone and camera privacy records Windows keeps on Windows) to avoid interrupting calls. It cannot and does not access audio or video content.
- **Purchases (Microsoft Store version):** RestifEye is bought through the Microsoft Store, which also runs the free trial, and Microsoft handles the payment under its own privacy statement. RestifEye never sees your payment details or your Microsoft account details; it only asks the Store whether this copy is in its free trial or has been bought, and keeps the Store's last answer locally with your other data so it works offline.
- Deleting your data is as simple as deleting the folder above. On Windows, uninstalling the Store version also removes its data.

The source code is available under the [PolyForm Shield License](LICENSE) — you can verify every claim above by reading it.
