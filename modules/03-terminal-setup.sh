#!/bin/bash
# Activa el modo estricto
set -e

echo "--- Módulo 3: Configuración de la Terminal ---"

# --- Arreglo de Permisos ---
# Arregla el error 'permission denied: /home/sam/.local/bin'
echo "⚙️  Verificando permisos de /home/$USER/.local/bin..."
mkdir -p "$HOME/.local/bin"
sudo chown -R $USER:$USER "$HOME/.local/bin"
echo "✅ Permisos de .local/bin corregidos."

# --- Zsh y Oh My Zsh ---
if [ "$SHELL" != "/bin/zsh" ]; then
    echo "⚙️  Cambiando el shell por defecto a Zsh..."
    ZSH_PATH=$(which zsh)
    if chsh -s "$ZSH_PATH"; then
        echo "✅ Shell cambiado a Zsh. Por favor, cierra sesión y vuelve a entrar."
    else
        echo "⚠️  No se pudo cambiar el shell."
    fi
else
    echo "👌 El shell por defecto ya es Zsh."
fi

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "⚙️  Instalando Oh My Zsh..."
    # --unattended lo hace no-interactivo
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    echo "✅ Oh My Zsh instalado."
else
    echo "👌 Oh My Zsh ya está instalado."
fi

# --- Plugins para Oh My Zsh ---
ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    echo "⚙️  Instalando zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
else
    echo "👌 zsh-autosuggestions ya está instalado."
fi
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    echo "⚙️  Instalando zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
else
    echo "👌 zsh-syntax-highlighting ya está instalado."
fi
# Reemplaza la línea 'plugins=(git)' por la lista completa
sed -i.bak 's/^plugins=(git)$/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc
echo "✅ Plugins de Zsh activados en .zshrc"

# --- Entorno para Neovim / LunarVim ---
echo "⚙️  Instalando dependencias de LunarVim..."
if [ "$DISTRO" == "arch" ]; then
    sudo pacman -S --noconfirm --needed neovim nodejs npm
elif [ "$DISTRO" == "debian" ]; then
    sudo apt-get install -y neovim nodejs npm
fi

# Instala LunarVim (es idempotente, no se reinstala)
if ! command -v lvim &> /dev/null; then
    echo "⚙️  Instalando LunarVim (lvim)..."
    LV_BRANCH='release-1.4/neovim-0.9' bash <(curl -s https://raw.githubusercontent.com/LunarVim/LunarVim/release-1.4/neovim-0.9/utils/installer/install.sh) --no 
    echo "✅ LunarVim instalado."
else
    echo "👌 LunarVim (lvim) ya está instalado."
fi

# --- Configuración de $PATH y Alias ---
echo "⚙️  Configurando $PATH para pipx, lvim y alias en .zshrc..."

# --- pipx ---
# Arregla el error 'eval: command not found: Otherwise'
# Redirige stderr (2) a /dev/null para silenciar la advertencia
if ! grep -q 'eval "$(pipx ensurepath &>/dev/null)"' "$HOME/.zshrc"; then
    # Borra líneas viejas si existen
    sed -i '/pipx ensurepath/d' "$HOME/.zshrc"
    echo 'eval "$(pipx ensurepath &>/dev/null)"' >> "$HOME/.zshrc"
    echo "✅ Añadido pipx ensurepath a .zshrc"
else
    echo "👌 pipx ensurepath ya está en .zshrc."
fi

# --- .local/bin (lvim), Flatpak (auto) y Alias (estáticos) ---
# Usa un marcador para ser idempotente
if ! grep -q "# --- Fin de la configuración de \$PATH y Alias ---" "$HOME/.zshrc"; then
    echo "-> Añadiendo bloque de \$PATH y carga de alias..."
    cat << 'EOF' >> ~/.zshrc

# --- Configuración de $PATH ---
# (Bloque añadido por el script global-linux-desktop)

# Añade la carpeta local de binarios (para lvim)
if [ -d "$HOME/.local/bin" ] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$PATH:$HOME/.local/bin"
fi

# Añade las carpetas de binarios de Flatpak (Intento automático del sistema)
if [ -d "/var/lib/flatpak/exports/bin" ] && [[ ":$PATH:" != *":/var/lib/flatpak/exports/bin:"* ]]; then
    export PATH="$PATH:/var/lib/flatpak/exports/bin"
fi
if [ -d "$HOME/.local/share/flatpak/exports/bin" ] && [[ ":$PATH:" != *":$HOME/.local/share/flatpak/exports/bin:"* ]]; then
    export PATH="$PATH:$HOME/.local/share/flatpak/exports/bin"
fi

# --- Cargar alias de Flatpak (GENERADOS) ---
# Carga el archivo de alias generado por 'update-flatpak-aliases.sh'
ALIAS_FILE_PATH="$HOME/.zshrc-flatpak-aliases"
if [ -f "$ALIAS_FILE_PATH" ]; then
    source "$ALIAS_FILE_PATH"
fi
# --- Fin de la configuración de $PATH y Alias ---
EOF
    echo "✅ $PATH y alias de Flatpak configurados en .zshrc"
else
    echo "👌 El bloque de \$PATH y Alias ya existe en .zshrc. Saltando."
fi
echo "--- Módulo 3 Finalizado ---"