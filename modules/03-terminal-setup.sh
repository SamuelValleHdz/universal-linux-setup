#!/bin/bash
# Activa el modo estricto
set -e

echo "--- Módulo 3: Configuración de la Terminal ---"

# --- Zsh y Oh My Zsh ---
# (Sección sin cambios)
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
# (Sección sin cambios)
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
# (Sección sin cambios)
echo "⚙️  Instalando dependencias de LunarVim..."
if [ "$DISTRO" == "arch" ]; then
    sudo pacman -S --noconfirm --needed neovim nodejs npm
elif [ "$DISTRO" == "debian" ]; then
    sudo apt-get install -y neovim nodejs npm
fi
if ! command -v lvim &> /dev/null; then
    echo "⚙️  Instalando LunarVim (lvim)..."
    LV_BRANCH='release-1.4/neovim-0.9' bash <(curl -s https://raw.githubusercontent.com/LunarVim/LunarVim/release-1.4/neovim-0.9/utils/installer/install.sh) --yes
    echo "✅ LunarVim instalado."
else
    echo "👌 LunarVim (lvim) ya está instalado."
fi

# --- Configuración de $PATH ---
echo "⚙️  Configurando $PATH para pipx, lvim y alias en .zshrc..."

# --- pipx ---
# (Sección sin cambios)
if ! grep -q 'eval "$(pipx ensurepath)"' "$HOME/.zshrc"; then
    echo 'eval "$(pipx ensurepath)"' >> "$HOME/.zshrc"
    echo "✅ Añadido pipx ensurepath a .zshrc"
else
    echo "👌 pipx ensurepath ya está en .zshrc."
fi

# --- .local/bin (lvim), Flatpak (auto) y Alias (dinámicos) ---
# (Marcador actualizado para reflejar la nueva lógica)
if ! grep -q "# --- Fin de la configuración de \$PATH y Alias Dinámicos ---" "$HOME/.zshrc"; then
    echo "-> Añadiendo bloque de \$PATH y carga de alias dinámicos..."
    
    cat << 'EOF' >> ~/.zshrc

# --- Configuración de $PATH ---
# (Bloque añadido por el script global-linux-desktop)

# Añade la carpeta local de binarios (para lvim)
if [ -d "$HOME/.local/bin" ] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$PATH:$HOME/.local/bin"
fi

# Añade las carpetas de binarios de Flatpak (Intento automático)
if [ -d "/var/lib/flatpak/exports/bin" ] && [[ ":$PATH:" != *":/var/lib/flatpak/exports/bin:"* ]]; then
    export PATH="$PATH:/var/lib/flatpak/exports/bin"
fi
if [ -d "$HOME/.local/share/flatpak/exports/bin" ] && [[ ":$PATH:" != *":$HOME/.local/share/flatpak/exports/bin:"* ]]; then
    export PATH="$PATH:$HOME/.local/share/flatpak/exports/bin"
fi

# --- Cargar alias de Flatpak (DINÁMICAMENTE) ---
# Genera alias para *todos* los flatpaks instalados
# al inicio de cada sesión de shell.
# Funciona con la salida de 'flatpak list --app'
if command -v flatpak &> /dev/null; then
    eval "$(flatpak list --app | awk '{
        app_id = $2;
        n = split(app_id, parts, ".");
        alias_name = tolower(parts[n]);
        printf "alias %s=\047flatpak run %s\047\n", alias_name, app_id
    }')"
fi
# --- Fin de la configuración de $PATH y Alias Dinámicos ---
EOF
    echo "✅ $PATH y alias de Flatpak configurados en .zshrc"
else
    echo "👌 El bloque de \$PATH y Alias Dinámicos ya existe en .zshrc. Saltando."
fi


echo "--- Módulo 3 Finalizado ---"