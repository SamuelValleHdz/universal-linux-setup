#!/bin/bash
# Enable strict mode
set -e
echo "--- Module 2: Application Installation (Profile: $PROFILE) ---"
echo "[*] Distro: $PRETTY_NAME ($DISTRO_ID) | Family: $DISTRO_FAMILY"

# --- AUR Helper Detection ---
# Module 01 may have installed the AUR helper in a different child process,
# so we re-detect it here to ensure $AUR_HELPER is always set correctly.
if [ "$DISTRO_FAMILY" == "arch" ]; then
    if command -v paru &>/dev/null; then
        AUR_HELPER="paru"
    elif command -v yay &>/dev/null; then
        AUR_HELPER="yay"
    elif command -v pamac &>/dev/null; then
        AUR_HELPER="pamac"
    else
        echo "[!] No AUR helper found. Cannot install AUR packages."
        exit 1
    fi
    echo "[*] Using AUR helper: $AUR_HELPER"
fi

# --- 1. Application Lists ---

# Flatpak apps (distro-agnostic)
apps_flatpak_minimal=(
    org.mozilla.firefox
)
apps_flatpak_work=(
    md.obsidian.Obsidian
    org.onlyoffice.desktopeditors
    com.brave.Browser
    com.spotify.Client
    org.keepassxc.KeePassXC
    org.qbittorrent.qBittorrent
)
apps_flatpak_creative=(
    org.inkscape.Inkscape
    org.kde.krita
    com.discordapp.Discord
)
# Gaming Flatpaks: Discord (Steam, Lutris, and Heroic go as native)
apps_flatpak_gaming=(
    com.discordapp.Discord
)

# Native apps
native_minimal_arch=(btop nsnake fastfetch)
native_minimal_debian=(btop nsnake fastfetch)
native_extras_arch=(hollywood asciiquarium)
native_extras_debian=(hollywood)

native_virtualization_arch=(
    virtualbox
    virtualbox-host-dkms
    virtualbox-guest-iso
)
native_virtualization_debian=(virtualbox virtualbox-dkms)

# Gaming — Steam, Lutris, and Heroic native
native_gaming_arch=(
    steam
    lutris
    heroic-games-launcher-bin
    prismlauncher
    wine-staging
    winetricks
)
# Use 'steam-installer' on Ubuntu/Debian for better i386 compatibility
native_gaming_debian=(steam-installer lutris)

# --- 2. Installation Functions ---

