#!/bin/bash
# Activa el modo estricto
set -e

echo "--- Módulo 2: Instalación de Aplicaciones (Perfil: $PROFILE) ---"

# --- 1. Definición de Listas de Aplicaciones ---
# (Listas de Flatpak sin cambios)
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

# (VirtualBox ELIMINADO de aquí)
native_minimal_arch=(btop nsnake fastfetch)
native_minimal_debian=(btop nsnake fastfetch)

# (Extras sin cambios)
native_extras_arch=(hollywood asciiquarium)
native_extras_debian=(hollywood)

# --- NUEVA CATEGORÍA NATIVA ---
# En Arch, podemos incluir el Extension Pack desde el AUR (yay)
native_virtualization_arch=(virtualbox virtualbox-host-dkms virtualbox-ext-oracle)
# En Debian, no podemos incluir 'virtualbox-ext-pack' porque
# requiere aceptar una EULA interactiva que detendría el script.
# Lo manejaremos en el Módulo 4.
native_virtualization_debian=(virtualbox virtualbox-dkms)


# --- 2. Funciones de Instalación ---

# ==== FUNCIÓN MODIFICADA ====
# Ya no acepta "minimal"/"full", sino una lista de paquetes
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
        yay -S --noconfirm --needed "${apps_to_install[@]}"
    elif [ "$DISTRO" == "debian" ]; then
        echo "-> Usando apt (Debian/Ubuntu)..."
        sudo apt-get install -y "${apps_to_install[@]}"
    else
        echo "⚠️  Distro no compatible '$DISTRO' en Módulo 2."
    fi
    echo "✅ Aplicaciones nativas instaladas."
}

# (Función install_flatpaks sin cambios)
install_flatpaks() {
    local apps_to_install=("$@")
    # ... (código sin cambios) ...
}


# --- 3. Lógica de Perfil (No-interactiva) ---
# ==== LÓGICA MODIFICADA ====
# Ahora creamos DOS listas: una para flatpak, una para nativas

declare -a final_flatpak_list
declare -a final_native_list

echo "-> Procesando perfil '$PROFILE' para la selección de apps..."

case "$PROFILE" in
    "minimal")
        final_flatpak_list=( "${apps_flatpak_minimal[@]}" )
        final_native_list=( "${native_minimal_arch[@]}" )
        ;;
    "work")
        final_flatpak_list=(
            "${apps_flatpak_minimal[@]}"
            "${apps_flatpak_work[@]}"
        )
        final_native_list=(
            "${native_minimal_arch[@]}"
            "${native_extras_arch[@]}"
        )
        ;;
    "creative")
        final_flatpak_list=(
            "${apps_flatpak_minimal[@]}"
            "${apps_flatpak_creative[@]}"
        )
        final_native_list=(
            "${native_minimal_arch[@]}"
            "${native_extras_arch[@]}"
        )
        ;;
    "gaming")
        final_flatpak_list=(
            "${apps_flatpak_minimal[@]}"
            "${apps_flatpak_gaming[@]}"
        )
        final_native_list=(
            "${native_minimal_arch[@]}"
            "${native_extras_arch[@]}"
        )
        ;;
    
    # --- NUEVO PERFIL ---
    "virtualization")
        final_flatpak_list=( "${apps_flatpak_minimal[@]}" )
        # Distingue entre Arch y Debian para la lista nativa
        if [ "$DISTRO" == "arch" ]; then
            final_native_list=(
                "${native_minimal_arch[@]}"
                "${native_virtualization_arch[@]}"
            )
        else
            final_native_list=(
                "${native_minimal_debian[@]}"
                "${native_virtualization_debian[@]}"
            )
        fi
        ;;

    "full")
        final_flatpak_list=(
            "${apps_flatpak_minimal[@]}"
            "${apps_flatpak_work[@]}"
            "${apps_flatpak_creative[@]}"
            "${apps_flatpak_gaming[@]}"
        )
        if [ "$DISTRO" == "arch" ]; then
            final_native_list=(
                "${native_minimal_arch[@]}"
                "${native_extras_arch[@]}"
                "${native_virtualization_arch[@]}"
            )
        else
            final_native_list=(
                "${native_minimal_debian[@]}"
                "${native_extras_debian[@]}"
                "${native_virtualization_debian[@]}"
            )
        fi
        ;;
    "terminal")
        # Lista de flatpak vacía
        final_native_list=(
            "${native_minimal_arch[@]}"
            "${native_extras_arch[@]}"
        )
        ;;
    *)
        echo "⚠️  Perfil '$PROFILE' desconocido."
        ;;
esac

# --- 4. Ejecución de Instalación ---
# ==== LLAMADA MODIFICADA ====
install_flatpaks "${final_flatpak_list[@]}"
install_native_utils "${final_native_list[@]}" # Pasamos la lista

# --- 5. Finalización de Flatpak ---
# (Sin cambios)
echo "⚙️  Actualizando la base de datos de Flatpak..."
flatpak update --appstream
echo "✅ 'Alias' de Flatpak generados."


echo "--- Módulo 2 Finalizado ---"