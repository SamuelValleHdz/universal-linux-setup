#!/bin/bash
# Enable strict mode
set -e

echo "--- Module 1: Base System Setup ---"
echo "[*] Distro: $PRETTY_NAME ($DISTRO_ID) | Family: $DISTRO_FAMILY"

# --- System Package Lists ---
pkgs_build_arch=(base-devel)
pkgs_build_debian=(build-essential)

# Base packages — pciutils for hardware detection
pkgs_essentials_arch=(git curl wget zsh kitty bluez bluez-utils python-pip python-pipx pciutils)
pkgs_essentials_debian=(git curl wget zsh kitty bluez software-properties-common python3-pip python3-venv pipx pciutils)

# --- Repository Configuration ---
if [ "$DISTRO_FAMILY" == "arch" ]; then
    echo "[*] Configuring Arch-based repositories..."
    # Guard: only enable multilib if it is actually commented out.
    # Manjaro and CachyOS ship with multilib already active.
    if grep -q "^#\[multilib\]" /etc/pacman.conf; then
        echo "-> Enabling Multilib repository (required for Steam/Wine)..."
        sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
        echo "[+] Multilib enabled."
    else
        echo "[+] Multilib already active. Skipping."
    fi
    sudo pacman -Syy

elif [ "$DISTRO_FAMILY" == "debian" ]; then
    echo "[*] Configuring Debian-based repositories..."
    # 'multiverse' is Ubuntu-specific. Mint and pure Debian don't have it.
    if [ "$DISTRO_ID" == "ubuntu" ]; then
        echo "-> Adding Ubuntu multiverse repo..."
        sudo add-apt-repository -y multiverse
    fi
    echo "-> Enabling 32-bit architecture (i386)..."
    sudo dpkg --add-architecture i386
    sudo apt-get update
fi

# --- Native Package Installation ---
echo "[*] Installing essential system packages..."

if [ "$DISTRO_FAMILY" == "arch" ]; then
    sudo pacman -S --noconfirm --needed "${pkgs_build_arch[@]}" "${pkgs_essentials_arch[@]}"
elif [ "$DISTRO_FAMILY" == "debian" ]; then
    sudo apt-get install -y "${pkgs_build_debian[@]}" "${pkgs_essentials_debian[@]}"
fi

echo "[+] Essential packages installed."

# --- Fastfetch Installation (Debian-based) ---
# Ubuntu can use a PPA; Mint and pure Debian don't support Ubuntu PPAs,
# so we download the .deb directly from GitHub Releases instead.
if [ "$DISTRO_FAMILY" == "debian" ]; then
    if command -v fastfetch &>/dev/null; then
        echo "[+] Fastfetch is already installed."
    elif [ "$DISTRO_ID" == "ubuntu" ]; then
        echo "[*] Adding Fastfetch PPA (Ubuntu)..."
        sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch
        sudo apt-get update
        sudo apt-get install -y fastfetch
    else
        echo "[*] Installing Fastfetch from GitHub Releases ($DISTRO_ID)..."
        FASTFETCH_DEB=$(curl -s https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest \
            | grep "browser_download_url.*linux-amd64\.deb\"" \
            | cut -d '"' -f 4 | head -1)
        if [ -n "$FASTFETCH_DEB" ]; then
            wget -q "$FASTFETCH_DEB" -O /tmp/fastfetch.deb
            sudo dpkg -i /tmp/fastfetch.deb
            rm -f /tmp/fastfetch.deb
            echo "[+] Fastfetch installed from GitHub Releases."
        else
            echo "[!] Warning: Could not resolve fastfetch release URL. Skipping."
        fi
    fi
fi

# --- AUR Helper Setup (Arch-based only) ---
# Priority: paru > yay > pamac.
# Only install yay automatically on vanilla Arch. On Manjaro/CachyOS,
# the user likely already has an AUR helper — we respect that choice.
if [ "$DISTRO_FAMILY" == "arch" ]; then
    export AUR_HELPER=""

    if command -v paru &>/dev/null; then
        export AUR_HELPER="paru"
        echo "[+] AUR helper detected: paru"
    elif command -v yay &>/dev/null; then
        export AUR_HELPER="yay"
        echo "[+] AUR helper detected: yay"
    elif command -v pamac &>/dev/null; then
        export AUR_HELPER="pamac"
        echo "[+] AUR helper detected: pamac"
    else
        if [ "$DISTRO_ID" == "arch" ]; then
            echo "[*] No AUR helper found on vanilla Arch. Installing yay..."
            git clone https://aur.archlinux.org/yay.git /tmp/yay
            (cd /tmp/yay && makepkg -si --noconfirm)
            rm -rf /tmp/yay
            export AUR_HELPER="yay"
            echo "[+] yay installed."
        else
            echo "[!] No AUR helper found on $DISTRO_ID."
            echo "    Please install paru or yay, then re-run this script."
            exit 1
        fi
    fi
fi

# --- Flatpak Installation ---
if ! command -v flatpak &>/dev/null; then
    echo "[*] Installing Flatpak..."
    if [ "$DISTRO_FAMILY" == "arch" ]; then
        sudo pacman -S --noconfirm flatpak
    elif [ "$DISTRO_FAMILY" == "debian" ]; then
        sudo apt-get install -y flatpak
    fi
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    echo "[+] Flatpak installed and configured."
else
    echo "[+] Flatpak is already installed."
fi

echo "--- Module 1 Finished ---"