#!/bin/bash
# Upgrade de plugins.
# Lee el catalogo desde /init-scripts/plugins.json y las variables PLUGIN_* del .env.
# Filtra por SCHOOL_TYPE e INSTALL_TYPE=upgrade.

# Cargar helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/plugins-lib.sh"

# Google Meet: elegir entre fork hyukudan (moderno) o legacy (ronefel).
# A diferencia de Moodle-Docker, aqui no se clona en build-time; se asume que
# el codigo correspondiente ya esta presente en moodle-code.
if [ "${PLUGIN_MOD_GOOGLEMEET_LEGACY:-false}" = "true" ]; then
    echo >&2 "Google Meet legacy (ronefel) seleccionado. Reemplazando mod/googlemeet..."
    if [ -d /var/www/html/mod/googlemeet_legacy ]; then
        rm -rf /var/www/html/mod/googlemeet
        cp -a /var/www/html/mod/googlemeet_legacy /var/www/html/mod/googlemeet
        PLUGIN_MOD_GOOGLEMEET=false
    else
        echo >&2 "WARNING: /var/www/html/mod/googlemeet_legacy no existe. No se puede activar legacy."
    fi
elif [ "${PLUGIN_MOD_GOOGLEMEET:-false}" = "true" ]; then
    # Hyukudan seleccionado: limpiar legacy para no ocupar espacio
    rm -rf /var/www/html/mod/googlemeet_legacy
fi

# GET PLUGIN LIST
echo >&2 "Downloading plugin list..."
moosh plugin-list >/dev/null
echo >&2 "Plugin list downloaded!"

# INSTALL PLUGINS (theme is installed in theme.sh)
echo >&2 "Installing plugins..."
echo "Moodle's version: ${VERSION}"
VERSION_MINOR=$(echo ${VERSION} | cut -d. -f1,2)
echo "Moodle's minor version: ${VERSION_MINOR}"

# Mostrar resumen antes de empezar
plugins_show_summary "${SCHOOL_TYPE}" "upgrade"

# Iterar sobre los plugins habilitados para upgrade
while IFS= read -r PLUGIN; do
    [ -z "$PLUGIN" ] && continue

    echo ""
    echo "===> Processing plugin: ${PLUGIN}"

    INSTALL_METHOD="$(plugins_json_get "${PLUGIN}" "install_method")"
    INSTALL_METHOD="${INSTALL_METHOD:-moosh}"

    if [ "${INSTALL_METHOD}" = "git_clone" ]; then
        echo "Installing ${PLUGIN} via git clone..."
        /init-scripts/lib/clone-plugin-runtime.sh ${PLUGIN}
        if [ "${PLUGIN}" = "local_educaaragon" ]; then
            php /init-scripts/new-install/educaaragon_setup.php
        fi
    else
        # En upgrade instalamos directamente (sin comprobacion remota previa)
        echo "trying to install ${PLUGIN} ..."
        moosh plugin-install -d ${PLUGIN} || echo "${PLUGIN} already present or install skipped"
    fi
done < <(plugins_list_enabled "${SCHOOL_TYPE}" "upgrade")

echo >&2 "Plugins installed!"
