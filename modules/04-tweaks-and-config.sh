#!/bin/bash

# Activa el modo estricto
set -e

echo "--- Módulo 4: Ajustes y Configuraciones Personales ---"

# --- Copia de Dotfiles ---
# Copia las configuraciones desde la carpeta 'config' del repositorio a ~/.config
CONFIG_DIR=$(dirname "$0")/../config

if [ -d "$CONFIG_DIR" ]; then
    echo "⚙️  Copiando archivos de configuración (dotfiles)..."
    # -r para copiar directorios, -T para tratar el destino como un archivo normal
    # Esto asegura que si ~/.config/kitty no existe, se cree.
    if [ -d "$CONFIG_DIR/kitty" ]; then
        cp -rT "$CONFIG_DIR/kitty" "$HOME/.config/kitty"
        echo "✅ Configuración de Kitty copiada."
    fi
    if [ -d "$CONFIG_DIR/fastfetch" ]; then
        cp -rT "$CONFIG_DIR/fastfetch" "$HOME/.config/fastfetch"
        echo "✅ Configuración de Fastfetch copiada."
    fi
else
    echo "⚠️  No se encontró la carpeta 'config'. Saltando copia de dotfiles."
fi

# --- Ajustes Específicos de Arch (Ejemplos) ---
if [ "$DISTRO" == "arch" ]; then
    echo "⚙️  Aplicando ajustes específicos para Arch..."

    # Habilitar "ILoveCandy" en pacman.conf si no está ya
    if ! grep -q "ILoveCandy" /etc/pacman.conf; then
        sudo sed -i '/#Color/a ILoveCandy' /etc/pacman.conf
        echo "🍬 ¡ILoveCandy activado!"
    fi

    # Habilitar Multilib
    if grep -q "#\[multilib\]" /etc/pacman.conf; then
        echo "Habilitando repositorio Multilib..."
        sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
        sudo pacman -Syy
        echo "✅ Repositorio Multilib activado."
    fi
fi

# --- Configuración de GRUB para Dual Boot (Ejemplo) ---
# Descomenta esta sección si quieres automatizarla
# if [ -f /etc/default/grub ]; then
#   if grep -q "GRUB_DISABLE_OS_PROBER=true" /etc/default/grub; then
#       echo "⚙️  Configurando GRUB para detectar otros sistemas operativos..."
#       sudo sed -i 's/GRUB_DISABLE_OS_PROBER=true/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
#       sudo pacman -S --noconfirm os-prober # O 'sudo apt install os-prober'
#       sudo grub-mkconfig -o /boot/grub/grub.cfg
#       echo "✅ GRUB configurado para dual boot."
#   fi
# fi

echo "--- Módulo 4 Finalizado ---"
