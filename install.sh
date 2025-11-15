#!/bin/bash
# Activa el modo estricto
set -e

# --- 1. Lógica de Auto-Reubicación ---
# Define la "casa" permanente para este repositorio
DEST_DIR="$HOME/.dotfiles"

# Obtiene el directorio actual (absoluto) del script
CURRENT_DIR=$(cd "$(dirname "$0")" && pwd)

# Comprueba si el script YA está en su casa permanente
if [ "$CURRENT_DIR" != "$DEST_DIR" ]; then
    echo "--- Reubicando el Repositorio de Instalación ---"
    echo "Moviendo el script a su ubicación permanente: $DEST_DIR"
    
    # Asegura que el directorio exista
    mkdir -p "$DEST_DIR"
    
    # Usa rsync para copiar/sincronizar el repo completo
    # -a (archive) preserva permisos
    # --delete asegura que el destino sea una copia exacta
    # El "/" al final de CURRENT_DIR es importante: copia el *contenido*
    rsync -a --delete "$CURRENT_DIR/" "$DEST_DIR/"
    
    echo "✅ Reubicación completa. Reiniciando el script desde la nueva ubicación..."
    echo "-------------------------------------------------------------------"
    sleep 2
    
    # 'exec' reemplaza el proceso actual con el nuevo
    # Pasa todos los argumentos originales (si los hubiera)
    exec "$DEST_DIR/install.sh" "$@"
fi

# --- 2. Configuración Principal ---
# Si el script llega aquí, significa que ya está en $DEST_DIR
echo "--- Script ejecutándose desde la ubicación permanente ($DEST_DIR) ---"

# Exporta el WORKDIR absoluto para que los módulos (como 04)
# puedan usarlo para crear alias (como 'update')
export WORKDIR="$CURRENT_DIR"

# --- 3. Detección del Sistema Operativo ---
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

# --- 4. Interfaz de Usuario (TUI) para seleccionar el Perfil ---
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
        "${options[0]}") # Minimal
            export PROFILE="minimal"
            break
            ;;
        "${options[1]}") # Work
            export PROFILE="work"
            break
            ;;
        "${options[2]}") # Creative
            export PROFILE="creative"
            break
            ;;
        "${options[3]}") # Gaming
            export PROFILE="gaming"
            break
            ;;
        "${options[4]}") # Virtualization
            export PROFILE="virtualization"
            break
            ;;
        "${options[5]}") # Full
            export PROFILE="full"
            break
            ;;
        "${options[6]}") # Solo Terminal
            export PROFILE="terminal"
            break
            ;;
        "${options[7]}") # Salir
            echo "Saliendo. No se instaló nada."
            exit 0
            ;;
        *) # Opción inválida
            echo "Opción inválida: $REPLY. Intenta de nuevo."
            ;;
    esac
done

# --- 5. Lógica Principal de Ejecución ---
echo "🚀 Iniciando la configuración de Linux con el perfil: $PROFILE en un sistema $DISTRO."
echo "-------------------------------------------------------------------"
sleep 2 

modules=(
    "01-system-setup.sh"
    "02-install-apps.sh"
    "03-terminal-setup.sh"
    "04-tweaks-and-config.sh"
)

# Ejecutar cada módulo
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

# --- 6. Generación de Alias ---
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

# --- 7. Lanzamiento Final ---
clear
echo "🎉 ¡Todos los módulos se completaron con éxito!"
echo "A partir de ahora, el repositorio de este script vive en $DEST_DIR"
echo "Puedes actualizarlo con 'git pull' y usar el alias 'update'."
echo ""
echo "Se recomienda reiniciar el sistema para que todos los cambios surtan efecto."
echo "🚀 ¡Lanzando fastfetch en kitty para la gran final!"

nohup kitty fastfetch >/dev/null 2>&1 &

exit 0