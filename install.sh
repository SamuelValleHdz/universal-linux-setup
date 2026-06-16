#!/bin/bash
# Enable strict mode: if a command fails, the script will exit.
set -e

# --- Colors and Styles ---
NC='\033[0m'
BOLD='\033[1m'
ITALIC='\033[3m'
RED='\033[38;5;203m'
GREEN='\033[38;5;84m'
YELLOW='\033[38;5;221m'
BLUE='\033[38;5;39m'
PURPLE='\033[38;5;141m'
CYAN='\033[38;5;51m'
PINK='\033[38;5;205m'
ORANGE='\033[38;5;208m'

# Export colors for sub-scripts
export NC BOLD ITALIC RED GREEN YELLOW BLUE PURPLE CYAN PINK ORANGE

# --- Logging Helpers ---
log_info() {
    echo -e "  ${BLUE}[*]${NC} $1"
}
log_success() {
    echo -e "  ${GREEN}[+]${NC} $1"
}
log_warn() {
    echo -e "  ${YELLOW}[!]${NC} $1"
}
log_error() {
    echo -e "  ${RED}[!]${NC} $1"
}
log_step() {
    echo -e "  ${CYAN}[>]${NC} $1"
}

export -f log_info log_success log_warn log_error log_step

# --- 0. Argument Parsing ---
# Supports --skip-* flags to bypass individual modules without the TUI.
SKIP_MODULES=()
for arg in "$@"; do
    case $arg in
        --skip-system)   SKIP_MODULES+=("01-system-setup.sh") ;;
        --skip-apps)     SKIP_MODULES+=("02-install-apps.sh") ;;
        --skip-terminal) SKIP_MODULES+=("03-terminal-setup.sh") ;;
        --skip-tweaks)   SKIP_MODULES+=("04-tweaks-and-config.sh") ;;
        --help|-h)
            echo "Usage: ./install.sh [options]"
            echo ""
            echo "Options:"
            echo "  --skip-system    Skip base system setup (01)"
            echo "  --skip-apps      Skip application installation (02)"
            echo "  --skip-terminal  Skip terminal & shell setup (03)"
            echo "  --skip-tweaks    Skip tweaks & dotfiles (04)"
            echo "  --help           Show this help message"
            exit 0
            ;;
    esac
done

# --- 1. Distro Detection ---
# Read /etc/os-release for granular distro info instead of just checking
# which package manager is present. This correctly handles Manjaro, CachyOS,
# Linux Mint, and other derivatives that behave differently from their base distro.
if [ ! -f /etc/os-release ]; then
    log_error "Cannot detect distro: /etc/os-release not found. Exiting."
    exit 1
fi

# shellcheck source=/dev/null
source /etc/os-release
export DISTRO_ID="${ID:-unknown}"
export DISTRO_ID_LIKE="${ID_LIKE:-}"

log_info "Detected distribution: ${GREEN}$PRETTY_NAME${NC} (${CYAN}$DISTRO_ID${NC})"

if echo "$DISTRO_ID $DISTRO_ID_LIKE" | grep -qiw "arch"; then
    log_success "Arch-based family detected."
    export DISTRO_FAMILY="arch"
elif echo "$DISTRO_ID $DISTRO_ID_LIKE" | grep -qiw "debian\|ubuntu"; then
    log_success "Debian/Ubuntu-based family detected."
    export DISTRO_FAMILY="debian"
else
    log_error "Unsupported distribution: $DISTRO_ID. Exiting."
    exit 1
fi

# --- 2. Prerequisite Check ---
# The script needs 'rsync' for relocation.
log_info "Checking prerequisites (git, rsync)..."

if ! command -v rsync &>/dev/null; then
    log_warn "'rsync' is not installed. Installing..."
    if [ "$DISTRO_FAMILY" == "arch" ]; then
        sudo pacman -S --noconfirm --needed rsync
    elif [ "$DISTRO_FAMILY" == "debian" ]; then
        sudo apt-get update -qq
        sudo apt-get install -y rsync
    fi
    log_success "'rsync' installed."
else
    log_success "'rsync' is already installed."
fi
# (We assume 'git' exists since the user cloned the repo)

# --- 3. Self-Relocation Logic ---
# Define the permanent "home" for this repository.
DEST_BASE="$HOME/.dotfiles"
CURRENT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_NAME=$(basename "$CURRENT_DIR")
DEST_PATH="$DEST_BASE/$PROJECT_NAME"

# Check if the script is ALREADY in its permanent home.
if [ "$CURRENT_DIR" != "$DEST_PATH" ]; then
    echo -e "\n  ${BOLD}--- Relocating Installation Repository ---${NC}"
    log_info "Moving script to its permanent location: ${CYAN}$DEST_PATH${NC}"

    mkdir -p "$DEST_BASE"
    rsync -a --delete "$CURRENT_DIR/" "$DEST_PATH/"

    log_success "Relocation complete. Restarting script from new location..."
    echo -e "  -------------------------------------------------------------------"
    sleep 2

    # 'exec' replaces the current process with the new one, passing all args.
    exec "$DEST_PATH/install.sh" "$@"
