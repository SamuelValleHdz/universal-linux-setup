#!/bin/bash
# Activa el modo estricto
set -e
echo "--- Módulo 2: Instalación de Aplicaciones (Perfil: $PROFILE) ---"

# --- 1. Definición de Listas de Aplicaciones ---
# (Listas de Flatpak)
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

# (Listas Nativas Mínimas)
native_minimal_arch=(btop nsnake fastfetch)
native_minimal_debian=(btop nsnake fastfetch)

# (Listas Nativas Opcionales)
native_extras_arch=(hollywood asciiquarium)
native_extras_debian=(hollywood)
native_virtualization_arch=(virtualbox virtualbox-host-dkms virtualbox-ext-oracle)
native_virtualization_debian=(virtualbox virtualbox-dkms)

# --- 2. Funciones de Instalación ---

# Instala paquetes nativos (apt/yay)
# Acepta una lista de paquetes
install_native_utils() {
    local apps_to_install=("$@")
    if [ ${#apps_to_install[@]} -eq 0 ]; then
        echo "-> No se seleccionaron aplicaciones nativas para este perfil."
        return
    fi
    echo "⚙️  Instalando ${#apps_to_install[@]} aplicaciones nativas..."
    printf "  - %s\n" "${apps_to_install[@]}"
    
    if [ "$DISTRO" == "arch" ]; then
        echo "-> Usando yay (Arch)..."
        # --needed evita reinstalar lo que ya está
        yay -S --noconfirm --needed "${apps_to_install[@]}"
    elif [ "$DISTRO" == "debian" ]; then
        echo "-> Usando apt (Debian/Ubuntu)..."
        sudo apt-get install -y "${apps_to_install[@]}"
    else
        echo "⚠️  Distro no compatible '$DISTRO' en Módulo 2."
    fi
    echo "✅ Aplicaciones nativas instaladas."
}

# Instala paquetes de Flatpak
# Acepta una lista de paquetes
install_flatpaks() {
    local apps_to_install=("$@")
    if [ ${#apps_to_install[@]} -eq 0 ]; then
        echo "-> No se seleccionaron aplicaciones Flatpak para este perfil."
        return
    fi
    echo "⚙️  Instalando ${#apps_to_install[@]} aplicaciones de Flathub..."
    printf "  - %s\n" "${apps_to_install[@]}"
    
    # Este comando es idempotente: instala lo que falta
    # y se salta lo que ya está. No se necesita --reinstall.
    flatpak install -y --noninteractive flathub "${apps_to_install[@]}"
    echo "✅ Aplicaciones de Flathub instaladas."
}

# --- 3. Lógica de Perfil (No-interactiva) ---
# Construye las listas de instalación basadas en $PROFILE

declare -a final_flatpak_list
declare -a final_native_list

echo "-> Procesando perfil '$PROFILE' para la selección de apps..."
case "$PROFILE" in
    "minimal")
        final_flatpak_list=( "${apps_flatpak_minimal[@]}" )
        if [ "$DISTRO" == "arch" ]; then final_native_list=( "${native_minimal_arch[@]}" ); else final_native_list=( "${native_minimal_debian[@]}" ); fi
        ;;
    "work")
        final_flatpak_list=( "${apps_flatpak_minimal[@]}" "${apps_flatpak_work[@]}" )
        if [ "$DISTRO" == "arch" ]; then final_native_list=( "${native_minimal_arch[@]}" "${native_extras_arch[@]}" ); else final_native_list=( "${native_minimal_debian[@]}" "${native_extras_debian[@]}" ); fi
        ;;
    "creative")
        final_flatpak_list=( "${apps_flatpak_minimal[@]}" "${apps_flatpak_creative[@]}" )
        if [ "$DISTRO" == "arch" ]; then final_native_list=( "${native_minimal_arch[@]}" "${native_extras_arch[@]}" ); else final_native_list=( "${native_minimal_debian[@]}" "${native_extras_debian[@]}" ); fi
        ;;
    "gaming")
        final_flatpak_list=( "${apps_flatpak_minimal[@]}" "${apps_flatpak_gaming[@]}" )
        if [ "$DISTRO" == "arch" ]; then final_native_list=( "${native_minimal_arch[@]}" "${native_extras_arch[@]}" ); else final_native_list=( "${native_minimal_debian[@]}" "${native_extras_debian[@]}" ); fi
        ;;
    "virtualization")
        final_flatpak_list=( "${apps_flatpak_minimal[@]}" )
        if [ "$DISTRO" == "arch" ]; then
            final_native_list=( "${native_minimal_arch[@]}" "${native_virtualization_arch[@]}" )
        else
            final_native_list=( "${native_minimal_debian[@]}" "${native_virtualization_debian[@]}" )
        fi
        ;;
    "full")
        final_flatpak_list=( "${apps_flatpak_minimal[@]}" "${apps_flatpak_work[@]}" "${apps_flatpak_creative[@]}" "${apps_flatpak_gaming[@]}" )
        if [ "$DISTRO" == "arch" ]; then
            final_native_list=( "${native_minimal_arch[@]}" "${native_extras_arch[@]}" "${native_virtualization_arch[@]}" )
        else
            final_native_list=( "${native_minimal_debian[@]}" "${native_extras_debian[@]}" "${native_virtualization_debian[@]}" )
        fi
        ;;
    "terminal")
        # Lista de flatpak vacía
        if [ "$DISTRO" == "arch" ]; then final_native_list=( "${native_minimal_arch[@]}" "${native_extras_arch[@]}" ); else final_native_list=( "${native_minimal_debian[@]}" "${native_extras_debian[@]}" ); fi
        ;;
    *)
        echo "⚠️  Perfil '$PROFILE' desconocido."
        ;;
esac

# --- 4. Ejecución de Instalación ---
install_flatpaks "${final_flatpak_list[@]}"
install_native_utils "${final_native_list[@]}"

# --- 5. Finalización de Flatpak ---
# Sigue siendo útil para actualizar los metadatos del sistema
echo "⚙️  Actualizando la base de datos de AppStream de Flatpak..."
flatpak update --appstream

echo "--- Módulo 2 Finalizado ---"