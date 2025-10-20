#!/bin/bash

# Activa el modo estricto: si un comando falla, el script se detiene.
set -e

# --- Configuración por Defecto ---
PROFILE="full"  # El perfil predeterminado es 'full'
# Establece el directorio de trabajo en la ubicación del script
WORKDIR=$(dirname "$0")

# --- Función para mostrar cómo usar el script ---
usage() {
    echo "Uso: $0 [--profile <full|minimal>] [--help]"
    echo ""
    echo "Opciones:"
    echo "  --profile <full|minimal>  Define el perfil de instalación (por defecto: full)."
    echo "  --help                      Muestra este mensaje de ayuda."
    exit 1
}

# --- Procesar los argumentos de la línea de comandos ---
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --profile)
            # Verifica que el siguiente argumento sea 'full' o 'minimal'
            if [[ "$2" == "full" || "$2" == "minimal" ]]; then
                PROFILE="$2"
                shift # Consume el valor del argumento
            else
                echo "Error: Perfil inválido '$2'. Usa 'full' o 'minimal'." >&2
                usage
            fi
            ;;
        --help)
            usage
            ;;
        *)
            echo "Error: Parámetro desconocido: $1"
            usage
            ;;
    esac
    shift # Pasa al siguiente argumento
done

# --- Detección del Sistema Operativo ---
export DISTRO=""   # Familia de la Distro (arch, debian)

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

# --- Exportar variables para que los sub-scripts puedan usarlas ---
export PROFILE
export DISTRO

# --- Lógica Principal de Ejecución ---
echo "🚀 Iniciando la configuración de Linux con el perfil: $PROFILE en un sistema $DISTRO."
echo "-------------------------------------------------------------------"

# Definir los módulos que se ejecutarán en orden
modules=(
    "01-system-setup.sh"
    "02-install-apps.sh"
    "03-terminal-setup.sh"
    "04-tweaks-and-config.sh"
)

# Ejecutar cada módulo de la lista
for module in "${modules[@]}"; do
    script_path="$WORKDIR/modules/$module"
    if [ -f "$script_path" ]; then
        echo "▶️  Ejecutando módulo: $module"
        # Darle permisos de ejecución por si acaso
        chmod +x "$script_path"

        # Ejecutar el módulo y verificar si falla
        if ! "$script_path"; then
            echo "❌ Error en el módulo '$module'. La instalación se ha detenido."
            exit 1
        fi

        echo "✅ Módulo finalizado: $module"
        echo "-------------------------------------------------------------------"
    else
        echo "⚠️  Aviso: Módulo no encontrado, saltando: $script_path"
        echo "-------------------------------------------------------------------"
    fi
done

echo "🎉 ¡Todos los módulos se completaron con éxito!"
echo "Se recomienda reiniciar el sistema para que todos los cambios surtan efecto."
