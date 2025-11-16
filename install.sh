#!/bin/bash
# Activa el modo estricto: si un comando falla, el script se detiene.
set -e

# --- 1. Detección de Distro (Movido al inicio) ---
# Necesitamos saber la distro AHORA para instalar prerrequisitos.
export DISTRO=""
if command -v pacman &> /dev/null; then
    echo "✅ Sistema basado en Arch detectado."
    DISTRO="arch"
elif command -v apt &> /dev/null; then
    echo "✅ Sistema basado en Debian/Ubuntu detectado."
    DISTRO="debian"
else
    echo "❌ Distribución no soportada. Saliendo."
    exit 1
fi

# --- 2. Comprobación de Prerrequisitos ---
# El script necesita 'git' (para futuros 'pull') y 'rsync' (para reubicarse).
echo "⚙️  Comprobando prerrequisitos (git, rsync)..."

if ! command -v rsync &> /dev/null; then
    echo "-> 'rsync' no está instalado. Instalando..."
    if [ "$DISTRO" == "arch" ]; then
        sudo pacman -S --noconfirm --needed rsync
    elif [ "$DISTRO" == "debian" ]; then
        sudo apt-get update
        sudo apt-get install -y rsync
    fi
    echo "✅ 'rsync' instalado."
else
    echo "👌 'rsync' ya está instalado."
fi
# (Asumimos que 'git' existe, ya que el usuario usó 'git clone')

# --- 3. Lógica de Auto-Reubicación ---
# Define la "casa" permanente para este repositorio
DEST_BASE="$HOME/.dotfiles"
CURRENT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_NAME=$(basename "$CURRENT_DIR")
DEST_PATH="$DEST_BASE/$PROJECT_NAME"

# Comprueba si el script YA está en su casa permanente
if [ "$CURRENT_DIR" != "$DEST_PATH" ]; then
    echo "--- Reubicando el Repositorio de Instalación ---"
    echo "Moviendo el script a su ubicación permanente: $DEST_PATH"
    
    mkdir -p "$DEST_BASE"
    
    # Este comando ahora funcionará en Arch porque
    # acabamos de instalar 'rsync'
    rsync -a --delete "$CURRENT_DIR/" "$DEST_PATH/"
    
    echo "✅ Reubicación completa. Reiniciando el script desde la nueva ubicación..."
    echo "-------------------------------------------------------------------"
    sleep 2
    
    exec "$DEST_PATH/install.sh" "$@"
fi

# --- 4. Configuración Principal ---
echo "--- Script ejecutándose desde la ubicación permanente ($DEST_PATH) ---"
export WORKDIR="$CURRENT_DIR" # $CURRENT_DIR ahora es $DEST_PATH

# --- 5. Interfaz de Usuario (TUI) para seleccionar el Perfil ---
clear 
echo "Bienvenido al Script de Instalación."
echo "Selecciona el perfil de instalación deseado:"
echo ""
options=(
    "Minimal (Firefox, VLC, VSCode)"
    "Work (Minimal + Obsidian, OnlyOffice)"
    "Creative (Minimal + Inkscape, Krita)"
    "Gaming (Minimal + Lutris, Heroic, Prism)"
    "Virtualization (Minimal + VirtualBox)"
    "Full (Instalar TODO)"
    "Solo Terminal (Utilidades nativas)"
    "Salir"
)
PS3="Elige una opción (1-8): "
select choice in "${options[@]}"; do
    case $choice in
        "${options[0]}") export PROFILE="minimal"; break ;;
        "${options[1]}") export PROFILE="work"; break ;;
        "${options[2]}") export PROFILE="creative"; break ;;
        "${options[3]}") export PROFILE="gaming"; break ;;
        "${options[4]}") export PROFILE="virtualization"; break ;;
        "${options[5]}") export PROFILE="full"; break ;;
        "${options[6]}") export PROFILE="terminal"; break ;;
        "${options[7]}") echo "Saliendo."; exit 0 ;;
        *) echo "Opción inválida: $REPLY." ;;
    esac
done

# --- 6. Lógica Principal de Ejecución ---
echo "🚀 Iniciando la configuración de Linux con el perfil: $PROFILE en un sistema $DISTRO."
echo "-------------------------------------------------------------------"
sleep 2 

modules=(
    "01-system-setup.sh"
    "02-install-apps.sh"
    "03-terminal-setup.sh"
    "04-tweaks-and-config.sh"
)
for module in "${modules[@]}"; do
    clear
    script_path="$WORKDIR/modules/$module"
    if [ -f "$script_path" ]; then
        echo "▶️  Ejecutando módulo: $module (Perfil: $PROFILE)"
        chmod +x "$script_path"
        if ! "$script_path"; then
            echo "❌ Error en el módulo '$module'. La instalación se ha detenido."
            exit 1
        fi
        echo "✅ Módulo finalizado: $module"
        echo "-------------------------------------------------------------------"
        echo "(Siguiente módulo en 2 segundos...)"
        sleep 2
    else
        echo "⚠️  Aviso: Módulo no encontrado, saltando: $script_path"
        echo "-------------------------------------------------------------------"
        sleep 2
    fi
done

# --- 7. Generación de Alias ---
clear
echo "▶️  Ejecutando generador de alias de Flatpak..."
alias_script_path="$WORKDIR/modules/update-flatpak-aliases.sh"
if [ -f "$alias_script_path" ]; then
    chmod +x "$alias_script_path"
    if ! "$alias_script_path"; then
        echo "❌ Error en el script 'update-flatpak-aliases.sh'."
        exit 1
    fi
    echo "✅ Generador de alias finalizado."
    echo "-------------------------------------------------------------------"
    echo "(Lanzamiento final en 2 segundos...)"
    sleep 2
else
    echo "⚠️  Aviso: No se encontró 'update-flatpak-aliases.sh'. Saltando."
fi

# --- 8. Lanzamiento Final ---
clear
echo "🎉 ¡Todos los módulos se completaron con éxito!"
echo "A partir de ahora, el repositorio de este script vive en $DEST_PATH"
echo "Puedes actualizarlo con 'git pull' y usar el alias 'update'."
echo ""
echo "Se recomienda reiniciar el sistema para que todos los cambios surtan efecto."
echo "🚀 ¡Lanzando fastfetch en kitty para la gran final!"
nohup kitty zsh -c "fastfetch; zsh" >/dev/null 2...
exit 0