install_native_utils() {
    local apps_to_install=("$@")
    if [ ${#apps_to_install[@]} -eq 0 ]; then
        echo "-> No native applications selected for this profile."
        return
    fi
    echo "[*] Installing ${#apps_to_install[@]} native applications..."
    printf "  - %s\n" "${apps_to_install[@]}"

    if [ "$DISTRO_FAMILY" == "arch" ]; then
        echo "-> Using $AUR_HELPER (Arch)..."
        "$AUR_HELPER" -S --noconfirm --needed "${apps_to_install[@]}"
    elif [ "$DISTRO_FAMILY" == "debian" ]; then
        echo "-> Using apt (Debian/Ubuntu)..."
        sudo apt-get install -y "${apps_to_install[@]}"
    else
        echo "[!] Unsupported distro family '$DISTRO_FAMILY' in Module 2."
    fi
    echo "[+] Native applications installed."
}

install_flatpaks() {
    local apps_to_install=("$@")
    if [ ${#apps_to_install[@]} -eq 0 ]; then
        echo "-> No Flatpak applications selected for this profile."
        return
    fi
    echo "[*] Installing ${#apps_to_install[@]} applications from Flathub..."
    printf "  - %s\n" "${apps_to_install[@]}"

    flatpak install -y --noninteractive flathub "${apps_to_install[@]}"
    echo "[+] Flatpak applications installed."
}

install_vscode_debian() {
    if ! command -v code &>/dev/null; then
        echo "[*] Installing VS Code natively (apt repository)..."
        sudo apt-get install -y wget gpg apt-transport-https
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /usr/share/keyrings/packages.microsoft.gpg > /dev/null
        echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y code
        echo "[+] VS Code installed natively."
    else
        echo "[+] VS Code is already installed."
    fi
}

install_heroic_debian() {
    if ! command -v heroic &>/dev/null; then
        echo "[*] Installing Heroic Games Launcher natively..."
        # Get latest release deb url from GitHub releases
        local deb_url
        deb_url=$(curl -s https://api.github.com/repos/Heroic-Games-Launcher/HeroicGamesLauncher/releases/latest | grep -oP '"browser_download_url": "\K[^"]+\.deb' | head -n 1)
        if [ -n "$deb_url" ]; then
            echo "-> Downloading $deb_url..."
            wget -O /tmp/heroic.deb "$deb_url"
            sudo apt-get install -y /tmp/heroic.deb
            rm -f /tmp/heroic.deb
            echo "[+] Heroic Games Launcher installed natively."
        else
            echo "[!] Could not fetch Heroic Games Launcher .deb URL."
        fi
    else
        echo "[+] Heroic Games Launcher is already installed."
    fi
}

# --- 3. Profile Logic ---
declare -a final_flatpak_list
declare -a final_native_list

echo "-> Processing profile '$PROFILE' for app selection..."
case "$PROFILE" in
    "minimal")
        final_flatpak_list=( "${apps_flatpak_minimal[@]}" )
        if [ "$DISTRO_FAMILY" == "arch" ]; then final_native_list=( "${native_minimal_arch[@]}" ); else final_native_list=( "${native_minimal_debian[@]}" ); fi
        ;;
    "work")
        final_flatpak_list=( "${apps_flatpak_minimal[@]}" "${apps_flatpak_work[@]}" )
        if [ "$DISTRO_FAMILY" == "arch" ]; then
            final_native_list=( "${native_minimal_arch[@]}" "${native_extras_arch[@]}" "visual-studio-code-bin" )
        else
            final_native_list=( "${native_minimal_debian[@]}" "${native_extras_debian[@]}" )
            install_vscode_debian
        fi
        ;;
    "creative")
        final_flatpak_list=( "${apps_flatpak_minimal[@]}" "${apps_flatpak_creative[@]}" )
        if [ "$DISTRO_FAMILY" == "arch" ]; then final_native_list=( "${native_minimal_arch[@]}" "${native_extras_arch[@]}" ); else final_native_list=( "${native_minimal_debian[@]}" "${native_extras_debian[@]}" ); fi
        ;;
    "gaming")
        final_flatpak_list=( "${apps_flatpak_minimal[@]}" "${apps_flatpak_gaming[@]}" )
        if [ "$DISTRO_FAMILY" == "arch" ]; then
            final_native_list=( "${native_minimal_arch[@]}" "${native_extras_arch[@]}" "${native_gaming_arch[@]}" )
        else
            final_native_list=( "${native_minimal_debian[@]}" "${native_extras_debian[@]}" "${native_gaming_debian[@]}" )
            install_heroic_debian
        fi
        ;;
    "virtualization")
        final_flatpak_list=( "${apps_flatpak_minimal[@]}" )
        if [ "$DISTRO_FAMILY" == "arch" ]; then
            final_native_list=( "${native_minimal_arch[@]}" "${native_virtualization_arch[@]}" )
        else
            final_native_list=( "${native_minimal_debian[@]}" "${native_virtualization_debian[@]}" )
        fi
        sudo usermod -aG vboxusers "$USER"
        ;;
    "full")
        final_flatpak_list=( "${apps_flatpak_minimal[@]}" "${apps_flatpak_work[@]}" "${apps_flatpak_creative[@]}" "${apps_flatpak_gaming[@]}" )
        if [ "$DISTRO_FAMILY" == "arch" ]; then
            final_native_list=( "${native_minimal_arch[@]}" "${native_extras_arch[@]}" "${native_virtualization_arch[@]}" "${native_gaming_arch[@]}" "visual-studio-code-bin" )
        else
            final_native_list=( "${native_minimal_debian[@]}" "${native_extras_debian[@]}" "${native_virtualization_debian[@]}" "${native_gaming_debian[@]}" )
            install_vscode_debian
            install_heroic_debian
        fi
        ;;
    "terminal")
        if [ "$DISTRO_FAMILY" == "arch" ]; then final_native_list=( "${native_minimal_arch[@]}" "${native_extras_arch[@]}" ); else final_native_list=( "${native_minimal_debian[@]}" "${native_extras_debian[@]}" ); fi
        ;;
    *)
        echo "[!] Unknown profile '$PROFILE'."
        ;;
esac

# --- 4. Installation Execution ---
install_flatpaks "${final_flatpak_list[@]}"
install_native_utils "${final_native_list[@]}"

# --- 5. Flatpak Finalization ---
echo "[*] Updating Flatpak AppStream database..."
flatpak update --appstream

echo "--- Module 2 Finished ---"
