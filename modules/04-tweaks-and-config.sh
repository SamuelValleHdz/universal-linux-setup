#!/bin/bash
# Activa el modo estricto
set -e
echo "--- Módulo 4: Ajustes y Configuraciones Personales ---"

# --- Copia de Dotfiles ---
# $WORKDIR es exportado por install.sh
CONFIG_DIR="$WORKDIR/config"

if [ -d "$CONFIG_DIR" ]; then
    echo "⚙️  Copiando archivos de configuración (dotfiles)..."
    
    # Bloque de Kitty
    if [ -d "$CONFIG_DIR/kitty" ]; then
        # Asegura que el directorio de destino exista
        mkdir -p "$HOME/.config/kitty"
        # -rT copia el contenido de la carpeta
        cp -rT "$CONFIG_DIR/kitty" "$HOME/.config/kitty"
        echo "✅ Configuración de Kitty copiada."
    fi
    
    # Bloque de Fastfetch (Corregido, sin brackets)
    if [ -d "$CONFIG_DIR/fastfetch" ]; then
        mkdir -p "$HOME/.config/fastfetch"
        cp -rT "$CONFIG_DIR/fastfetch" "$HOME/.config/fastfetch"
        echo "✅ Configuración de Fastfetch copiada."
    fi
    
else
    echo "⚠️  No se encontró la carpeta 'config'. Saltando copia de dotfiles."
fi

# --- Ajustes Específicos de Arch (Ejemplos) ---
if [ "$DISTRO" == "arch" ]; then
    echo "⚙️  Aplicando ajustes específicos para Arch..."
    # Activa 'ILoveCandy' en pacman
    if ! grep -q "ILoveCandy" /etc/pacman.conf; then
        sudo sed -i '/#Color/a ILoveCandy' /etc/pacman.conf
        echo "🍬 ¡ILoveCandy activado!"
    fi
    # Activa 'multilib'
    if grep -q "#\[multilib\]" /etc/pacman.conf; then
        echo "Habilitando repositorio Multilib..."
        sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
        sudo pacman -Syy
        echo "✅ Repositorio Multilib activado."
    fi
fi

# --- Ajustes de VirtualBox ---
# Revisa si VirtualBox está instalado (por el Módulo 02)
if command -v virtualbox &> /dev/null; then
    echo "⚙️  Configurando permisos para VirtualBox..."
    
    # Añade el usuario actual al grupo 'vboxusers'
    if ! id -nG "$USER" | grep -q "vboxusers"; then
        sudo usermod -aG vboxusers "$USER"
        echo "✅ Usuario $USER añadido al grupo 'vboxusers'."
        echo "   (Se requiere CERRAR SESIÓN y volver a entrar para que surta efecto)"
    else
        echo "👌 El usuario $USER ya pertenece al grupo 'vboxusers'."
    fi
    
    # Aviso sobre el Extension Pack en Debian/Ubuntu
    if [ "$DISTRO" == "debian" ]; then
        if ! dpkg -l | grep -q "virtualbox-ext-pack"; then
            echo "-------------------------------------------------------------------"
            echo "⚠️  ACCIÓN MANUAL REQUERIDA (VirtualBox)"
            echo "El 'Extension Pack' (para USB) no se pudo instalar automáticamente."
            echo "Por favor, ejecútalo manualmente y acepta la licencia:"
            echo ""
            echo "   sudo apt install virtualbox-ext-pack"
            echo ""
            echo "-------------------------------------------------------------------"
        fi
    fi
else
    echo "-> VirtualBox no está instalado, saltando ajustes."
fi

# --- Configuración de Alias de Shell ---
echo "⚙️  Configurando alias personalizados para Zsh..."

# Obtiene la ruta al script de alias (definida en install.sh)
ALIAS_SCRIPT_PATH="$WORKDIR/modules/update-flatpak-aliases.sh"

# Usa un marcador para ser idempotente
if ! grep -q "# --- Fin de los alias personalizados ---" "$HOME/.zshrc"; then
    echo "-> Añadiendo bloque de alias personalizados a .zshrc..."
    
    # \EOF evita que las variables (como $USER) se expandan
    cat << \EOF >> "$HOME/.zshrc"

# --- Alias Personalizados (Añadidos por 04-tweaks-and-config.sh) ---
# Alias de conveniencia (sin sudo)
alias apt='sudo apt'
alias pacman='sudo pacman'
alias yay='yay' # Yay nunca debe usarse con sudo
EOF
    
    # --- Lógica de Alias de Actualización ---
    
    if [ "$DISTRO" == "arch" ]; then
        echo "-> Añadiendo alias 'syu' y 'update' para Arch."
        # EOF (sin '\') permite que $ALIAS_SCRIPT_PATH se expanda
        cat << EOF >> "$HOME/.zshrc"

# --- Alias de Actualización (Arch) ---
alias syu="echo '🚀 Actualizando sistema (Yay), Flatpaks y regenerando alias...'; yay -Syu && flatpak update -y && \"$ALIAS_SCRIPT_PATH\""
alias update='syu'
EOF
    
    elif [ "$DISTRO" == "debian" ]; then
        echo "-> Añadiendo alias 'update' y 'syu' para Debian."
        cat << EOF >> "$HOME/.zshrc"

# --- Alias de Actualización (Debian) ---
alias update="echo '🚀 Actualizando sistema (Apt), Flatpaks y regenerando alias...'; sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && flatpak update -y && \"$ALIAS_SCRIPT_PATH\""
alias syu='update'
EOF
    fi
    
    # Escribir el marcador final
    echo "" >> "$HOME/.zshrc"
    echo "# --- Fin de los alias personalizados ---" >> "$HOME/.zshrc"

    echo "✅ Alias personalizados añadidos a .zshrc"
else
    echo "👌 El bloque de alias personalizados ya existe en .zshrc. Saltando."
fi


echo "--- Módulo 4 Finalizado ---"