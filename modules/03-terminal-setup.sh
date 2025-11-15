#!/bin/bash
# Activa el modo estricto
set -e

echo "--- Módulo 3: Configuración de la Terminal ---"

# --- Zsh, Oh My Zsh, Plugins, LunarVim ---
# (Todas estas secciones no cambian)
# ... (deja todo igual hasta la sección de $PATH) ...

# --- Configuración de $PATH ---
echo "⚙️  Configurando $PATH para pipx, lvim y alias en .zshrc..."

# --- pipx ---
if ! grep -q 'eval "$(pipx ensurepath)"' "$HOME/.zshrc"; then
    echo 'eval "$(pipx ensurepath)"' >> "$HOME/.zshrc"
    echo "✅ Añadido pipx ensurepath a .zshrc"
else
    echo "👌 pipx ensurepath ya está en .zshrc."
fi

# --- .local/bin (lvim), Flatpak (auto) y Alias (estáticos) ---
# Usamos un marcador para evitar añadir este bloque varias veces.
# (Actualizamos el marcador para que se vuelva a generar esta vez)
if ! grep -q "# --- Fin de la configuración de \$PATH y Alias ---" "$HOME/.zshrc"; then
    echo "-> Añadiendo bloque de \$PATH y carga de alias..."
    
    cat << 'EOF' >> ~/.zshrc

# --- Configuración de $PATH ---
# (Bloque añadido por el script global-linux-desktop)

# Añade la carpeta local de binarios (para lvim)
if [ -d "$HOME/.local/bin" ] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$PATH:$HOME/.local/bin"
fi

# Añade las carpetas de binarios de Flatpak (Intento automático)
if [ -d "/var/lib/flatpak/exports/bin" ] && [[ ":$PATH:" != *":/var/lib/flatpak/exports/bin:"* ]]; then
    export PATH="$PATH:/var/lib/flatpak/exports/bin"
fi
if [ -d "$HOME/.local/share/flatpak/exports/bin" ] && [[ ":$PATH:" != *":$HOME/.local/share/flatpak/exports/bin:"* ]]; then
    export PATH="$PATH:$HOME/.local/share/flatpak/exports/bin"
fi

# --- Cargar alias de Flatpak (GENERADOS) ---
# Carga el archivo de alias generado por 'update-flatpak-aliases.sh'
ALIAS_FILE_PATH="$HOME/.zshrc-flatpak-aliases"
if [ -f "$ALIAS_FILE_PATH" ]; then
    source "$ALIAS_FILE_PATH"
fi
# --- Fin de la configuración de $PATH y Alias ---
EOF
    echo "✅ $PATH y alias de Flatpak configurados en .zshrc"
else
    echo "👌 El bloque de \$PATH y Alias ya existe en .zshrc. Saltando."
fi


echo "--- Módulo 3 Finalizado ---"