#!/usr/bin/env bash
# Crea los cursos nuevos de MI (Mecatrónica Industrial) con su shortname nuevo
# y les importa el contenido del curso antiguo restaurando el .mbz
# correspondiente (que está nombrado con el shortname VIEJO).
#
# Por cada fila del CSV (fullname,shortname_viejo,shortname_nuevo):
#   1. Crea un curso vacío en la categoría indicada con el shortname NUEVO.
#   2. Busca su id recién creado.
#   3. Restaura dentro de ese curso el backup <shortname_viejo>.mbz
#      (moosh course-restore -e ..., que fusiona el contenido sin tocar
#      el shortname del curso destino).
set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"
SCRIPT_NAME="$(basename "$0" .sh)"
LOG_FILE="${SCRIPT_DIR}/${SCRIPT_NAME}_$(date '+%Y-%m-%d').log"

# Valores por defecto.
CONTAINER="wwwfpvirtualaragones-moodle-1"
CSV="${SCRIPT_DIR}/codigos-viejos-y-nuevos-cursos.csv"
CATEGORY_ID="58"
MBZ_DIR="/var/www/moodledata/repository/mbzs_curso_anterior"
DRY_RUN=false

log() {
    local level="$1"; shift
    local msg="$*"
    local ts
    ts=$(date '+%Y-%m-%d %H:%M:%S')
    printf '%s [%-5s] %s\n' "$ts" "$level" "$msg" | tee -a "$LOG_FILE"
}

usage() {
    cat <<EOF
Uso: $(basename "$0") [OPCIONES]

Crea los cursos nuevos (shortname nuevo) en la categoría indicada y les
restaura el contenido del curso antiguo a partir del .mbz correspondiente
(nombrado como <shortname_viejo>.mbz).

OPCIONES:
  --container NOMBRE   Nombre del contenedor Docker de Moodle.
                        Por defecto: ${CONTAINER}

  --csv RUTA            Ruta al CSV (fullname,shortname_viejo,shortname_nuevo).
                        Por defecto: ${CSV}

  --category ID         Id numérico de la categoría destino.
                        Por defecto: ${CATEGORY_ID}

  --mbz-dir RUTA         Ruta (dentro del contenedor) donde están los .mbz.
                        Por defecto: ${MBZ_DIR}

  --dry-run              No ejecuta nada, solo muestra lo que haría.

  --help                Muestra esta ayuda y termina.

EJEMPLOS:
  ./$(basename "$0")
  ./$(basename "$0") --dry-run
  ./$(basename "$0") --container otro-contenedor --category 58
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --container) CONTAINER="$2"; shift 2 ;;
        --csv) CSV="$2"; shift 2 ;;
        --category) CATEGORY_ID="$2"; shift 2 ;;
        --mbz-dir) MBZ_DIR="$2"; shift 2 ;;
        --dry-run) DRY_RUN=true; shift ;;
        --help) usage; exit 0 ;;
        *) log ERROR "Parámetro desconocido: $1"; exit 1 ;;
    esac
done

START_TS=$(date +%s)
log INFO "Inicio"

if [[ ! -f "$CSV" ]]; then
    log ERROR "Fichero CSV no encontrado: $CSV"
    exit 1
fi

log INFO "Contenedor  : $CONTAINER"
log INFO "CSV         : $CSV"
log INFO "Categoría   : $CATEGORY_ID"
log INFO "Directorio mbz: $MBZ_DIR"
log INFO "Dry-run     : $DRY_RUN"

run_moosh() {
    if $DRY_RUN; then
        log INFO "  [dry-run] docker exec --user www-data $CONTAINER moosh $*"
    else
        docker exec --user www-data "$CONTAINER" moosh "$@"
    fi
}

TOTAL=0
OK=0
FALLOS=0

