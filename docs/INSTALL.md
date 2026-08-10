# Installing RestifEye on Linux

RestifEye is available in three formats. Pick the one that matches your system — if you're not sure, start with the AppImage (it works everywhere).

---

## Which format should I pick?

| Your Linux distribution | Recommended format |
|---|---|
| **Ubuntu**, Debian, Pop!\_OS, Linux Mint, elementary OS, Zorin OS | `.deb` package |
| **Fedora**, RHEL, CentOS Stream, Rocky Linux, AlmaLinux, openSUSE | `.rpm` package |
| Anything else, or you're not sure | AppImage |

> **Quick rule of thumb:** If your system has `apt`, use `.deb`. If it has `dnf` or `zypper`, use `.rpm`. If neither, or you just want something that runs immediately with no installation, use the AppImage.

---

## Where to download

Go to the [RestifEye website](https://restifeye.vercel.app/#download) and download the file matching your format.

| Format | Filename pattern |
|---|---|
| AppImage | `RestifEye-<version>-x86_64.AppImage` |
| DEB | `restifeye_<version>_amd64.deb` |
| RPM | `RestifEye-<version>.x86_64.rpm` |

---

## Option 1: AppImage (any Linux distribution)

The AppImage is a single file that contains everything RestifEye needs. No installation, no root password, no dependencies.

### Steps

1. **Download** the `.AppImage` file from the website.

2. **Open a terminal** in the folder where you downloaded it.
   - On most desktops: right-click inside the folder → "Open in Terminal" or "Open Terminal Here".

3. **Make it executable** (this tells Linux it's allowed to run):
   ```sh
   chmod +x RestifEye-*-x86_64.AppImage
   ```

4. **Run it:**
   ```sh
   ./RestifEye-*-x86_64.AppImage
   ```

That's it — RestifEye is running. You can also double-click the file from your file manager after step 3.

### Optional: Add to your app menu

The AppImage runs from wherever you put it, but it won't show up in your application menu by default. To make it feel like a "real" installed app:

1. Move the AppImage somewhere permanent:
   ```sh
   mkdir -p ~/.local/bin
   mv RestifEye-*-x86_64.AppImage ~/.local/bin/RestifEye.AppImage
   ```

2. Create a desktop entry:
   ```sh
   mkdir -p ~/.local/share/applications
   cat > ~/.local/share/applications/com.xernai.restifeye.desktop << 'EOF'
   [Desktop Entry]
   Type=Application
   Name=RestifEye
   GenericName=Break Reminder
   Comment=Break reminders that respect your flow
   Exec=RestifEye.AppImage
   Icon=com.xernai.restifeye
   Terminal=false
   Categories=Utility;Accessibility;
   Keywords=break;eyes;health;posture;screen time;wellbeing;
   StartupWMClass=com.xernai.restifeye
   EOF
   ```

3. Update your desktop database:
   ```sh
   update-desktop-database ~/.local/share/applications/ 2>/dev/null || true
   ```

### Uninstalling the AppImage

Delete the file and the desktop entry (if you created one):

```sh
rm ~/.local/bin/RestifEye.AppImage
rm ~/.local/share/applications/com.xernai.restifeye.desktop
```

---

## Option 2: DEB package (Ubuntu, Debian, Pop!\_OS, Linux Mint)

The `.deb` package installs RestifEye system-wide with proper desktop integration — it shows up in your app menu, has an icon, and can be managed with your package manager.

### Steps

1. **Download** the `.deb` file from the website.

2. **Open a terminal** in the folder where you downloaded it.

3. **Install it:**
   ```sh
   sudo apt install ./restifeye_*_amd64.deb
   ```
   This will ask for your password. Type it (it won't show characters — that's normal) and press Enter.

   > **Note:** The `./` at the start is important — it tells `apt` to install from a local file, not search online repositories.

   If you see a message about missing dependencies, `apt` will try to install them automatically. If that fails:
   ```sh
   sudo apt --fix-broken install
   ```

4. **Verify it installed:**
   ```sh
   RestifEye --help
   ```
   Or search for "RestifEye" in your application menu.

5. **Launch:** Find "RestifEye" in your app menu, or run:
   ```sh
   RestifEye
   ```

### Uninstalling

```sh
sudo apt remove restifeye
```

---

## Option 3: RPM package (Fedora, RHEL, openSUSE)

The `.rpm` package works like the `.deb` but for RPM-based distributions.

### Steps

1. **Download** the `.rpm` file from the website.

2. **Open a terminal** in the folder where you downloaded it.

3. **Install it:**

   **Fedora / RHEL / CentOS Stream / Rocky Linux / AlmaLinux:**
   ```sh
   sudo dnf install ./RestifEye-*.rpm
   ```

   **openSUSE:**
   ```sh
   sudo zypper install ./RestifEye-*.rpm
   ```

   This will ask for your password. Type it and press Enter.

4. **Verify it installed:**
   ```sh
   RestifEye --help
   ```
   Or search for "RestifEye" in your application menu.

5. **Launch:** Find "RestifEye" in your app menu, or run:
   ```sh
   RestifEye
   ```

### Uninstalling

**Fedora / RHEL:**
```sh
sudo dnf remove RestifEye
```

**openSUSE:**
```sh
sudo zypper remove RestifEye
```

---

## After installing

### GNOME tray icon

RestifEye uses a system tray icon to show its status and let you pause/quit without opening the window. **GNOME does not show tray icons by default.** You need one extra step:

1. Install the [AppIndicator extension](https://extensions.gnome.org/extension/615/appindicator-support/):
   - Open the link in Firefox or Chrome.
   - Toggle the switch to "ON".
   - If prompted, install the browser extension first.

   **Or from the command line (Fedora):**
   ```sh
   sudo dnf install gnome-shell-extension-appindicator
   ```

   **Ubuntu:**
   ```sh
   sudo apt install gnome-shell-extension-appindicator
   ```

2. Log out and log back in (or press Alt+F2, type `r`, press Enter on X11).

3. The RestifEye tray icon should now appear in your top panel.

> **KDE Plasma, XFCE, Cinnamon, MATE, Budgie:** Tray icons work out of the box — no extension needed.

### Autostart

RestifEye starts automatically when you log in. If you don't want this, you can toggle it off in **RestifEye → Settings → Start at login**.

---

## Troubleshooting

### "Permission denied" when running the AppImage
You forgot to make it executable:
```sh
chmod +x RestifEye-*-x86_64.AppImage
```

### "No such file or directory" when installing .deb or .rpm
Make sure you're in the same folder as the downloaded file. Check with:
```sh
ls -la *.deb    # or *.rpm
```
If nothing shows up, you're in the wrong folder. Navigate to your Downloads folder:
```sh
cd ~/Downloads
```

### The app runs but has no tray icon (GNOME)
See the [GNOME tray icon](#gnome-tray-icon) section above.

### "libgtk-3.so: cannot open shared object file"
You're missing the GTK 3 library. Install it:
```sh
# Fedora
sudo dnf install gtk3

# Ubuntu/Debian
sudo apt install libgtk-3-0
```

### The app doesn't appear in my application menu after RPM/DEB install
Try refreshing the desktop database:
```sh
sudo update-desktop-database /usr/share/applications/
```
Then log out and log back in.

### How do I check which version I have?
Open RestifEye → Settings. The version is shown at the bottom.

---

## Getting help

For bug reports or questions, email [xernaitech@gmail.com](mailto:xernaitech@gmail.com).
