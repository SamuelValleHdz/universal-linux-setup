#!/bin/bash
#
# MÓDULO: Actualizador de Alias de Flatpak
#
# Este script genera un archivo estático con alias para todas las
# aplicaciones de Flatpak instaladas.
# Está diseñado para ser llamado por install.sh o manualmente (alias 'update').

set -e

# El archivo que se generará
ALIAS_FILE="$HOME/.zshrc-flatpak-aliases"

echo "--- Generando alias de Flatpak en $ALIAS_FILE ---"

# Escribir el encabezado (>) sobrescribe el archivo cada vez
echo "# --- Alias de Flatpak (Generado por update-flatpak-aliases.sh) ---" > "$ALIAS_FILE"
echo "# Este archivo se vuelve a generar cada vez que se ejecuta ese script." >> "$ALIAS_FILE"
echo "" >> "$ALIAS_FILE"

# --- Lógica de 'awk' ---
# Arregla el error 'alias studio' de apps con nombres largos
# 1. Itera por todos los campos (columnas) de cada línea.
# 2. Busca el campo que contiene un punto ('.') - ese es el App ID.
# 3. Divide ese App ID por el punto y usa la última parte como el alias.
flatpak list --app | awk '{
    app_id = "";
    # Itera por todos los campos para encontrar el App ID
    for (i = 1; i <= NF; i++) {
        if ($i ~ /\./) {
            app_id = $i;
            break;
        }
    }
    
    if (app_id != "") {
        n = split(app_id, parts, ".");
        alias_name = tolower(parts[n]);
        # Imprime el alias al archivo
        printf "alias %s=\047flatpak run %s\047\n", alias_name, app_id
    }
}' >> "$ALIAS_FILE" # (>>) Añade al archivo

echo "✅ Alias de Flatpak generados."