#!/bin/bash
# Enable strict mode
set -e

echo "--- Module GPU: Graphics Driver Detection & Setup ---"

# Función para Arch Linux
install_gpu_arch() {
    # Detectar GPU
    if lspci | grep -i "NVIDIA" &> /dev/null; then
        echo "[!] NVIDIA GPU detected."
        echo "-> Installing NVIDIA DKMS drivers and Vulkan support..."
        # nvidia-dkms es mejor para compatibilidad con kernels variados (como zen o lts)
        sudo pacman -S --noconfirm --needed \
            nvidia-dkms \
            nvidia-utils \
            lib32-nvidia-utils \
            nvidia-settings \
            vulkan-icd-loader \
            lib32-vulkan-icd-loader
            
    elif lspci | grep -i "AMD" &> /dev/null || lspci | grep -i "Radeon" &> /dev/null; then
        echo "[!] AMD GPU detected."
        echo "-> Installing AMD Mesa/Vulkan drivers..."
        sudo pacman -S --noconfirm --needed \
            mesa \
            lib32-mesa \
            xf86-video-amdgpu \
            vulkan-radeon \
            lib32-vulkan-radeon \
            vulkan-icd-loader \
            lib32-vulkan-icd-loader

    elif lspci | grep -i "Intel" &> /dev/null && lspci | grep -i "VGA" &> /dev/null; then
        echo "[!] Intel GPU detected."
        echo "-> Installing Intel Mesa/Vulkan drivers..."
        sudo pacman -S --noconfirm --needed \
            mesa \
            lib32-mesa \
            vulkan-intel \
            lib32-vulkan-intel \
            vulkan-icd-loader \
            lib32-vulkan-icd-loader
    else
        echo "[?] No dedicated GPU vendor detected or using VM."
        echo "-> Installing generic Mesa drivers just in case..."
        sudo pacman -S --noconfirm --needed mesa lib32-mesa
    fi
}

# Función para Debian/Ubuntu
install_gpu_debian() {
    # Ubuntu tiene un gestor de drivers propio 'ubuntu-drivers', usamos eso para NVIDIA
    if lspci | grep -i "NVIDIA" &> /dev/null; then
        echo "[!] NVIDIA GPU detected."
        echo "-> Auto-installing recommended drivers via ubuntu-drivers..."
        sudo ubuntu-drivers autoinstall
        
    elif lspci | grep -i "AMD" &> /dev/null; then
        echo "[!] AMD GPU detected."
        echo "-> Installing Mesa/Vulkan..."
        sudo apt-get install -y mesa-vulkan-drivers libglx-mesa0
    else
        echo "[?] Using generic/intel drivers."
        sudo apt-get install -y mesa-vulkan-drivers
    fi
}

# Ejecución
if [ "$DISTRO" == "arch" ]; then
    install_gpu_arch
elif [ "$DISTRO" == "debian" ]; then
    install_gpu_debian
fi

echo "--- Module GPU Finished ---"