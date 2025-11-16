#!/bin/bash

# Activa el modo estricto
set -e

echo "--- Módulo 1: Configuración del Sistema Base ---"

# --- Listas de paquetes del sistema ---
pkgs_build_arch=(base-devel)
pkgs_build_debian=(build-essential)

# Paquetes básicos
# ==== INICIO DE LA CORRECCIÓN ====
# Añadido 'python-venv' (el equivalente de Arch a python3-venv)
# como dependencia para pipx.
pkgs_essentials_arch=(git curl zsh kitty bluez bluez-utils python-pip python-venv pipx)
# ==== FIN DE LA CORRECCIÓN ====
pkgs_essentials_debian=(git curl zsh kitty bluez software-properties-common python3-pip python3-venv pipx)

# --- Instalación de paquetes nativos ---
echo "⚙️  Instalando paquetes esenciales del sistema (incl. zsh, kitty y pip)..."

if [ "$DISTRO" == "arch" ]; then
    sudo pacman -Syu --noconfirm --needed "${pkgs_build_arch[@]}" "${pkgs_essentials_arch[@]}"
elif [ "$DISTRO" == "debian" ]; then
    sudo apt-get update
    sudo apt-get install -y "${pkgs_build_debian[@]}" "${pkgs_essentials_debian[@]}"
    
    # Añadir el PPA de Fastfetch
    echo "⚙️  Añadiendo PPA de Fastfetch para Ubuntu/Debian..."
    sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch
    sudo apt-get update
fi

echo "✅ Paquetes esenciales instalados."

# --- Instalación de yay (Solo para Arch) ---
# (El resto del script no cambia...)
if [ "$DISTRO" == "arch" ]; then
    if ! command -v yay &> /dev/null; then
        echo "⚙️  Instalando yay..."
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        (cd /tmp/yay && makepkg -si --noconfirm)
        rm -rf /tmp/yay
        echo "✅ yay instalado."
    else
        echo "👌 yay ya está instalado."
    fi
fi

# --- Instalación y configuración de Flatpak ---
# (El resto del script no cambia...)
if ! command -v flatpak &> /dev/null; then
    echo "⚙️  Instalando Flatpak..."
    if [ "$DISTRO" == "arch" ]; then
        sudo pacman -S --noconfirm flatpak
    elif [ "$DISTRO" == "debian" ]; then
        sudo apt-get install -y flatpak
    fi
    flatpak remote-add --if-not-exists flub https://flathub.org/repo/flathub.flatpakrepo
    echo "✅ Flatpak instalado y configurado."
else
    echo "👌 Flatpak ya está instalado."
fi

echo "--- Módulo 1 Finalizado ---"