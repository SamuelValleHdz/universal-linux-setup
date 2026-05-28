#!/bin/bash
# Enable strict mode
set -e
echo "--- Module 4: Tweaks and Personal Config ---"
echo "[*] Distro: $PRETTY_NAME ($DISTRO_ID) | Family: $DISTRO_FAMILY"

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
if [ "$DISTRO_FAMILY" == "arch" ]; then
    echo "[*] Applying Arch-specific tweaks..."
    if ! grep -q "ILoveCandy" /etc/pacman.conf; then
        sudo sed -i '/#Color/a ILoveCandy' /etc/pacman.conf
        echo "[+] ILoveCandy enabled!"
    fi
fi

# --- VirtualBox Tweaks ---
if command -v virtualbox &> /dev/null; then
    echo "[*] Configuring permissions for VirtualBox..."
    if ! id -nG "$USER" | grep -q "vboxusers"; then
        sudo usermod -aG vboxusers "$USER"
        echo "[+] User $USER added to 'vboxusers' group."
    fi
fi

# --- Kitty Theme Setup ---
if command -v kitty &> /dev/null; then
    echo "[*] Setting Kitty theme to 'Catppuccin-Macchiato'..."
    mkdir -p "$HOME/.config/kitty"
    
    # 1. Volcar el tema 'Catppuccin-Macchiato'
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

# --- FIX: Asegurar permisos de ejecución aquí mismo ---
if [ -f "$ALIAS_SCRIPT_PATH" ]; then
    chmod +x "$ALIAS_SCRIPT_PATH"
    echo "[+] Ensured execution permissions for alias generator."
fi
# -----------------------------------------------------

if ! grep -q "# --- End of custom aliases ---" "$HOME/.zshrc"; then
    echo "-> Adding custom alias block to .zshrc..."
    
    cat << \EOF >> "$HOME/.zshrc"

# --- Custom Aliases (Added by 04-tweaks-and-config.sh) ---
alias apt='sudo apt'
alias pacman='sudo pacman'  

# --- Python 'Quick & Dirty' Environment ---
export PIP_REQUIRE_VIRTUALENV=false
pipi() {
    if [ ! -d "$HOME/.dev_env" ]; then
        echo "Creando entorno global en ~/.dev_env..."
        python -m venv "$HOME/.dev_env"
    fi
    "$HOME/.dev_env/bin/pip" "$@"
}
pythoni() {
    "$HOME/.dev_env/bin/python" "$@"
}
EOF
    
    if [ "$DISTRO_FAMILY" == "arch" ]; then
        echo "-> Adding 'syu' and 'update' aliases for Arch."
        # Detect AUR helper at alias-creation time for the update command
        if command -v paru &>/dev/null; then _aur="paru"; elif command -v yay &>/dev/null; then _aur="yay"; else _aur="sudo pacman"; fi
        cat << EOF >> "$HOME/.zshrc"

# --- Update Aliases (Arch) ---
alias syu="echo '[>] Updating system ($_aur), Flatpaks, and regenerating aliases...'; $_aur -Syu && flatpak update -y && '$ALIAS_SCRIPT_PATH'"
alias update='syu'
EOF
    elif [ "$DISTRO_FAMILY" == "debian" ]; then
        echo "-> Adding 'update' and 'syu' aliases for Debian."
        cat << EOF >> "$HOME/.zshrc"

# --- Update Aliases (Debian) ---
alias update="echo '[>] Updating system (Apt), Flatpaks, and regenerating aliases...'; sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && flatpak update -y && '$ALIAS_SCRIPT_PATH'"
alias syu='update'
EOF
    fi
    
    echo "" >> "$HOME/.zshrc"
    echo "# --- End of custom aliases ---" >> "$HOME/.zshrc"
    echo "[+] Custom aliases added to .zshrc"
else
    echo "[+] Custom alias block already exists. Skipping."
fi

echo "--- Module 4 Finished ---"