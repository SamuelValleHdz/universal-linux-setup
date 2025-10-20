 #!/bin/bash

# Activa el modo estricto
set -e

echo "--- Módulo 2: Instalación de Aplicaciones ---"

# --- Listas de Aplicaciones Universales (Flatpak) ---
# Usamos los IDs de Flathub (ej: com.discordapp.Discord)
apps_flatpak_minimal=(
    com.visualstudio.code
    org.mozilla.firefox
)

apps_flatpak_full=(
    com.discordapp.Discord
    md.obsidian.Obsidian
    org.kde.krita
    org.inkscape.Inkscape
    com.valvesoftware.Steam
    # ...añade más aplicaciones de Flathub aquí
)

# --- Listas de Aplicaciones Nativas (Terminal y Sistema) ---
# Herramientas que funcionan mejor instaladas de forma nativa
apps_native_minimal_arch=(kitty btop nsnake fastfetch)
apps_native_minimal_debian=(kitty btop nsnake fastfetch)

apps_native_full_arch=(hollywood asciiquarium)
# Para Debian/Ubuntu, 'hollywood' está en los repos, pero 'asciiquarium' no.
# Se podría instalar 'asciiquarium' via snap o cpan, pero lo omitimos para mantener el script simple.
apps_native_full_debian=(hollywood)


# --- Instalación de Flatpaks ---
echo "⚙️  Instalando aplicaciones de Flathub..."
flatpak install -y --noninteractive flathub "${apps_flatpak_minimal[@]}"

if [ "$PROFILE" == "full" ]; then
    flatpak install -y --noninteractive flathub "${apps_flatpak_full[@]}"
fi
echo "✅ Aplicaciones de Flathub instaladas."


# --- Instalación de Aplicaciones Nativas ---
echo "⚙️  Instalando aplicaciones nativas y de terminal..."
if [ "$DISTRO" == "arch" ]; then
    yay -S --noconfirm --needed "${apps_native_minimal_arch[@]}"
    if [ "$PROFILE" == "full" ]; then
        yay -S --noconfirm --needed "${apps_native_full_arch[@]}"
    fi
elif [ "$DISTRO" == "debian" ]; then
    sudo apt-get install -y "${apps_native_minimal_debian[@]}"
    if [ "$PROFILE" == "full" ]; then
        sudo apt-get install -y "${apps_native_full_debian[@]}"
    fi
fi
echo "✅ Aplicaciones nativas instaladas."

echo "--- Módulo 2 Finalizado ---"
