#!/bin/bash

# Activa el modo estricto
set -e

echo "--- Módulo 1: Configuración del Sistema Base ---"

# --- Listas de paquetes del sistema ---
# Herramientas para compilar software, esenciales para AUR o para instalar paquetes con pip-
pkgs_build_arch=(base-devel)
pkgs_build_debian=(build-essential)

# Paquetes básicos (¡kitty añadido aquí!)
pkgs_essentials_arch=(git curl zsh kitty bluez bluez-utils)
pkgs_essentials_debian=(git curl zsh kitty bluez)

# --- Instalación de paquetes nativos ---
echo "⚙️  Instalando paquetes esenciales del sistema..."

if [ "$DISTRO" == "arch" ]; then
    sudo pacman -Syu --noconfirm --needed "${pkgs_build_arch[@]}" "${pkgs_essentials_arch[@]}"
elif [ "$DISTRO" == "debian" ]; then
    sudo apt-get update
    sudo apt-get install -y "${pkgs_build_debian[@]}" "${pkgs_essentials_debian[@]}"
fi

echo "✅ Paquetes esenciales instalados."

# --- Instalación de yay (Solo para Arch) ---
if [ "$DISTRO" == "arch" ]; then
    if ! command -v yay &> /dev/null; then
        echo "⚙️  Instalando yay..."
        # Clonamos, construimos e instalamos yay, luego limpiamos
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        (cd /tmp/yay && makepkg -si --noconfirm)
        rm -rf /tmp/yay
        echo "✅ yay instalado."
    else
        echo "👌 yay ya está instalado."
    fi
fi

# --- Instalación y configuración de Flatpak ---
if ! command -v flatpak &> /dev/null; then
    echo "⚙️  Instalando Flatpak..."
    if [ "$DISTRO" == "arch" ]; then
        sudo pacman -S --noconfirm flatpak
    elif [ "$DISTRO" == "debian" ]; then
        sudo apt-get install -y flatpak
    fi
    # Añadimos el repositorio de Flathub, la tienda principal de Flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    echo "✅ Flatpak instalado y configurado."
else
    echo "👌 Flatpak ya está instalado."
fi

echo "--- Módulo 1 Finalizado ---"
