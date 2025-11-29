#!/bin/bash
# Enable strict mode
set -e
echo "--- Module 4: Tweaks and Personal Config ---"

# --- Dotfile Copying ---
CONFIG_DIR="$WORKDIR/config"

if [ -d "$CONFIG_DIR" ]; then
    echo "[*] Copying configuration files (dotfiles)..."
    
    if [ -d "$CONFIG_DIR/kitty" ]; then
        mkdir -p "$HOME/.config/kitty"
        cp -rT "$CONFIG_DIR/kitty" "$HOME/.config/kitty"
        echo "[+] Kitty config copied."
    fi
    
    if [ -d "$CONFIG_DIR/fastfetch" ]; then
        mkdir -p "$HOME/.config/fastfetch"
        cp -rT "$CONFIG_DIR/fastfetch" "$HOME/.config/fastfetch"
        echo "[+] Fastfetch config copied."
    fi
else
    echo "[!] Warning: 'config' folder not found. Skipping dotfile copy."
fi

# --- Arch-Specific Tweaks ---
if [ "$DISTRO" == "arch" ]; then
    echo "[*] Applying Arch-specific tweaks..."
    # Enable 'ILoveCandy' in pacman
    if ! grep -q "ILoveCandy" /etc/pacman.conf; then
        sudo sed -i '/#Color/a ILoveCandy' /etc/pacman.conf
        echo "[+] ILoveCandy enabled!"
    fi
    # Note: Multilib logic was moved to Module 01
fi

# --- VirtualBox Tweaks ---
if command -v virtualbox &> /dev/null; then
    echo "[*] Configuring permissions for VirtualBox..."
    if ! id -nG "$USER" | grep -q "vboxusers"; then
        sudo usermod -aG vboxusers "$USER"
        echo "[+] User $USER added to 'vboxusers' group."
    else
        echo "[+] User $USER is already in 'vboxusers' group."
    fi
    
    if [ "$DISTRO" == "debian" ]; then
        if ! dpkg -l | grep -q "virtualbox-ext-pack"; then
            echo "-------------------------------------------------------------------"
            echo "[!] MANUAL ACTION REQUIRED (VirtualBox)"
            echo "The 'Extension Pack' (for USB) could not be installed automatically."
            echo "Please run: sudo apt install virtualbox-ext-pack"
            echo "-------------------------------------------------------------------"
        fi
    fi
else
    echo "-> VirtualBox is not installed, skipping tweaks."
fi

# --- Kitty Theme Setup ---
if command -v kitty &> /dev/null; then
    echo "[*] Setting Kitty theme to 'Catppuccin-Macchiato'..."
    mkdir -p "$HOME/.config/kitty"
    
    # 1. Volcar el tema 'Catppuccin-Macchiato'
    # Nota: Requiere que kitty-themes esté disponible o internet para bajarlo
    if kitty +kitten themes --dump-theme "Catppuccin-Macchiato" > "$HOME/.config/kitty/current-theme.conf" 2>/dev/null; then
        
        # 2. Asegurar que kitty.conf incluya este tema
        KITTY_CONF="$HOME/.config/kitty/kitty.conf"
        touch "$KITTY_CONF"
        
        if ! grep -q "include current-theme.conf" "$KITTY_CONF"; then
            echo "" >> "$KITTY_CONF"
            echo "# --- Theme configured by install script ---" >> "$KITTY_CONF"
            echo "include current-theme.conf" >> "$KITTY_CONF"
        fi
        echo "[+] Theme 'Catppuccin-Macchiato' applied successfully."
    else
        echo "[!] Warning: Could not find theme 'Catppuccin-Macchiato'. Check internet connection or theme name."
    fi
fi

# --- Custom Shell Alias Setup ---
echo "[*] Configuring custom shell aliases..."
ALIAS_SCRIPT_PATH="$WORKDIR/modules/update-flatpak-aliases.sh"

if ! grep -q "# --- End of custom aliases ---" "$HOME/.zshrc"; then
    echo "-> Adding custom alias block to .zshrc..."
    
    cat << \EOF >> "$HOME/.zshrc"

# --- Custom Aliases (Added by 04-tweaks-and-config.sh) ---
alias apt='sudo apt'
alias pacman='sudo pacman'
alias yay='yay'
EOF
    
    if [ "$DISTRO" == "arch" ]; then
        echo "-> Adding 'syu' and 'update' aliases for Arch."
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
    
    echo "" >> "$HOME/.zshrc"
    echo "# --- End of custom aliases ---" >> "$HOME/.zshrc"
    echo "[+] Custom aliases added to .zshrc"
else
    echo "[+] Custom alias block already exists in .zshrc. Skipping."
fi

echo "--- Module 4 Finished ---"