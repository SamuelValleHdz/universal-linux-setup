#!/bin/bash
# Enable strict mode: if a command fails, the script will exit.
set -e

# --- 1. Distro Detection (Moved to top) ---
# We need to know the distro NOW to install prerequisites.
export DISTRO=""
if command -v pacman &> /dev/null; then
    echo "[+] Arch-based system detected."
    DISTRO="arch"
elif command -v apt &> /dev/null; then
    echo "[+] Debian/Ubuntu-based system detected."
    DISTRO="debian"
else
    echo "[!] Unsupported distribution. Exiting."
    exit 1
fi

# --- 2. Prerequisite Check ---
# The script needs 'git' (for future pulls) and 'rsync' (for relocation).
echo "[*] Checking prerequisites (git, rsync)..."

if ! command -v rsync &> /dev/null; then
    echo "-> 'rsync' is not installed. Installing..."
    if [ "$DISTRO" == "arch" ]; then
        sudo pacman -S --noconfirm --needed rsync
    elif [ "$DISTRO" == "debian" ]; then
        sudo apt-get update
        sudo apt-get install -y rsync
    fi
    echo "[+] 'rsync' installed."
else
    echo "[+] 'rsync' is already installed."
fi
# (We assume 'git' exists since the user cloned the repo)

# --- 3. Self-Relocation Logic ---
# Define the permanent "home" for this repository
DEST_BASE="$HOME/.dotfiles"
CURRENT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_NAME=$(basename "$CURRENT_DIR")
DEST_PATH="$DEST_BASE/$PROJECT_NAME"

# Check if the script is ALREADY in its permanent home
if [ "$CURRENT_DIR" != "$DEST_PATH" ]; then
    echo "--- Relocating Installation Repository ---"
    echo "Moving script to its permanent location: $DEST_PATH"
    
    mkdir -p "$DEST_BASE"
    
    # This command will now work on Arch because
    # we just installed 'rsync'
    rsync -a --delete "$CURRENT_DIR/" "$DEST_PATH/"
    
    echo "[+] Relocation complete. Restarting script from new location..."
    echo "-------------------------------------------------------------------"
    sleep 2
    
    # 'exec' replaces the current process with the new one
    exec "$DEST_PATH/install.sh" "$@"
fi

# --- 4. Main Configuration ---
echo "--- Script running from permanent location ($DEST_PATH) ---"
# Export the absolute WORKDIR so modules (like 04)
# can use it to create aliases (like 'update')
export WORKDIR="$CURRENT_DIR" # $CURRENT_DIR is now $DEST_PATH

# --- 5. User Interface (TUI) for Profile Selection ---
clear 
echo "Welcome to the Installation Script."
echo "Please select the desired installation profile:"
echo ""

options=(
    "Minimal (Firefox, VLC, VSCode)"
    "Work (Minimal + Obsidian, OnlyOffice)"
    "Creative (Minimal + Inkscape, Krita)"
    "Gaming (Minimal + Lutris, Heroic, Prism)"
    "Virtualization (Minimal + VirtualBox)"
    "Full (Install EVERYTHING)"
    "Terminal Only (Native utilities)"
    "Exit"
)
PS3="Choose an option (1-8): "
select choice in "${options[@]}"; do
    case $choice in
        "${options[0]}") export PROFILE="minimal"; break ;;
        "${options[1]}") export PROFILE="work"; break ;;
        "${options[2]}") export PROFILE="creative"; break ;;
        "${options[3]}") export PROFILE="gaming"; break ;;
        "${options[4]}") export PROFILE="virtualization"; break ;;
        "${options[5]}") export PROFILE="full"; break ;;
        "${options[6]}") export PROFILE="terminal"; break ;;
        "${options[7]}") echo "Exiting."; exit 0 ;;
        *) echo "Invalid option: $REPLY." ;;
    esac
done

# --- 6. Main Execution Logic ---
echo "[>] Starting Linux setup with profile: $PROFILE on a $DISTRO system."
echo "-------------------------------------------------------------------"
sleep 2 

# Ordered list of modules to execute
modules=(
    "01-system-setup.sh"
    "02-install-apps.sh"
    "03-terminal-setup.sh"
    "04-tweaks-and-config.sh"
)

# Execute each module
for module in "${modules[@]}"; do
    clear
    script_path="$WORKDIR/modules/$module"
    
    if [ -f "$script_path" ]; then
        echo "[>] Executing module: $module (Profile: $PROFILE)"
        chmod +x "$script_path"
        
        # Run the module and stop everything if it fails
        if ! "$script_path"; then
            echo "[!] Error in module '$module'. Installation has been stopped."
            exit 1
        fi

        echo "[+] Module finished: $module"
        echo "-------------------------------------------------------------------"
        echo "(Next module in 2 seconds...)"
        sleep 2
    else
        echo "[!] Warning: Module not found, skipping: $script_path"
        echo "-------------------------------------------------------------------"
        sleep 2
    fi
done

# --- 7. Alias Generation ---
# Runs at the end to ensure all apps (from 02)
# and the .zshrc file (from 03) exist.
clear
echo "[>] Running Flatpak alias generator..."
alias_script_path="$WORKDIR/modules/update-flatpak-aliases.sh"
if [ -f "$alias_script_path" ]; then
    chmod +x "$alias_script_path"
    if ! "$alias_script_path"; then
        echo "[!] Error in 'update-flatpak-aliases.sh' script."
        exit 1
    fi
    echo "[+] Alias generator finished."
    echo "-------------------------------------------------------------------"
    echo "(Final launch in 2 seconds...)"
    sleep 2
else
    echo "[!] Warning: 'update-flatpak-aliases.sh' not found. Skipping."
fi

# --- 8. Final Launch ---
clear
echo "[+] All modules completed successfully!"
echo "From now on, this script's repository lives in $DEST_PATH"
echo "You can update it with 'git pull' and use the 'update' alias."
echo ""
echo "A system restart is recommended for all changes to take effect."
echo "[>] Launching fastfetch in kitty for the grand finale!"

# 'nohup' and '&' run it in the background,
# independent of this terminal
nohup kitty zsh -c "fastfetch; zsh" >/dev/null 2>&1 &

exit 0