fi

# --- 4. Main Configuration ---
log_info "Script running from permanent location: ${CYAN}$DEST_PATH${NC}"
export WORKDIR="$CURRENT_DIR" # $CURRENT_DIR is now $DEST_PATH

# --- 4b. Set Wallpaper (XFCE / KDE) ---
set_desktop_wallpaper() {
    local wp_path="$WORKDIR/wallhaven-p9gr2p_1920x1080.png"
    if [ ! -f "$wp_path" ]; then
        return
    fi

    # XFCE Wallpaper Setup
    if command -v xfconf-query &>/dev/null; then
        log_info "Setting XFCE desktop wallpaper..."
        local xfce_props
        xfce_props=$(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep "last-image" || true)
        for prop in $xfce_props; do
            xfconf-query -c xfce4-desktop -p "$prop" -s "$wp_path" 2>/dev/null || true
        done
    fi

    # KDE Plasma Wallpaper Setup
    local kdbus_cmd=""
    if command -v qdbus6 &>/dev/null; then
        kdbus_cmd="qdbus6"
    elif command -v qdbus &>/dev/null; then
        kdbus_cmd="qdbus"
    elif command -v qdbus-qt6 &>/dev/null; then
        kdbus_cmd="qdbus-qt6"
    elif command -v qdbus-qt5 &>/dev/null; then
        kdbus_cmd="qdbus-qt5"
    fi

    if [ -n "$kdbus_cmd" ]; then
        log_info "Setting KDE Plasma desktop wallpaper using ${GREEN}$kdbus_cmd${NC}..."
        $kdbus_cmd org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
            var desktops = desktops();
            for (var i = 0; i < desktops.length; i++) {
                var d = desktops[i];
                d.wallpaperPlugin = 'org.kde.image';
                d.currentConfigGroup = Array('Wallpaper', 'org.kde.image', 'General');
                d.writeConfig('Image', 'file://$wp_path')
            }
        " &>/dev/null || true
    fi
}

set_desktop_wallpaper

print_banner() {
    clear
    # Solid GREEN ASCII art for "UNIVERSAL SETUP"
    echo -e "${GREEN}   █ █ █▀█ ▀█▀ █ █ █▀▀ █▀▄ █▀▀ █▀█ █     █▀▀ █▀▀ ▀█▀ █ █ █▀█  ${NC}"
    echo -e "${GREEN}   █ █ █ █  █  ▀▄▀ █▀▀ █▀▄ ▀▀█ █▀█ █     ▀▀█ █▀▀  █  █ █ █▀▀  ${NC}"
    echo -e "${GREEN}   ▀▀▀ ▀ ▀ ▀▀▀  ▀  ▀▀▀ ▀ ▀ ▀▀▀ ▀ ▀ ▀▀▀   ▀▀▀ ▀▀▀  ▀  ▀▀▀ ▀    ${NC}"
    echo -e ""
    echo -e "  ${BOLD}System:${NC} ${GREEN}$PRETTY_NAME${NC} | ${BOLD}Family:${NC} ${CYAN}$DISTRO_FAMILY${NC}"
    echo -e "  --------------------------------------------------------"
    echo -e ""
}

# --- 5. User Interface (TUI) for Profile Selection ---
print_banner
echo -e "  ${BOLD}Please select the desired installation profile:${NC}"
echo -e ""

options=(
    "Minimal" "Firefox"
    "Work" "Minimal + VS Code, Antigravity IDE, Brave, Obsidian, OnlyOffice, Spotify, KeePassXC, qBittorrent"
    "Creative" "Minimal + Inkscape, Krita, Discord"
    "Gaming" "Minimal + Steam, Discord, Lutris, Heroic"
    "3D Printing" "Minimal + Bambu Studio, OrcaSlicer"
    "Virtualization" "Minimal + VirtualBox, QEMU, virt-manager"
    "Full" "Install EVERYTHING (all native & flatpak apps)"
    "Terminal Only" "Native terminal utilities & tools"
    "Custom" "Choose which categories to install"
    "Exit" "Cancel setup and exit"
)

for i in {1..10}; do
    idx=$(( (i - 1) * 2 ))
    title="${options[idx]}"
    desc="${options[idx+1]}"
    if [ $i -eq 10 ]; then
        echo -e "  ${RED}[$i]${NC} ${BOLD}$title${NC} - $desc"
    else
        echo -e "  ${CYAN}[$i]${NC} ${BOLD}$title${NC}"
        echo -e "      ${ITALIC}${NC}$desc"
    fi
done

echo ""
while true; do
    read -rp "  Select an option [1-10]: " choice_num
    case "$choice_num" in
        1) export PROFILE="minimal"; break ;;
        2) export PROFILE="work"; break ;;
        3) export PROFILE="creative"; break ;;
        4) export PROFILE="gaming"; break ;;
        5) export PROFILE="3dprint"; break ;;
        6) export PROFILE="virtualization"; break ;;
        7) export PROFILE="full"; break ;;
        8) export PROFILE="terminal"; break ;;
        9) export PROFILE="custom"; break ;;
        10) echo -e "\n  ${RED}Exiting installation.${NC}\n"; exit 0 ;;
        *) echo -e "  ${RED}[!] Invalid option: $choice_num. Please choose 1-10.${NC}" ;;
    esac
