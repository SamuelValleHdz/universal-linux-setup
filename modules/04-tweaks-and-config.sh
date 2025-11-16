#!/bin/bash
# Enable strict mode
set -e
echo "--- Module 4: Tweaks and Personal Config ---"

# --- Dotfile Copying ---
# $WORKDIR is exported by install.sh
CONFIG_DIR="$WORKDIR/config"

if [ -d "$CONFIG_DIR" ]; then
    echo "[*] Copying configuration files (dotfiles)..."
    
    # Kitty block
    if [ -d "$CONFIG_DIR/kitty" ]; then
        # Ensure the target directory exists
        mkdir -p "$HOME/.config/kitty"
        # -rT copies the *contents* of the folder
        cp -rT "$CONFIG_DIR/kitty" "$HOME/.config/kitty"
        echo "[+] Kitty config copied."
    fi
    
    # Fastfetch block (syntax corrected)
    if [ -d "$CONFIG_DIR/fastfetch" ]; then
        mkdir -p "$HOME/.config/fastfetch"
        cp -rT "$CONFIG_DIR/fastfetch" "$HOME/.config/fastfetch"
        echo "[+] Fastfetch config copied."
    fi
    
else
    echo "[!] Warning: 'config' folder not found. Skipping dotfile copy."
fi

# --- Arch-Specific Tweaks (Examples) ---
if [ "$DISTRO" == "arch" ]; then
    echo "[*] Applying Arch-specific tweaks..."
    # Enable 'ILoveCandy' in pacman
    if ! grep -q "ILoveCandy" /etc/pacman.conf; then
        sudo sed -i '/#Color/a ILoveCandy' /etc/pacman.conf
        echo "[+] ILoveCandy enabled!"
    fi
    # Enable 'multilib'
    if grep -q "#\[multilib\]" /etc/pacman.conf; then
        echo "Enabling Multilib repository..."
        sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
        sudo pacman -Syy
        echo "[+] Multilib repository enabled."
    fi
fi

# --- VirtualBox Tweaks ---
# Check if VirtualBox was installed (by Module 02)
if command -v virtualbox &> /dev/null; then
    echo "[*] Configuring permissions for VirtualBox..."
    
    # Add the current user to the 'vboxusers' group
    if ! id -nG "$USER" | grep -q "vboxusers"; then
        sudo usermod -aG vboxusers "$USER"
        echo "[+] User $USER added to 'vboxusers' group."
        echo "   (A full LOGOUT is required for this to take effect)"
    else
        echo "[+] User $USER is already in 'vboxusers' group."
    fi
    
    # Warning about Extension Pack on Debian/Ubuntu
    if [ "$DISTRO" == "debian" ]; then
        if ! dpkg -l | grep -q "virtualbox-ext-pack"; then
            echo "-------------------------------------------------------------------"
            echo "[!] MANUAL ACTION REQUIRED (VirtualBox)"
            echo "The 'Extension Pack' (for USB) could not be installed automatically."
            echo "Please run the following manually and accept the license:"
            echo ""
            echo "   sudo apt install virtualbox-ext-pack"
            echo ""
            echo "-------------------------------------------------------------------"
        fi
    fi
else
    echo "-> VirtualBox is not installed, skipping tweaks."
fi

# --- Custom Shell Alias Setup ---
echo "[*] Configuring custom shell aliases..."

# Get the path to the alias script (defined in install.sh)
ALIAS_SCRIPT_PATH="$WORKDIR/modules/update-flatpak-aliases.sh"

# Use a marker to be idempotent
if ! grep -q "# --- End of custom aliases ---" "$HOME/.zshrc"; then
    echo "-> Adding custom alias block to .zshrc..."
    
    # \EOF prevents variables (like $USER) from expanding
    cat << \EOF >> "$HOME/.zshrc"

# --- Custom Aliases (Added by 04-tweaks-and-config.sh) ---
# Convenience aliases (sudo-less)
alias apt='sudo apt'
alias pacman='sudo pacman'
alias yay='yay' # Yay should never be run with sudo
EOF
    
    # --- Update Alias Logic ---
    
    if [ "$DISTRO" == "arch" ]; then
        echo "-> Adding 'syu' and 'update' aliases for Arch."
        # EOF (no '\') allows $ALIAS_SCRIPT_PATH to expand
        cat << EOF >> "$HOME/.zshrc"

# --- Update Aliases (Arch) ---
alias syu="echo '[>] Updating system (Yay), Flatpaks, and regenerating aliases...'; yay -Syu && flatpak update -y && \"$ALIAS_SCRIPT_PATH\""
alias update='syu'
EOF
    
    elif [ "$DISTRO" == "debian" ]; then
        echo "-> Adding 'update' and 'syu' aliases for Debian."
        cat << EOF >> "$HOME/.zshrc"

# --- Update Aliases (Debian) ---
alias update="echo '[>] Updating system (Apt), Flatpaks, and regenerating aliases...'; sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && flatpak update -y && \"$ALIAS_SCRIPT_PATH\""
alias syu='update'
EOF
    fi
    
    # Write the final marker
    echo "" >> "$HOME/.zshrc"
    echo "# --- End of custom aliases ---" >> "$HOME/.zshrc"

    echo "[+] Custom aliases added to .zshrc"
else
    echo "[+] Custom alias block already exists in .zshrc. Skipping."
fi


echo "--- Module 4 Finished ---"