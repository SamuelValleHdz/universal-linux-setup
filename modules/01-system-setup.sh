#!/bin/bash
# Enable strict mode
set -e

echo "--- Module 1: Base System Setup ---"

# --- System Package Lists ---
pkgs_build_arch=(base-devel)
pkgs_build_debian=(build-essential)

# Base packages
# 'pipx' has been removed from the Arch list as per your change.
pkgs_essentials_arch=(git curl zsh kitty bluez bluez-utils python-pip)
pkgs_essentials_debian=(git curl zsh kitty bluez software-properties-common python3-pip python3-venv pipx)

# --- Native Package Installation ---
echo "[*] Installing essential system packages (incl. zsh, kitty, and pip)..."

if [ "$DISTRO" == "arch" ]; then
    sudo pacman -Syu --noconfirm --needed "${pkgs_build_arch[@]}" "${pkgs_essentials_arch[@]}"
elif [ "$DISTRO" == "debian" ]; then
    sudo apt-get update
    sudo apt-get install -y "${pkgs_build_debian[@]}" "${pkgs_essentials_debian[@]}"
    
    # Add Fastfetch PPA
    echo "[*] Adding Fastfetch PPA for Ubuntu/Debian..."
    sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch
    sudo apt-get update
fi

echo "[+] Essential packages installed."

# --- yay Installation (Arch Only) ---
if [ "$DISTRO" == "arch" ]; then
    if ! command -v yay &> /dev/null; then
        echo "[*] Installing yay..."
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        (cd /tmp/yay && makepkg -si --noconfirm)
        rm -rf /tmp/yay
        echo "[+] yay installed."
    else
        echo "[+] yay is already installed."
    fi
fi

# --- Flatpak Installation & Setup ---
if ! command -v flatpak &> /dev/null; then
    echo "[*] Installing Flatpak..."
    if [ "$DISTRO" == "arch" ]; then
        sudo pacman -S --noconfirm flatpak
    elif [ "$DISTRO" == "debian" ]; then
        sudo apt-get install -y flatpak
    fi
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    echo "[+] Flatpak installed and configured."
else
    echo "[+] Flatpak is already installed."
fi

echo "--- Module 1 Finished ---"