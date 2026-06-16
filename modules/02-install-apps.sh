#!/bin/bash
# NOTE: We intentionally do NOT use 'set -e' in this module.
# Installations are handled individually with error tracking so that
# a single package failure doesn't kill the entire setup.
echo "--- Module 2: Application Installation (Profile: $PROFILE) ---"
echo "[*] Distro: $PRETTY_NAME ($DISTRO_ID) | Family: $DISTRO_FAMILY"

# --- Failed Package Tracker ---
declare -a FAILED_PACKAGES=()

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
    it.mijorus.gearlever
    com.github.tchx84.Flatseal
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
# 3D Printing Flatpaks
apps_flatpak_3dprint=(
    com.bambulab.BambuStudio
)

# Native apps
native_minimal_arch=(btop nsnake fastfetch)
native_minimal_debian=(btop nsnake fastfetch)
native_extras_arch=(asciiquarium)
native_extras_debian=(hollywood)
native_3dprint_arch=(orca-slicer-bin)

native_virtualization_arch=(
    virtualbox
    virtualbox-host-dkms
    virtualbox-guest-iso
    qemu-full
    libvirt
    virt-manager
    virt-viewer
    dnsmasq
    vde2
    openbsd-netcat
    swtpm
    edk2-ovmf
)
native_virtualization_debian=(
    virtualbox
    virtualbox-dkms
    qemu-kvm
    libvirt-daemon-system
    libvirt-clients
    bridge-utils
    virtinst
    virt-manager
)

# Gaming — Steam, Lutris, and Heroic native
native_gaming_arch=(
    steam
    lutris
    heroic-games-launcher-bin
    prismlauncher
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
    echo "[*] Installing ${#apps_to_install[@]} native applications (one by one)..."
    printf "  - %s\n" "${apps_to_install[@]}"
    echo ""

    local count=0
    for pkg in "${apps_to_install[@]}"; do
        count=$((count + 1))
        echo "-> [$count/${#apps_to_install[@]}] Installing: $pkg"
        if [ "$DISTRO_FAMILY" == "arch" ]; then
            if ! "$AUR_HELPER" -S --noconfirm --needed "$pkg"; then
                echo "[!] FAILED: $pkg"
                FAILED_PACKAGES+=("$pkg (native)")
            fi
        elif [ "$DISTRO_FAMILY" == "debian" ]; then
            if ! sudo apt-get install -y "$pkg"; then
                echo "[!] FAILED: $pkg"
                FAILED_PACKAGES+=("$pkg (native)")
            fi
        fi
    done
    echo "[+] Native application installation pass complete."
}

# --- Conflict-Safe Optional Installers ---
# These packages are installed separately because they can have dependency
# conflicts on certain distros (e.g., wine variants on CachyOS, byobu for hollywood).

try_install_arch_package() {
    local pkg="$1"
    local reason="$2"
    if [ "$DISTRO_FAMILY" != "arch" ]; then return 0; fi

    if pacman -Qi "$pkg" &>/dev/null; then
        echo "[+] $pkg is already installed."
        return 0
    fi

    echo "[*] Attempting to install optional package: $pkg ($reason)..."
    if "$AUR_HELPER" -S --noconfirm --needed "$pkg"; then
        echo "[+] $pkg installed successfully."
    else
        echo "[!] Warning: Could not install '$pkg' (dependency conflict?). Skipping."
        FAILED_PACKAGES+=("$pkg (optional)")
    fi
}

install_wine_if_needed() {
    if [ "$DISTRO_FAMILY" != "arch" ]; then return 0; fi

    # Check if ANY wine variant is already installed (wine, wine-staging, wine-ge, cachyos-wine, etc.)
    if pacman -Qs "^wine" &>/dev/null; then
        local installed_wine
        installed_wine=$(pacman -Qs "^wine" | head -1 | awk '{print $1}' | sed 's|local/||')
        echo "[+] Wine variant already installed: $installed_wine. Skipping wine-staging."
        return 0
    fi

    echo "[*] No wine installation detected. Installing wine-staging..."
    if "$AUR_HELPER" -S --noconfirm --needed wine-staging; then
        echo "[+] wine-staging installed successfully."
    else
        echo "[!] Warning: Could not install wine-staging. You may need to install a wine variant manually."
        FAILED_PACKAGES+=("wine-staging (optional)")
    fi
}

