#!/bin/bash

# Activa el modo estricto
set -e

echo "--- Módulo 1: Configuración del Sistema Base ---"

# --- Listas de paquetes del sistema ---
pkgs_build_arch=(base-devel)
pkgs_build_debian=(build-essential)

# Paquetes básicos
# AÑADIMOS 'python-pip' y 'python3-pip' para las dependencias de npm (node-gyp)
pkgs_essentials_arch=(git curl zsh kitty bluez bluez-utils python-pip)
pkgs_essentials_debian=(git curl zsh kitty bluez software-properties-common python3-pip)

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
if ! command -v flatpak &> /dev/null; then
    echo "⚙️  Instalando Flatpak..."
    if [ "$DISTRO" == "arch" ]; then
        sudo pacman -S --noconfirm flatpak
    elif [ "$DISTRO" == "debian" ]; then
        sudo apt-get install -y flatpak
    fi
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    echo "✅ Flatpak instalado y configurado."
else
    echo "👌 Flatpak ya está instalado."
fi

echo "--- Módulo 1 Finalizado ---"