done

# --- 5b. Interactive Module Selection ---
# Only ask if no --skip-* flags were provided on the command line.
# This allows experienced users to bypass the questions with flags,
# while first-time users get guided through the options.
if [ ${#SKIP_MODULES[@]} -eq 0 ]; then
    print_banner
    echo -e "  ${BOLD}Configure Modules to Execute:${NC}"
    echo -e "  Press ${GREEN}[Enter]${NC} for Yes (default) or type ${RED}n${NC} to skip."
    echo -e ""

    declare -A module_descriptions
    module_descriptions["01-system-setup.sh"]="Base system setup (repos, package manager, Flatpak)"
    module_descriptions["02-install-apps.sh"]="Application installation (profile: ${GREEN}$PROFILE${NC})"
    module_descriptions["03-terminal-setup.sh"]="Terminal & shell setup (Zsh, Oh My Zsh, plugins)"
    module_descriptions["04-tweaks-and-config.sh"]="Tweaks & dotfiles (Kitty config, shell aliases)"

    for module_file in "01-system-setup.sh" "02-install-apps.sh" "03-terminal-setup.sh" "04-tweaks-and-config.sh"; do
        echo -e "  * ${BOLD}${module_file}${NC}"
        echo -e "    Description: ${module_descriptions[$module_file]}"
        
        while true; do
            read -rp "    Run this module? [Y/n]: " response
            response="${response,,}" # to lowercase
            if [[ -z "$response" || "$response" == "y" || "$response" == "yes" ]]; then
                echo -e "    ${GREEN}✓ Will run.${NC}\n"
                break
            elif [[ "$response" == "n" || "$response" == "no" ]]; then
                SKIP_MODULES+=("$module_file")
                echo -e "    ${YELLOW}✗ Will skip.${NC}\n"
                break
            else
                echo -e "    ${RED}[!] Invalid response. Please enter 'y' or 'n'.${NC}"
            fi
        done
    done
fi

# --- 6. Main Execution Logic ---
clear
print_banner
log_step "Starting Linux setup with profile: ${GREEN}$PROFILE${NC}"
echo -e "  -------------------------------------------------------------------"
sleep 2

# Ordered list of modules to execute.
modules=(
    "01-system-setup.sh"
    "02-install-apps.sh"
    "03-terminal-setup.sh"
    "04-tweaks-and-config.sh"
)

# Execute each module (or skip it if flagged).
for module in "${modules[@]}"; do
    # Check if this module was skipped via flag or interactive selection.
    if [[ " ${SKIP_MODULES[*]} " == *" $module "* ]]; then
        echo -e "  ${YELLOW}[~] Skipping module: $module${NC}"
        echo -e "  -------------------------------------------------------------------"
        continue
    fi

    clear
    print_banner
    script_path="$WORKDIR/modules/$module"

    if [ -f "$script_path" ]; then
        log_step "Executing module: ${BOLD}$module${NC}"
        echo -e "  -------------------------------------------------------------------"
        chmod +x "$script_path"

        # Run the module and stop everything if it fails.
        if ! "$script_path"; then
            echo ""
            log_error "Error in module '$module'. Installation has been stopped."
            exit 1
        fi

        echo ""
        log_success "Module finished: ${BOLD}$module${NC}"
        echo -e "  -------------------------------------------------------------------"
        echo -e "  (Next module in 2 seconds...)"
        sleep 2
    else
        log_warn "Module not found, skipping: $script_path"
        echo -e "  -------------------------------------------------------------------"
        sleep 2
    fi
done

# --- 7. Alias Generation ---
# Runs at the end to ensure all apps (from 02)
# and the .zshrc file (from 03) exist.
clear
print_banner
log_step "Running Flatpak alias generator..."
alias_script_path="$WORKDIR/modules/update-flatpak-aliases.sh"
if [ -f "$alias_script_path" ]; then
    chmod +x "$alias_script_path"
    if ! "$alias_script_path"; then
        log_error "Error in 'update-flatpak-aliases.sh' script."
        exit 1
    fi
    log_success "Alias generator finished."
    echo -e "  -------------------------------------------------------------------"
    echo -e "  (Final launch in 2 seconds...)"
    sleep 2
else
    log_warn "'update-flatpak-aliases.sh' not found. Skipping."
fi

# --- 8. Final Launch ---
clear
print_banner
log_success "All modules completed successfully!"
echo -e "  From now on, this script's repository lives in ${CYAN}$DEST_PATH${NC}"
echo -e "  You can update it with 'git pull' and use the 'update' alias."
echo ""
echo -e "  ${YELLOW}A system restart is recommended for all changes to take effect.${NC}"
log_step "Launching fastfetch in kitty for the grand finale!"

# 'nohup' and '&' run it in the background,
# independent of this terminal.
nohup kitty zsh -c "fastfetch; zsh" >/dev/null 2>&1 &

exit 0