# Lectura del CSV: fullname,shortname_viejo,shortname_nuevo (sin cabecera).
while IFS=, read -r FULLNAME OLD_SHORT NEW_SHORT _resto; do
    FULLNAME="${FULLNAME//$'\r'/}"
    OLD_SHORT="${OLD_SHORT//[$'\r ']/}"
    NEW_SHORT="${NEW_SHORT//[$'\r ']/}"

    if [[ -z "$FULLNAME" || -z "$OLD_SHORT" || -z "$NEW_SHORT" ]]; then
        continue
    fi

    TOTAL=$((TOTAL + 1))
    log INFO "----------------------------------------------------------------"
    log INFO "Procesando: '${FULLNAME}' (viejo='${OLD_SHORT}' -> nuevo='${NEW_SHORT}')"

    # 1. Comprobar que no exista ya un curso con ese shortname nuevo.
    existing=$(docker exec --user www-data "$CONTAINER" moosh sql-run \
        "SELECT id FROM mdl_course WHERE shortname = '${NEW_SHORT}'" 2>/dev/null || true)
    existing_id=$(echo "$existing" | grep -oP '\[id\] => \K\S+' || true)

    if [[ -n "$existing_id" ]]; then
        log WARN "Ya existe un curso con shortname '${NEW_SHORT}' (id=${existing_id}). Se omite la creación."
        course_id="$existing_id"
    else
        # 2. Crear el curso nuevo (vacío) con el shortname nuevo.
        if ! run_moosh course-create --category "$CATEGORY_ID" --fullname "$FULLNAME" "$NEW_SHORT"; then
            log ERROR "Fallo al crear el curso '${NEW_SHORT}'. Se omite."
            FALLOS=$((FALLOS + 1))
            continue
        fi

        if $DRY_RUN; then
            log INFO "  [dry-run] curso '${NEW_SHORT}' se crearía aquí; se omite la restauración en dry-run."
            OK=$((OK + 1))
            continue
        fi

        # 3. Recuperar el id del curso recién creado.
        created=$(docker exec --user www-data "$CONTAINER" moosh sql-run \
            "SELECT id FROM mdl_course WHERE shortname = '${NEW_SHORT}'" 2>/dev/null || true)
        course_id=$(echo "$created" | grep -oP '\[id\] => \K\S+' || true)

        if [[ -z "$course_id" ]]; then
            log ERROR "No se ha podido obtener el id del curso recién creado '${NEW_SHORT}'."
            FALLOS=$((FALLOS + 1))
            continue
        fi
    fi

    log INFO "Curso '${NEW_SHORT}' -> id=${course_id}"

    # 4. Restaurar el backup del curso antiguo dentro del curso nuevo.
    mbz_path="${MBZ_DIR}/${OLD_SHORT}.mbz"

    if ! $DRY_RUN; then
        if ! docker exec --user www-data "$CONTAINER" test -f "$mbz_path"; then
            log ERROR "No se encuentra el fichero mbz: ${mbz_path}. Se omite la restauración de este curso."
            FALLOS=$((FALLOS + 1))
            continue
        fi
    fi

    if run_moosh course-restore -e "$mbz_path" "$course_id"; then
        log INFO "Curso id=${course_id} ('${NEW_SHORT}') restaurado correctamente desde ${mbz_path}."
        OK=$((OK + 1))
    else
        log ERROR "Fallo al restaurar ${mbz_path} en el curso id=${course_id}."
        FALLOS=$((FALLOS + 1))
    fi

done < "$CSV"

END_TS=$(date +%s)
ELAPSED=$(( END_TS - START_TS ))
ELAPSED_FMT=$(printf '%02d:%02d:%02d' $(( ELAPSED / 3600 )) $(( (ELAPSED % 3600) / 60 )) $(( ELAPSED % 60 )))

log INFO "----------------------------------------------------------------"
log INFO "Fin. Total=${TOTAL} OK=${OK} Fallos=${FALLOS}. Duración: ${ELAPSED_FMT} (${ELAPSED}s)"
