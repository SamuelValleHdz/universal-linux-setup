#!/bin/bash
#
# MÓDULO: Actualizador de Alias de Flatpak
#
# Este script genera un archivo estático con alias para todas las
# aplicaciones de Flatpak instaladas.
# Está diseñado para ser llamado por install.sh o manualmente.

set -e

# El archivo que se generará
ALIAS_FILE="$HOME/.zshrc-flatpak-aliases"

echo "--- Generando alias de Flatpak en $ALIAS_FILE ---"

# Escribir el encabezado (sobrescribe el archivo cada vez)
echo "# --- Alias de Flatpak (Generado por update-flatpak-aliases.sh) ---" > "$ALIAS_FILE"
echo "# Este archivo se vuelve a generar cada vez que se ejecuta ese script." >> "$ALIAS_FILE"
echo "" >> "$ALIAS_FILE"

# Usar el AWK que sí funcionó (basado en 'flatpak list --app')
# para AÑADIR (>>) los alias al archivo que acabamos de crear.
flatpak list --app | awk '{
    app_id = $2;
    n = split(app_id, parts, ".");
    alias_name = tolower(parts[n]);
    printf "alias %s=\047flatpak run %s\047\n", alias_name, app_id
}' >> "$ALIAS_FILE"

echo "✅ Alias de Flatpak generados."