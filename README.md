# Global Linux Desktop

My global scripts for automating a complete Linux desktop setup (Arch/Debian) with interactive profiles.

## Features

- **Fully Automated:** Sets up a complete workstation from a minimal install.
- **Interactive TUI:** An easy-to-use menu to select your installation profile.
- **Cross-Distro:** Supports both **Arch Linux** and **Debian/Ubuntu**-based systems.
- **Smart GPU Detection:** Automatically detects and installs drivers for **NVIDIA (DKMS)**, **AMD**, or **Intel**.
- **Python Developer Ready:** Includes `pipx` for tools and native system libraries (`numpy`, `opencv`) to avoid compilation headaches.
- **Flatpak First:** Prioritizes Flatpak for Gaming (Steam) and proprietary apps to keep the host system clean.
- **Idempotent:** Safe to re-run (won't reinstall or break existing configs).

## Prerequisites

Before you run the script, you'll need:

1. A fresh installation of Arch Linux or a Debian/Ubuntu-based distro.
2. The `git` package installed (e.g., `sudo pacman -S git` or `sudo apt install git`).
3. An active internet connection.

## Usage (Installation)

1. Clone this repository:
    ```bash
    git clone https://github.com/SamuelValleHdz/universal-linux-setup.git
    cd universal-linux-setup
    ```

2. Make the main script executable:
    ```bash
    chmod +x install.sh
    ```

3. Run the script:
    ```bash
    ./install.sh
    ```

4. Follow the on-screen menu to select your desired profile (Minimal, Work, Gaming, etc.) and let the script run.

## Repository Structure

- `install.sh`: The main script (orchestrator) that shows the TUI and runs the modules.
- `modules/01-system-setup.sh`: Installs base system packages, `yay` (Arch), and prepares `flatpak`.
- `modules/01-gpu-setup.sh`: Detects your GPU vendor (NVIDIA/AMD/Intel) and installs the correct drivers automatically.
- `modules/02-install-apps.sh`: Installs applications based on the selected profile (uses Flatpak for Steam/Discord).
- `modules/03-terminal-setup.sh`: Configures Zsh, Oh My Zsh, plugins, and `pipx`.
- `modules/04-tweaks-and-config.sh`: Applies final tweaks, creates aliases (`pipi`, `pythoni`), and sets up the Kitty theme.
- `modules/update-flatpak-aliases.sh`: Generates shell aliases for your Flatpak apps (e.g., `obsidian` instead of `flatpak run md.obsidian.Obsidian`).

## Aliases & Updates

The script automatically sets up an update alias for your convenience:

- **Arch Linux:** Type `syu` or `update` to update system packages, Flatpaks, and regenerate app aliases.
- **Debian/Ubuntu:** Type `update` to do the same.

## Extras

Wallpaper : https://wallhaven.cc/w/p9gr2p
