#!/bin/bash
# Activa el modo estricto
set -e

echo "--- Módulo 2: Instalación de Aplicaciones (Perfil: $PROFILE) ---"

# --- 1. Definición de Listas de Aplicaciones ---
# (Listas de apps sin cambios)
apps_flatpak_minimal=(
    org.mozilla.firefox
    org.videolan.vlc
    com.visualstudio.code
)
apps_flatpak_work=(
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
native_minimal_arch=(btop nsnake fastfetch)
native_minimal_debian=(btop nsnake fastfetch)
native_extras_arch=(hollywood asciiquarium)
native_extras_debian=(hollywood)


# --- 2. Funciones de Instalación ---
# (Funciones install_native_utils e install_flatpaks sin cambios)
install_native_utils() {
    local profile_type=$1
    echo "⚙️  Instalando utilidades nativas de terminal (Perfil: $profile_type)..."
    if [ "$DISTRO" == "arch" ]; then
        echo "-> Usando yay (Arch)..."
        yay -S --noconfirm --needed "${native_minimal_arch[@]}"
        if [ "$profile_type" == "full" ]; then
            yay -S --noconfirm --needed "${native_extras_arch[@]}"
        fi
    elif [ "$DISTRO" == "debian" ]; then
        echo "-> Usando apt (Debian/Ubuntu)..."
        sudo apt-get install -y "${native_minimal_debian[@]}"
        if [ "$profile_type" == "full" ]; then
            sudo apt-get install -y "${native_extras_debian[@]}"
        fi
    else
        echo "⚠️  Distro no compatible '$DISTRO' en Módulo 2. Saltando utilidades nativas."
    fi
    echo "✅ Utilidades nativas instaladas."
}

install_flatpaks() {
    local apps_to_install=("$@")
    if [ ${#apps_to_install[@]} -eq 0 ]; then
        echo "-> No se seleccionaron aplicaciones Flatpak para este perfil."
        return
    fi
    echo "⚙️  Instalando ${#apps_to_install[@]} aplicaciones de Flathub..."
    printf "  - %s\n" "${apps_to_install[@]}"
    flatpak install -y --noninteractive flathub "${apps_to_install[@]}"
    echo "✅ Aplicaciones de Flathub instaladas."
}

# --- 3. Lógica de Perfil (No-interactiva) ---
# (Sección case "$PROFILE" sin cambios)
declare -a final_flatpak_list
native_profile_type="minimal"
case "$PROFILE" in
    "minimal")
        final_flatpak_list=( "${apps_flatpak_minimal[@]}" )
        native_profile_type="minimal"
        ;;
    "work")
        final_flatpak_list=(
            "${apps_flatpak_minimal[@]}"
            "${apps_flatpak_work[@]}"
        )
        native_profile_type="full"
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
        native_profile_type="full"
        ;;
    *)
        echo "⚠️  Perfil '$PROFILE' desconocido en 02-install-apps.sh. No se instalará software."
        ;;
esac

# --- 4. Ejecución de Instalación ---
install_flatpaks "${final_flatpak_list[@]}"
install_native_utils "$native_profile_type"

# ==== SECCIÓN DE ALIAS ESTÁTICOS ELIMINADA ====
# (La lógica de generación de alias estáticos se eliminó de aquí)

# --- 5. Finalización de Flatpak ---
echo "⚙️  Actualizando la base de datos de Flatpak para crear 'alias' (symlinks)..."
# (Esto sigue siendo útil para el sistema de 'alias' oficial)
flatpak update --appstream
echo "✅ 'Alias' de Flatpak generados."


echo "--- Módulo 2 Finalizado ---"