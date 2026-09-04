#!/bin/bash
# =============================================================================
# clone-plugin-runtime.sh - Clona un plugin desde Git en runtime.
# =============================================================================
# Uso: clone-plugin-runtime.sh <plugin_name>
#
# Lee los metadatos del plugin desde /init-scripts/plugins.json y clona el
# repositorio en la ruta correspondiente dentro de /var/www/html.
# =============================================================================

set -e

PLUGIN_NAME="${1:-}"
PLUGINS_JSON="${PLUGINS_JSON:-/init-scripts/plugins.json}"
BASE_DIR="/var/www/html"

if [ -z "$PLUGIN_NAME" ]; then
    echo "ERROR: Debe indicar el nombre del plugin." >&2
    exit 1
fi

if [ ! -f "$PLUGINS_JSON" ]; then
    echo "ERROR: No se encontro $PLUGINS_JSON" >&2
    exit 1
fi

# Usamos python3 (siempre disponible en la imagen) en vez de jq, que no
# esta instalado y cuya instalacion via apt-get falla en silencio al
# ejecutarse init.sh como www-data (sin privilegios).
plugin_fields=$(python3 -c "
import json, sys
try:
    with open('$PLUGINS_JSON', 'r') as f:
        data = json.load(f)
    for p in data.get('plugins', []):
        if p['name'] == '$PLUGIN_NAME':
            print(p.get('git_url') or '')
            print(p.get('git_branch') or '')
            print(p.get('moodle_path') or '')
            sys.exit(0)
    sys.exit(1)
except Exception as e:
    print(f'Error JSON: {e}', file=sys.stderr)
    sys.exit(1)
") || { echo "ERROR: Plugin ${PLUGIN_NAME} no encontrado en $PLUGINS_JSON" >&2; exit 1; }

git_url=$(echo "$plugin_fields" | sed -n '1p')
git_branch=$(echo "$plugin_fields" | sed -n '2p')
moodle_path=$(echo "$plugin_fields" | sed -n '3p')

if [ -z "$git_url" ]; then
    echo "ERROR: Plugin ${PLUGIN_NAME} no tiene git_url definida." >&2
    exit 1
fi

target_dir="$BASE_DIR/$moodle_path"

# Si el plugin ya existe y no esta vacio, no reclonar
if [ -d "$target_dir" ] && [ "$(ls -A "$target_dir" 2>/dev/null)" ]; then
    echo "Plugin ${PLUGIN_NAME} ya presente en ${target_dir}. Omitiendo clone." >&2
    exit 0
fi

branch_arg=""
if [ -n "$git_branch" ] && [ "$git_branch" != "null" ]; then
    branch_arg="--branch $git_branch"
fi

echo "Clonando ${PLUGIN_NAME} desde ${git_url}..." >&2
mkdir -p "$(dirname "$target_dir")"
rm -rf "$target_dir"
git clone --depth 1 $branch_arg "$git_url" "$target_dir"
echo "Plugin ${PLUGIN_NAME} clonado en ${target_dir}." >&2