install_flatpaks() {
    local apps_to_install=("$@")
    if [ ${#apps_to_install[@]} -eq 0 ]; then
        echo "-> No Flatpak applications selected for this profile."
        return
    fi
    echo "[*] Installing ${#apps_to_install[@]} Flatpak applications (one by one)..."
    printf "  - %s\n" "${apps_to_install[@]}"
    echo ""

    local count=0
    for app in "${apps_to_install[@]}"; do
        count=$((count + 1))
        echo "-> [$count/${#apps_to_install[@]}] Installing Flatpak: $app"
        if ! flatpak install -y --noninteractive flathub "$app"; then
            echo "[!] FAILED: $app"
            FAILED_PACKAGES+=("$app (flatpak)")
        fi
    done
    echo "[+] Flatpak installation pass complete."
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

install_antigravity_debian() {
    if ! command -v antigravity &>/dev/null; then
        echo "[*] Installing Antigravity IDE natively (Google repo)..."
        # Add Google's signing key and repo
        wget -qO- https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/google-cloud.gpg 2>/dev/null || true
        echo "deb [signed-by=/usr/share/keyrings/google-cloud.gpg] https://packages.cloud.google.com/apt antigravity-ide main" | sudo tee /etc/apt/sources.list.d/antigravity-ide.list > /dev/null
        sudo apt-get update
        if sudo apt-get install -y antigravity-ide; then
            echo "[+] Antigravity IDE installed natively."
        else
            echo "[!] Could not install Antigravity IDE from repo. You may need to install it manually."
            return 1
        fi
    else
        echo "[+] Antigravity IDE is already installed."
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
            final_native_list=( "${native_minimal_arch[@]}" "${native_extras_arch[@]}" "visual-studio-code-bin" "antigravity-ide" )
        else
            final_native_list=( "${native_minimal_debian[@]}" "${native_extras_debian[@]}" )
            if ! install_vscode_debian; then FAILED_PACKAGES+=("code (VS Code native)"); fi
            if ! install_antigravity_debian; then FAILED_PACKAGES+=("antigravity-ide (Antigravity IDE)"); fi
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
            if ! install_heroic_debian; then FAILED_PACKAGES+=("heroic (Heroic .deb)"); fi
        fi
        ;;
    "3dprint")
        final_flatpak_list=( "${apps_flatpak_minimal[@]}" "${apps_flatpak_3dprint[@]}" )
        if [ "$DISTRO_FAMILY" == "arch" ]; then final_native_list=( "${native_minimal_arch[@]}" "${native_3dprint_arch[@]}" ); else final_native_list=( "${native_minimal_debian[@]}" ); fi
        ;;
    "virtualization")
        final_flatpak_list=( "${apps_flatpak_minimal[@]}" )
        if [ "$DISTRO_FAMILY" == "arch" ]; then
            final_native_list=( "${native_minimal_arch[@]}" "${native_virtualization_arch[@]}" )
        else
            final_native_list=( "${native_minimal_debian[@]}" "${native_virtualization_debian[@]}" )
        fi
        sudo usermod -aG vboxusers "$USER" || true
        sudo usermod -aG libvirt "$USER" || true
        if [ "$DISTRO_FAMILY" == "arch" ]; then
            sudo systemctl enable --now libvirtd.service || true
        else
            sudo systemctl enable --now libvirtd || true
        fi
        ;;
    "full")
        final_flatpak_list=( "${apps_flatpak_minimal[@]}" "${apps_flatpak_work[@]}" "${apps_flatpak_creative[@]}" "${apps_flatpak_gaming[@]}" "${apps_flatpak_3dprint[@]}" )
        if [ "$DISTRO_FAMILY" == "arch" ]; then
            final_native_list=( "${native_minimal_arch[@]}" "${native_extras_arch[@]}" "${native_virtualization_arch[@]}" "${native_gaming_arch[@]}" "${native_3dprint_arch[@]}" "visual-studio-code-bin" "antigravity-ide" )
        else
            final_native_list=( "${native_minimal_debian[@]}" "${native_extras_debian[@]}" "${native_virtualization_debian[@]}" "${native_gaming_debian[@]}" )
            if ! install_vscode_debian; then FAILED_PACKAGES+=("code (VS Code native)"); fi
            if ! install_antigravity_debian; then FAILED_PACKAGES+=("antigravity-ide (Antigravity IDE)"); fi
            if ! install_heroic_debian; then FAILED_PACKAGES+=("heroic (Heroic .deb)"); fi
        fi
        sudo usermod -aG vboxusers "$USER" || true
        sudo usermod -aG libvirt "$USER" || true
        sudo systemctl enable --now libvirtd.service 2>/dev/null || sudo systemctl enable --now libvirtd 2>/dev/null || true
        ;;
    "terminal")
        if [ "$DISTRO_FAMILY" == "arch" ]; then final_native_list=( "${native_minimal_arch[@]}" "${native_extras_arch[@]}" ); else final_native_list=( "${native_minimal_debian[@]}" "${native_extras_debian[@]}" ); fi
        ;;
    "custom")
        # --- Interactive Category Selection ---
        echo ""
        echo "  Select which categories to install:"
        echo "  Press [Enter] for Yes (default) or type 'n' to skip."
        echo ""

        declare -A custom_categories
        for cat_name in "Minimal (base tools)" "Work (VS Code, Antigravity, Brave, Obsidian...)" "Creative (Inkscape, Krita, Discord)" "Gaming (Steam, Lutris, Heroic, Discord)" "3D Printing (Bambu Studio, OrcaSlicer)" "Virtualization (VirtualBox, QEMU, virt-manager)" "Terminal Extras (hollywood, asciiquarium)"; do
            while true; do
                read -rp "    Install $cat_name? [Y/n]: " response
                response="${response,,}"
                if [[ -z "$response" || "$response" == "y" || "$response" == "yes" ]]; then
                    custom_categories["$cat_name"]="yes"
                    echo "      ✓ Will install."
                    break
                elif [[ "$response" == "n" || "$response" == "no" ]]; then
                    custom_categories["$cat_name"]="no"
                    echo "      ✗ Skipping."
                    break
                else
                    echo "      [!] Invalid response. Please enter 'y' or 'n'."
                fi
            done
        done
        echo ""

        # Build lists based on selections
        if [[ "${custom_categories["Minimal (base tools)"]}" == "yes" ]]; then
            if [ "$DISTRO_FAMILY" == "arch" ]; then final_native_list+=( "${native_minimal_arch[@]}" ); else final_native_list+=( "${native_minimal_debian[@]}" ); fi
            final_flatpak_list+=( "${apps_flatpak_minimal[@]}" )
        fi
        if [[ "${custom_categories["Work (VS Code, Antigravity, Brave, Obsidian...)"]}" == "yes" ]]; then
            final_flatpak_list+=( "${apps_flatpak_work[@]}" )
            if [ "$DISTRO_FAMILY" == "arch" ]; then
                final_native_list+=( "visual-studio-code-bin" "antigravity-ide" )
            else
                if ! install_vscode_debian; then FAILED_PACKAGES+=("code (VS Code native)"); fi
                if ! install_antigravity_debian; then FAILED_PACKAGES+=("antigravity-ide (Antigravity IDE)"); fi
            fi
        fi
        if [[ "${custom_categories["Creative (Inkscape, Krita, Discord)"]}" == "yes" ]]; then
            final_flatpak_list+=( "${apps_flatpak_creative[@]}" )
        fi
        if [[ "${custom_categories["Gaming (Steam, Lutris, Heroic, Discord)"]}" == "yes" ]]; then
            final_flatpak_list+=( "${apps_flatpak_gaming[@]}" )
            if [ "$DISTRO_FAMILY" == "arch" ]; then
                final_native_list+=( "${native_gaming_arch[@]}" )
            else
                final_native_list+=( "${native_gaming_debian[@]}" )
                if ! install_heroic_debian; then FAILED_PACKAGES+=("heroic (Heroic .deb)"); fi
            fi
            export CUSTOM_GAMING="yes"
        fi
        if [[ "${custom_categories["3D Printing (Bambu Studio, OrcaSlicer)"]}" == "yes" ]]; then
            final_flatpak_list+=( "${apps_flatpak_3dprint[@]}" )
            if [ "$DISTRO_FAMILY" == "arch" ]; then final_native_list+=( "${native_3dprint_arch[@]}" ); fi
        fi
        if [[ "${custom_categories["Virtualization (VirtualBox, QEMU, virt-manager)"]}" == "yes" ]]; then
            if [ "$DISTRO_FAMILY" == "arch" ]; then
                final_native_list+=( "${native_virtualization_arch[@]}" )
            else
                final_native_list+=( "${native_virtualization_debian[@]}" )
            fi
            sudo usermod -aG vboxusers "$USER" || true
            sudo usermod -aG libvirt "$USER" || true
            sudo systemctl enable --now libvirtd.service 2>/dev/null || sudo systemctl enable --now libvirtd 2>/dev/null || true
        fi
        if [[ "${custom_categories["Terminal Extras (hollywood, asciiquarium)"]}" == "yes" ]]; then
            if [ "$DISTRO_FAMILY" == "arch" ]; then final_native_list+=( "${native_extras_arch[@]}" ); else final_native_list+=( "${native_extras_debian[@]}" ); fi
            export CUSTOM_EXTRAS="yes"
        fi
        ;;
    *)
        echo "[!] Unknown profile '$PROFILE'."
        ;;
