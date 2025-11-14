Global Linux Desktop

    My global scripts for automating a complete Linux desktop setup (Arch/Debian) with interactive profiles.

Features

    Fully Automated: Sets up a complete workstation from a minimal install.

    Interactive TUI: An easy-to-use menu to select your installation profile.

    Cross-Distro: Supports both Arch Linux and Debian/Ubuntu-based systems.

    Modular: Scripts are broken into logical steps (System, Apps, Terminal, Configs).

    Idempotent: Safe to re-run (won't reinstall or break existing configs).

Prerequisites

Before you run the script, you'll need:

    A fresh installation of Arch Linux or a Debian/Ubuntu-based distro.

    The git package installed (e.g., sudo pacman -S git or sudo apt install git).

    An active internet connection.

Usage (Installation)

    Clone this repository:
    Bash

git clone https://github.com/SamuelValleHdz/universal-linux-setup.git
cd global-linux-desktop

Make the main script executable:
Bash

chmod +x install.sh

Run the script:
Bash

./install.sh

Follow the on-screen menu to select your desired profile (Minimal, Work, Gaming, etc.) and let the script run.    
