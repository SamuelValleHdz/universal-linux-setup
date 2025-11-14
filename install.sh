#!/bin/bash

# Activa el modo estricto
set -e

# Establece el directorio de trabajo
WORKDIR=$(dirname "$0")

# --- Detección del Sistema Operativo ---
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

# --- Interfaz de Usuario (TUI) para seleccionar el Perfil ---
clear # Limpia la pantalla antes de mostrar el menú
echo "Bienvenido al Script de Instalación."
echo "Selecciona el perfil de instalación deseado:"
echo ""

options=(
    "Minimal (Firefox, VLC, VSCode)"
    "Work (Minimal + Obsidian, OnlyOffice)"
    "Creative (Minimal + Inkscape, Krita)"
    "Gaming (Minimal + Lutris, Heroic, Prism)"
    "Full (Instalar TODO)"
    "Solo Terminal (Utilidades nativas)"
    "Salir"
)

PS3="Elige una opción (1-7): "
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
        "${options[4]}") # Full
            export PROFILE="full"
            break
            ;;
        "${options[5]}") # Solo Terminal
            export PROFILE="terminal"
            break
            ;;
        "${options[6]}") # Salir
            echo "Saliendo. No se instaló nada."
            exit 0
            ;;
        *) # Opción inválida
            echo "Opción inválida: $REPLY. Intenta de nuevo."
            ;;
    esac
done

# --- Exportar variables para que los sub-scripts puedan usarlas ---
export DISTRO
export PROFILE

# --- Lógica Principal de Ejecución ---
echo "🚀 Iniciando la configuración de Linux con el perfil: $PROFILE en un sistema $DISTRO."
echo "-------------------------------------------------------------------"
sleep 2 # Pausa breve para leer el mensaje

# Definir los módulos
modules=(
    "01-system-setup.sh"
    "02-install-apps.sh"
    "03-terminal-setup.sh"
    "04-tweaks-and-config.sh"
)

# Ejecutar cada módulo
for module in "${modules[@]}"; do
    
    # ==== CAMBIO ESTÉTICO 1: LIMPIAR PANTALLA ====
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

# ==== CAMBIO ESTÉTICO 2: LANZAR FASTFETCH ====
clear
echo "🎉 ¡Todos los módulos se completaron con éxito!"
echo "Se recomienda reiniciar el sistema para que todos los cambios surtan efecto."
echo ""
echo "🚀 ¡Lanzando fastfetch en kitty para la gran final!"

# 'nohup' evita que el proceso muera si la terminal se cierra
# '&' lo ejecuta en segundo plano (desacopla el script)
# '>/dev/null 2>&1' redirige toda la salida para no "ensuciar" la terminal actual
nohup kitty fastfetch >/dev/null 2>&1 &

exit 0