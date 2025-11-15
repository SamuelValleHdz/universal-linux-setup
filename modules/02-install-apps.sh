#!/bin/bash
#
# MÓDULO 02: INSTALACIÓN DE APLICACIONES
#
# Este script es llamado por 'install.sh' y NO es interactivo.
# Lee las variables $PROFILE y $DISTRO exportadas por el script padre
# para instalar el software correspondiente.
#

# Salir inmediatamente si un comando falla
set -e

# Imprime el perfil que está siendo procesado (definido en install.sh)
echo "--- Módulo 2: Instalación de Aplicaciones (Perfil: $PROFILE) ---"

# --- 1. Definición de Listas de Aplicaciones ---
# Estas son las "listas maestras" de software.
# Para añadir/quitar apps, solo modifica estas listas.

# Perfil base de Flatpak (incluido en 'work', 'creative', 'gaming' y 'full')
apps_flatpak_minimal=(
    org.mozilla.firefox
    org.videolan.VLC
    com.visualstudio.code
)

# Perfiles adicionales de Flatpak
apps_flatpak_work=(
    org.keepassxc.KeePassXC
    md.obsidian.Obsidian
    org.onlyoffice.desktopeditors
)

apps_flatpak_creative=(
    org.inkscape.Inkscape
    org.kde.krita
)

apps_flatpak_gaming=(
    net.lutris.Lutris
    com.heroicgameslauncher.hgl
    org.prismlauncher.PrismLauncher
)

# Herramientas nativas de terminal
# NOTA: zsh y kitty se instalan en el Módulo 01 (son esenciales)
native_minimal_arch=(btop nsnake fastfetch)
native_minimal_debian=(btop nsnake fastfetch)

# Extras "divertidos"
native_extras_arch=(hollywood asciiquarium)
native_extras_debian=(hollywood)


# --- 2. Funciones de Instalación ---

##
# Instala utilidades NATIVAS (apt/yay)
# Argumento 1 ($1): Tipo de perfil nativo ("minimal" o "full")
##
install_native_utils() {
    local profile_type=$1
    echo "⚙️  Instalando utilidades nativas de terminal (Perfil: $profile_type)..."

    # $DISTRO es establecida por install.sh
    if [ "$DISTRO" == "arch" ]; then
        echo "-> Usando yay (Arch)..."
        # Instalar la base mínima siempre
        yay -S --noconfirm --needed "${native_minimal_arch[@]}"
        
        # Instalar extras solo si el perfil es "full"
        if [ "$profile_type" == "full" ]; then
            yay -S --noconfirm --needed "${native_extras_arch[@]}"
        fi

    elif [ "$DISTRO" == "debian" ]; then
        echo "-> Usando apt (Debian/Ubuntu)..."
        # Instalar la base mínima siempre
        sudo apt-get install -y "${native_minimal_debian[@]}"
        
        # Instalar extras solo si el perfil es "full"
        if [ "$profile_type" == "full" ]; then
            sudo apt-get install -y "${native_extras_debian[@]}"
        fi
        
    else
        echo "⚠️  Distro no compatible '$DISTRO' en Módulo 2. Saltando utilidades nativas."
    fi
    echo "✅ Utilidades nativas instaladas."
}

##
# Instala aplicaciones FLATPAK
# Argumentos ($@): Lista de IDs de flatpak a instalar
##
install_flatpaks() {
    # Copia todos los argumentos pasados a un array local
    local apps_to_install=("$@")

    # Revisa si el array está vacío
    if [ ${#apps_to_install[@]} -eq 0 ]; then
        echo "-> No se seleccionaron aplicaciones Flatpak para este perfil."
        return
    fi
    
    echo "⚙️  Instalando ${#apps_to_install[@]} aplicaciones de Flathub..."
    
    # Imprime la lista de lo que se va a instalar
    printf "  - %s\n" "${apps_to_install[@]}"
    
    # El comando de instalación
    flatpak install -y --noninteractive flathub "${apps_to_install[@]}"
    echo "✅ Aplicaciones de Flathub instaladas."
}


# --- 3. Lógica de Perfil (No-interactiva) ---
# Aquí se decide qué listas usar en base al $PROFILE
# que se obtuvo del menú en 'install.sh'

# Array final que se pasará a la función install_flatpaks
declare -a final_flatpak_list
    
# Perfil para utilidades nativas ("minimal" o "full")
# (Se eliminó 'local' de la siguiente línea)
native_profile_type="minimal"

echo "-> Procesando perfil '$PROFILE' para la selección de apps..."


case "$PROFILE" in
    "minimal")
        final_flatpak_list=( "${apps_flatpak_minimal[@]}" )
        native_profile_type="minimal" # Solo lo básico
        ;;
    "work")
        final_flatpak_list=(
            "${apps_flatpak_minimal[@]}"
            "${apps_flatpak_work[@]}"
        )
        native_profile_type="full" # Perfil "Work" obtiene utilidades extra
        ;;
    "creative")
        final_flatpak_list=(
            "${apps_flatpak_minimal[@]}"
            "${apps_flatpak_creative[@]}"
        )
        native_profile_type="full"
        ;;
    "gaming")
        final_flatpak_list=(
            "${apps_flatpak_minimal[@]}"
            "${apps_flatpak_gaming[@]}"
        )
        native_profile_type="full"
        ;;
    "full")
        final_flatpak_list=(
            "${apps_flatpak_minimal[@]}"
            "${apps_flatpak_work[@]}"
            "${apps_flatpak_creative[@]}"
            "${apps_flatpak_gaming[@]}"
        )
        native_profile_type="full"
        ;;
    "terminal")
        # La lista final_flatpak_list permanece vacía
        native_profile_type="full"
        ;;
    *)
        echo "⚠️  Perfil '$PROFILE' desconocido en 02-install-apps.sh. No se instalará software."
        # Los arrays quedan vacíos, no se instalará nada.
        ;;
esac

# --- 4. Ejecución ---
# Llama a las funciones con las listas decididas

install_flatpaks "${final_flatpak_list[@]}"
install_native_utils "$native_profile_type"

echo "⚙️  Actualizando la base de datos de Flatpak para crear 'alias' (symlinks)..."
# Este comando fuerza a Flatpak a generar los enlaces cortos (ej: 'code')
# que se colocan en /var/lib/flatpak/exports/bin
# y que el $PATH del Módulo 3 utiliza.
flatpak update --appstream

echo "✅ 'Alias' de Flatpak generados."

echo "--- Módulo 2 Finalizado ---"