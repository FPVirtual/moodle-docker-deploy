#!/bin/bash
# WHEN:
# - new-install
# - update
# - upgrade (moodle-code se regenera desde cero y hay que volver a parchear)
#
# Aplica sobre el código de Moodle los parches de /init-scripts/patches/<grupo>/.
# De momento solo hay parches para FPD (grupo "fpd").
#
# Es idempotente: si un parche ya está aplicado se omite, y si no se puede
# aplicar limpiamente (p. ej. ha cambiado el código de Moodle) se avisa y se
# continúa sin modificar nada.

MOODLE_DIR="${MOODLE_DIR:-/var/www/html}"
PATCHES_DIR="${PATCHES_DIR:-/init-scripts/patches}"

apply_patches_dir(){
    local dir="$1"
    local p

    for p in "$dir"/*.patch; do
        [ -e "$p" ] || continue

        # Si algún fichero del parche no existe (p. ej. el plugin no está instalado), se omite
        local target missing=""
        while read -r target; do
            [ -f "${MOODLE_DIR}/${target}" ] || missing="$target"
        done < <(sed -n 's#^+++ b/\([^[:space:]]*\).*#\1#p' "$p")
        if [ -n "$missing" ]; then
            echo >&2 "Patch $(basename "$p") skipped, ${missing} not present."
            continue
        fi

        if patch -d "$MOODLE_DIR" -p1 -R --dry-run -s -f < "$p" >/dev/null 2>&1; then
            echo >&2 "Patch $(basename "$p") already applied, skipping."
        elif patch -d "$MOODLE_DIR" -p1 -N --dry-run -s -f < "$p" >/dev/null 2>&1; then
            patch -d "$MOODLE_DIR" -p1 -N -s -f --no-backup-if-mismatch < "$p"
            echo >&2 "Patch $(basename "$p") applied."
        else
            echo >&2 "WARNING: patch $(basename "$p") does not apply cleanly to ${MOODLE_DIR}; review it manually."
        fi
    done
}

if [[ "${SCHOOL_TYPE}" = "FPD" ]]; then
    echo >&2 "Applying FPD patches..."
    apply_patches_dir "${PATCHES_DIR}/fpd"
fi
