# Global Linux Desktop

 My global scripts for automating a complete Linux desktop setup (Arch/Debian) with interactive profiles.

## Features

- **Fully Automated:** Sets up a complete workstation from a minimal install.
    
- **Interactive TUI:** An easy-to-use menu to select your installation profile.
    
- **Cross-Distro:** Supports both **Arch Linux** and **Debian/Ubuntu**-based systems.
    
- **Modular:** Scripts are broken into logical steps (System, Apps, Terminal, Configs).
    
- **Idempotent:** Safe to re-run (won't reinstall or break existing configs).
    

## Prerequisites

Before you run the script, you'll need:

1. A fresh installation of Arch Linux or a Debian/Ubuntu-based distro.
    
2. The `git` package installed (e.g., `sudo pacman -S git` or `sudo apt install git`).
    
3. An active internet connection.
    

## Usage (Installation)

1. Clone this repository:
    
    Bash
    
    ```
    git clone https://github.com/YOUR_USERNAME/global-linux-desktop.git
    cd global-linux-desktop
    ```
    
2. Make the main script executable:
    
    Bash
    
    ```
    chmod +x install.sh
    ```
    
3. Run the script:
    
    Bash
    
    ```
    ./install.sh
    ```
    
4. Follow the on-screen menu to select your desired profile (Minimal, Work, Gaming, etc.) and let the script run.
    

## Repository Structure

- `install.sh`: The main script (orchestrator) that shows the TUI and runs the modules.
    
- `modules/01-system-setup.sh`: Installs base system packages (`zsh`, `kitty`), `yay`, and `flatpak`.
    
- `modules/02-install-apps.sh`: Installs applications based on the selected profile.
    
- `modules/03-terminal-setup.sh`: Configures Zsh, Oh My Zsh, and essential plugins.
    
- `modules/04-tweaks-and-config.sh`: Applies final tweaks and copies dotfiles.
    
- `config/`: (Optional) Your personal config files (dotfiles) for `kitty`, `fastfetch`, etc., should go here.
    