esac

# --- 4. Installation Execution ---

# Skip Firefox Flatpak if a native Firefox is already installed
# (common on CachyOS, Manjaro, and other distros that ship Firefox by default).
if command -v firefox &>/dev/null; then
    echo "[+] Native Firefox already installed. Skipping Flatpak version."
    _filtered=()
    for app in "${final_flatpak_list[@]}"; do
        [[ "$app" != "org.mozilla.firefox" ]] && _filtered+=("$app")
    done
    final_flatpak_list=("${_filtered[@]}")
fi

install_flatpaks "${final_flatpak_list[@]}"
install_native_utils "${final_native_list[@]}"

# --- 4b. Optional Packages (conflict-prone) ---
# Installed separately with graceful error handling for distros
# like CachyOS that ship their own wine and have AUR dependency issues.
if [ "$DISTRO_FAMILY" == "arch" ]; then
    # hollywood: fun terminal screensaver (depends on byobu, may fail on some distros)
    case "$PROFILE" in
        work|creative|gaming|full|terminal)
            try_install_arch_package "hollywood" "terminal screensaver"
            ;;
        custom)
            if [[ "${CUSTOM_EXTRAS:-}" == "yes" ]]; then
                try_install_arch_package "hollywood" "terminal screensaver"
            fi
            ;;
    esac

    # wine-staging: only install if no wine variant is already present
    case "$PROFILE" in
        gaming|full)
            install_wine_if_needed
            ;;
        custom)
            if [[ "${CUSTOM_GAMING:-}" == "yes" ]]; then
                install_wine_if_needed
            fi
            ;;
    esac
fi

# --- 5. Flatpak Finalization ---
echo "[*] Updating Flatpak AppStream database..."
flatpak update --appstream || true

# --- 6. Installation Summary ---
if [ ${#FAILED_PACKAGES[@]} -gt 0 ]; then
    echo ""
    echo "  ╔══════════════════════════════════════════════════════════════╗"
    echo "  ║        ⚠  SOME PACKAGES COULD NOT BE INSTALLED  ⚠         ║"
    echo "  ╠══════════════════════════════════════════════════════════════╣"
    for failed_pkg in "${FAILED_PACKAGES[@]}"; do
        printf "  ║  ✗ %-56s ║\n" "$failed_pkg"
    done
    echo "  ╠══════════════════════════════════════════════════════════════╣"
    echo "  ║  Total failed: ${#FAILED_PACKAGES[@]} package(s)                              ║"
    echo "  ║  You can try installing them manually later.                ║"
    echo "  ╚══════════════════════════════════════════════════════════════╝"
    echo ""
else
    echo ""
    echo "[+] All packages installed successfully!"
fi

echo "--- Module 2 Finished ---"
