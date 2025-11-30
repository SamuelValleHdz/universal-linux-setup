#!/bin/bash
# Enable strict mode
set -e
echo "--- Module 2: Application Installation (Profile: $PROFILE) ---"

# --- 1. Application Lists ---

# (Flatpak Lists - Sin cambios)
apps_flatpak_minimal=(
    org.mozilla.firefox
    org.videolan.VLC
    com.visualstudio.code
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
)
apps_flatpak_gaming=(
    net.lutris.Lutris
    com.heroicgameslauncher.hgl
    org.prismlauncher.PrismLauncher
    com.discordapp.Discord
)

# (Native Lists)
native_minimal_arch=(btop nsnake fastfetch)
native_minimal_debian=(btop nsnake fastfetch)
native_extras_arch=(hollywood asciiquarium)
native_extras_debian=(hollywood)
native_virtualization_arch=(virtualbox virtualbox-host-dkms virtualbox-ext-oracle)
native_virtualization_debian=(virtualbox virtualbox-dkms)

# NEW: Native Gaming (Steam)
native_gaming_arch=(steam)
# ==== CAMBIO AQUÍ ====
# Usamos 'steam-installer' en Ubuntu/Debian para mayor compatibilidad
native_gaming_debian=(steam-installer)
# =====================

# --- 2. Installation Functions ---

install_native_utils() {
    local apps_to_install=("$@")
    if [ ${#apps_to_install[@]} -eq 0 ]; then
        echo "-> No native applications selected for this profile."
        return
    fi
    echo "[*] Installing ${#apps_to_install[@]} native applications..."
    printf "  - %s\n" "${apps_to_install[@]}"
    
    if [ "$DISTRO" == "arch" ]; then
        echo "-> Using yay (Arch)..."
        yay -S --noconfirm --needed "${apps_to_install[@]}"
    elif [ "$DISTRO" == "debian" ]; then
        echo "-> Using apt (Debian/Ubuntu)..."
        sudo apt-get install -y "${apps_to_install[@]}"
    else
        echo "[!] Unsupported distro '$DISTRO' in Module 2."
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

# --- 3. Profile Logic (Non-Interactive) ---
declare -a final_flatpak_list
declare -a final_native_list

echo "-> Processing profile '$PROFILE' for app selection..."
case "$PROFILE" in
    "minimal")
        final_flatpak_list=( "${apps_flatpak_minimal[@]}" )
        if [ "$DISTRO" == "arch" ]; then final_native_list=( "${native_minimal_arch[@]}" ); else final_native_list=( "${native_minimal_debian[@]}" ); fi
        ;;
    "work")
        final_flatpak_list=( "${apps_flatpak_minimal[@]}" "${apps_flatpak_work[@]}" )
        if [ "$DISTRO" == "arch" ]; then final_native_list=( "${native_minimal_arch[@]}" "${native_extras_arch[@]}" ); else final_native_list=( "${native_minimal_debian[@]}" "${native_extras_debian[@]}" ); fi
        ;;
    "creative")
        final_flatpak_list=( "${apps_flatpak_minimal[@]}" "${apps_flatpak_creative[@]}" )
        if [ "$DISTRO" == "arch" ]; then final_native_list=( "${native_minimal_arch[@]}" "${native_extras_arch[@]}" ); else final_native_list=( "${native_minimal_debian[@]}" "${native_extras_debian[@]}" ); fi
        ;;
    "gaming")
        final_flatpak_list=( "${apps_flatpak_minimal[@]}" "${apps_flatpak_gaming[@]}" )
        if [ "$DISTRO" == "arch" ]; then 
            final_native_list=( "${native_minimal_arch[@]}" "${native_extras_arch[@]}" "${native_gaming_arch[@]}" )
        else 
            final_native_list=( "${native_minimal_debian[@]}" "${native_extras_debian[@]}" "${native_gaming_debian[@]}" )
        fi
        ;;
    "virtualization")
        final_flatpak_list=( "${apps_flatpak_minimal[@]}" )
        if [ "$DISTRO" == "arch" ]; then
            final_native_list=( "${native_minimal_arch[@]}" "${native_virtualization_arch[@]}" )
        else
            final_native_list=( "${native_minimal_debian[@]}" "${native_virtualization_debian[@]}" )
        fi
        ;;
    "full")
        final_flatpak_list=( "${apps_flatpak_minimal[@]}" "${apps_flatpak_work[@]}" "${apps_flatpak_creative[@]}" "${apps_flatpak_gaming[@]}" )
        if [ "$DISTRO" == "arch" ]; then
            final_native_list=( "${native_minimal_arch[@]}" "${native_extras_arch[@]}" "${native_virtualization_arch[@]}" "${native_gaming_arch[@]}" )
        else
            final_native_list=( "${native_minimal_debian[@]}" "${native_extras_debian[@]}" "${native_virtualization_debian[@]}" "${native_gaming_debian[@]}" )
        fi
        ;;
    "terminal")
        if [ "$DISTRO" == "arch" ]; then final_native_list=( "${native_minimal_arch[@]}" "${native_extras_arch[@]}" ); else final_native_list=( "${native_minimal_debian[@]}" "${native_extras_debian[@]}" ); fi
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
