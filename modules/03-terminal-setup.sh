#!/bin/bash

# Activa el modo estricto
set -e

echo "--- Módulo 3: Configuración de la Terminal ---"

# --- Zsh y Oh My Zsh ---
# (Toda la sección de Zsh y Oh My Zsh sigue igual...)
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
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    echo "✅ Oh My Zsh instalado."
else
    echo "👌 Oh My Zsh ya está instalado."
fi

# --- Plugins para Oh My Zsh ---
# (La sección de plugins sigue igual...)
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

sed -i.bak 's/^plugins=(git)$/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc
echo "✅ Plugins de Zsh activados en .zshrc"


# --- Entorno para Neovim / LunarVim ---
echo "⚙️  Instalando dependencias de LunarVim..."

# Instalar Neovim, Node.js y npm de forma nativa
if [ "$DISTRO" == "arch" ]; then
    sudo pacman -S --noconfirm --needed neovim nodejs npm
elif [ "$DISTRO" == "debian" ]; then
    sudo apt-get install -y neovim nodejs npm
fi

# Instala LunarVim si no está ya instalado
if ! command -v lvim &> /dev/null; then
    echo "⚙️  Instalando LunarVim (lvim)..."
    # Usamos la misma rama que tenías definida
    # Añadimos '--yes' para hacerlo no-interactivo
    LV_BRANCH='release-1.3/neovim-0.9' bash <(curl -s https://raw.githubusercontent.com/LunarVim/LunarVim/release-1.3/neovim-0.9/utils/installer/install.sh) --yes
    echo "✅ LunarVim instalado."
else
    echo "👌 LunarVim (lvim) ya está instalado."
fi


# Añade las rutas de Flatpak y .local/bin al .zshrc
echo "⚙️  Configurando $PATH para Flatpak y LunarVim en .zshrc..."

cat << 'EOF' >> ~/.zshrc

# --- Configuración de $PATH ---

if ! grep -q "pipx ensurepath" "$HOME/.zshrc"; then
    echo 'eval "$(pipx ensurepath)"' >> ~/.zshrc
fi

# Añade la carpeta local de binarios (para lvim y otros scripts)
if [ -d "$HOME/.local/bin" ] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$PATH:$HOME/.local/bin"
fi

# Añade las carpetas de binarios de Flatpak (para 'firefox', 'vlc', etc.)
# Para instalaciones de todo el sistema
if [ -d "/var/lib/flatpak/exports/bin" ] && [[ ":$PATH:" != *":/var/lib/flatpak/exports/bin:"* ]]; then
    export PATH="$PATH:/var/lib/flatpak/exports/bin"
fi
# Para instalaciones de usuario
if [ -d "$HOME/.local/share/flatpak/exports/bin" ] && [[ ":$PATH:" != *":$HOME/.local/share/flatpak/exports/bin:"* ]]; then
    export PATH="$PATH:$HOME/.local/share/flatpak/exports/bin"
fi
# --- Fin de la configuración de $PATH ---
EOF

echo "✅ $PATH de Flatpak y .local/bin configurado en .zshrc"
# ==== FIN DE MODIFICACIÓN 2 ====


echo "--- Módulo 3 Finalizado ---"