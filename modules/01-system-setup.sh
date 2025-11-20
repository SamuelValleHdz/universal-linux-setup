#!/bin/bash
# Enable strict mode
set -e

echo "--- Module 1: Base System Setup ---"

# --- System Package Lists ---
pkgs_build_arch=(base-devel)
pkgs_build_debian=(build-essential)

# Base packages
pkgs_essentials_arch=(git curl zsh kitty bluez bluez-utils python-pip)
pkgs_essentials_debian=(git curl zsh kitty bluez software-properties-common python3-pip python3-venv pipx)

# --- Repository Configuration ---
if [ "$DISTRO" == "arch" ]; then
    echo "[*] Configuring Arch repositories..."
    if grep -q "#\[multilib\]" /etc/pacman.conf; then
        echo "-> Enabling Multilib repository (required for Steam)..."
        sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
    fi
    sudo pacman -Syy

elif [ "$DISTRO" == "debian" ]; then
    echo "[*] Configuring Ubuntu/Debian repositories..."
    # Enable 'multiverse' (required for Steam)
    sudo add-apt-repository -y multiverse

    # Habilitar arquitectura de 32 bits (Steam la necesita obligatoriamente)
    echo "-> Enabling 32-bit architecture (i386)..."
    sudo dpkg --add-architecture i386
    # ===============================
    
    sudo apt-get update
fi

# --- Native Package Installation ---
echo "[*] Installing essential system packages..."

if [ "$DISTRO" == "arch" ]; then
    sudo pacman -S --noconfirm --needed "${pkgs_build_arch[@]}" "${pkgs_essentials_arch[@]}"
elif [ "$DISTRO" == "debian" ]; then
    sudo apt-get install -y "${pkgs_build_debian[@]}" "${pkgs_essentials_debian[@]}"
    
    echo "[*] Adding Fastfetch PPA..."
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

# --- Flatpak Installation ---
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