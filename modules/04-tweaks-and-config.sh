# ... (Al final de 04-tweaks-and-config.sh)

# --- Ajustes de VirtualBox ---
# Revisa si VirtualBox está instalado antes de intentar configurarlo
if command -v virtualbox &> /dev/null; then
    echo "⚙️  Configurando permisos para VirtualBox..."
    
    # Añade el usuario actual al grupo 'vboxusers'
    # 'id -nG $USER' lista los grupos del usuario
    # 'grep -q' comprueba si 'vboxusers' ya está en la lista
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
    # Si virtualbox no está instalado, no hace nada
    echo "-> VirtualBox no está instalado, saltando ajustes."
fi

# ... (Todo tu script 04 anterior) ...

# --- Configuración de Alias de Shell ---
echo "⚙️  Configurando alias personalizados para Zsh..."

# $WORKDIR es exportado por install.sh y ahora es una ruta absoluta
# Esta variable se expandirá AHORA (en el script)
ALIAS_SCRIPT_PATH="$WORKDIR/modules/update-flatpak-aliases.sh"

# Usamos un marcador para evitar duplicados
if ! grep -q "# --- Fin de los alias personalizados ---" "$HOME/.zshrc"; then
    echo "-> Añadiendo bloque de alias personalizados a .zshrc..."
    
    # Primero, añadimos los alias sin sudo (que son independientes de la distro)
    # Usamos comillas en el EOF para que NADA se expanda
    cat << \EOF >> "$HOME/.zshrc"

# --- Alias Personalizados (Añadidos por 04-tweaks-and-config.sh) ---

# --- Alias de conveniencia (sin sudo) ---
alias apt='sudo apt'
alias pacman='sudo pacman'
# 'yay' no debe usarse con sudo, ya lo pide cuando lo necesita.
alias yay='yay'
EOF
    
    # --- Lógica de Alias de Actualización ---
    # Esta lógica se ejecuta AHORA y añade el alias correcto
    
    if [ "$DISTRO" == "arch" ]; then
        echo "-> Añadiendo alias 'syu' y 'update' para Arch."
        # Usamos "EOF" (sin comillas) para que $ALIAS_SCRIPT_PATH se expanda
        cat << EOF >> "$HOME/.zshrc"

# --- Alias de Actualización (Arch) ---
alias syu="echo '🚀 Actualizando sistema (Yay) y Flatpaks...'; yay -Syu && \"$ALIAS_SCRIPT_PATH\""
alias update='syu'
EOF
    
    elif [ "$DISTRO" == "debian" ]; then
        echo "-> Añadiendo alias 'update' y 'syu' para Debian."
        # Usamos "EOF" (sin comillas) para que $ALIAS_SCRIPT_PATH se expanda
        cat << EOF >> "$HOME/.zshrc"

# --- Alias de Actualización (Debian) ---
alias update="echo '🚀 Actualizando sistema (Apt) y Flatpaks...'; sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && \"$ALIAS_SCRIPT_PATH\""
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