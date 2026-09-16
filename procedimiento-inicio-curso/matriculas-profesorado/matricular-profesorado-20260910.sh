#!/usr/bin/env bash
# =============================================================================
# matricular-profesorado-20260910.sh
#
# Ejecuta las matrículas de profesorado a partir del CSV de matrículas
# (matricular_profes_moodle - ...csv).
#
# Cada fila del CSV tiene esta forma (10 columnas):
#   id,dni,id_ciclo,id_modulo,id_centro,created_at,updated_at,
#   username,shortname_course,comando moosh
#
# El comando moosh se GENERA aquí usando SOLO las columnas 1 a 7. Concretamente:
#   - usuario  = "prof" + dni            (columna 2)
#   - curso    = id_centro-id_ciclo-id_modulo   (columnas 5-3-4)
#
# de modo que para cada fila se ejecuta:
#   moosh -n course-enrolbyname -r editingteacher -c <id_centro>-<id_ciclo>-<id_modulo> prof<dni>
#
# (Esto reproduce exactamente lo que había en la columna "comando moosh", pero
#  sin depender de las columnas 8, 9 ni 10.)
#
# Este script:
#   1. Construye el comando moosh de cada fila a partir de las columnas 1-7.
#   2. Lo ejecuta con moosh dentro del contenedor Docker de Moodle.
#   3. Guarda TODA la salida (stdout + stderr) de cada comando en un fichero
#      de log con marca de tiempo.
#   4. Al terminar genera un RESUMEN con las matrículas que se han realizado
#      correctamente y las que han fallado (con el motivo del fallo), tanto por
#      pantalla como en un fichero de resumen aparte.
#
# NO modifica el CSV original.
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "$0" .sh)"
STAMP="$(date '+%Y-%m-%d_%H%M%S')"

LOG_FILE="${SCRIPT_DIR}/${SCRIPT_NAME}_${STAMP}.log"
RESUMEN_FILE="${SCRIPT_DIR}/${SCRIPT_NAME}_${STAMP}_resumen.txt"

# ---------------------------------------------------------------------------
# Valores por defecto (mismo estilo que el resto de scripts del repo).
# ---------------------------------------------------------------------------
CONTAINER="wwwfpvirtualaragones-moodle-1"
CSV="${SCRIPT_DIR}/matricular_profes_moodle - matriculas 26 27.csv"
DRY_RUN=false
USE_DOCKER=true      # false => ejecuta 'moosh' directamente (script ya dentro del contenedor)
LIMIT=0              # 0 = sin límite; N = procesa solo las N primeras filas (para pruebas)

# Fichero de estado con las matrículas ya realizadas (una por línea: "usuario<TAB>curso").
# Se usa para NO volver a matricular a quien ya se matriculó en ejecuciones anteriores.
STATE_FILE="${SCRIPT_DIR}/matriculas-realizadas.tsv"
FORCE=false           # true => ignora el estado y matricula aunque ya conste como hecho

# ---------------------------------------------------------------------------
# log(): escribe con marca de tiempo por pantalla y en el fichero de log.
# ---------------------------------------------------------------------------
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

Ejecuta las matrículas de profesorado de la columna "comando moosh" del CSV,
guarda la salida en un log y genera un resumen de aciertos y fallos.

OPCIONES:
  --container NOMBRE   Nombre del contenedor Docker de Moodle.
                        Por defecto: ${CONTAINER}

  --csv RUTA            Ruta al CSV de matrículas.
                        Por defecto: ${CSV}

  --no-docker           Ejecuta 'moosh' directamente (sin docker exec),
                        útil si ya estás dentro del contenedor.

  --limit N             Procesa solo las N primeras matrículas (0 = todas).
                        Útil para hacer una prueba antes de lanzarlo entero.

  --state RUTA           Fichero de estado con las matrículas ya realizadas.
                        Por defecto: ${STATE_FILE}

  --force                Matricula aunque el usuario+curso ya conste como
                        realizado en el fichero de estado.

  --dry-run             No ejecuta nada; solo muestra el comando que lanzaría.

  --help                Muestra esta ayuda y termina.

EJEMPLOS:
  ./$(basename "$0")
  ./$(basename "$0") --dry-run
  ./$(basename "$0") --limit 5
  ./$(basename "$0") --container otro-contenedor
EOF
}

# ---------------------------------------------------------------------------
# Parseo de argumentos.
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --container) CONTAINER="$2"; shift 2 ;;
        --csv)       CSV="$2"; shift 2 ;;
        --no-docker) USE_DOCKER=false; shift ;;
        --limit)     LIMIT="$2"; shift 2 ;;
        --state)     STATE_FILE="$2"; shift 2 ;;
        --force)     FORCE=true; shift ;;
        --dry-run)   DRY_RUN=true; shift ;;
        --help)      usage; exit 0 ;;
        *) echo "Parámetro desconocido: $1" >&2; usage; exit 1 ;;
    esac
done

# ---------------------------------------------------------------------------
# run_moosh(): ejecuta moosh con los argumentos dados (vía docker o directo)
# y devuelve por stdout la salida combinada (stdout+stderr). El código de
# salida de moosh se propaga como código de salida de la función.
# ---------------------------------------------------------------------------
run_moosh() {
    if $USE_DOCKER; then
        docker exec --user www-data "$CONTAINER" moosh "$@" 2>&1
    else
        moosh "$@" 2>&1
    fi
}

# ---------------------------------------------------------------------------
# Comprobaciones previas.
# ---------------------------------------------------------------------------
if [[ ! -f "$CSV" ]]; then
    log ERROR "No se encuentra el fichero CSV: $CSV"
    exit 1
fi

# ---------------------------------------------------------------------------
# Fichero de estado: qué combinaciones usuario+curso ya se han matriculado
# en ejecuciones anteriores (real, no dry-run), para no repetirlas.
#
# Si el fichero de estado todavía no existe, se genera sembrándolo a partir
# de los resúmenes ("*_resumen.txt") de ejecuciones reales anteriores de
# este mismo script, para no volver a matricular lo que ya se hizo antes de
# que existiera este mecanismo.
# ---------------------------------------------------------------------------
if [[ ! -f "$STATE_FILE" ]]; then
    : > "$STATE_FILE"
    for f in "${SCRIPT_DIR}/${SCRIPT_NAME}"_*_resumen.txt; do
        [[ -e "$f" ]] || continue
        awk -F' -> ' '/^[[:space:]]*\[OK\]/ && $0 !~ /\(dry-run\)/ {
            u=$1; sub(/^[[:space:]]*\[OK\][[:space:]]*/, "", u);
            c=$2; sub(/[[:space:]]*$/, "", c);
            print u "\t" c
        }' "$f" >> "$STATE_FILE"
    done
    sort -u -o "$STATE_FILE" "$STATE_FILE"
    log INFO "Fichero de estado creado a partir de resúmenes anteriores: $STATE_FILE ($(wc -l < "$STATE_FILE") matrículas previas)"
fi

declare -A ENROLLED
while IFS=$'\t' read -r su sc; do
    [[ -z "$su" ]] && continue
    ENROLLED["${su}|${sc}"]=1
done < "$STATE_FILE"

START_TS=$(date +%s)
log INFO "================================================================"
log INFO "Inicio matrícula de profesorado"
log INFO "CSV        : $CSV"
log INFO "Contenedor : $CONTAINER (usar docker: $USE_DOCKER)"
log INFO "Dry-run    : $DRY_RUN"
log INFO "Estado     : $STATE_FILE (${#ENROLLED[@]} matrículas ya registradas, force=$FORCE)"
[[ "$LIMIT" -gt 0 ]] && log INFO "Límite     : $LIMIT primeras filas"
log INFO "Log        : $LOG_FILE"
log INFO "Resumen    : $RESUMEN_FILE"
log INFO "================================================================"

# ---------------------------------------------------------------------------
# Contadores y acumuladores para el resumen.
# ---------------------------------------------------------------------------
TOTAL=0
OK=0
FALLOS=0
OMITIDAS=0
OK_LINES=()
FALLO_LINES=()

# ---------------------------------------------------------------------------
# Recorrido del CSV.
#   - Se salta la cabecera (primera línea).
#   - Solo se usan las columnas 1 a 7 para construir el comando moosh:
#       col2=dni  col3=id_ciclo  col4=id_modulo  col5=id_centro
# ---------------------------------------------------------------------------
FIRST=true
while IFS=',' read -r c_id c_dni c_ciclo c_modulo c_centro c_created c_updated _resto; do

    # Saltar cabecera.
    if $FIRST; then
        FIRST=false
        continue
    fi

    # Limpiar posibles retornos de carro de Windows (\r), espacios sobrantes
    # y comillas dobles (el CSV trae varios campos entrecomillados).
    c_id="${c_id//[$'\r\"']/}"
    c_dni="${c_dni//[$'\r \"']/}"
    c_ciclo="${c_ciclo//[$'\r \"']/}"
    c_modulo="${c_modulo//[$'\r \"']/}"
    c_centro="${c_centro//[$'\r \"']/}"

    # Saltar filas vacías / incompletas (faltan datos para construir el comando).
    if [[ -z "$c_dni" || -z "$c_ciclo" || -z "$c_modulo" || -z "$c_centro" ]]; then
        continue
    fi

    # -----------------------------------------------------------------------
    # Construir el comando moosh SOLO con las columnas 1-7:
    #   usuario = "prof" + dni
    #   curso   = id_centro-id_ciclo-id_modulo
    # -----------------------------------------------------------------------
    username="prof${c_dni}"
    shortname_course="${c_centro}-${c_ciclo}-${c_modulo}"
    key="${username}|${shortname_course}"

    # Saltar si ya consta como matriculado en el fichero de estado (salvo --force).
    if ! $FORCE && [[ -n "${ENROLLED[$key]+x}" ]]; then
        OMITIDAS=$((OMITIDAS + 1))
        continue
    fi

    # Respetar el límite si se ha indicado.
    if [[ "$LIMIT" -gt 0 && "$TOTAL" -ge "$LIMIT" ]]; then
        break
    fi

    TOTAL=$((TOTAL + 1))

    moosh_args=(-n course-enrolbyname -r editingteacher -c "$shortname_course" "$username")

    etiqueta="${username} -> ${shortname_course}"
    log INFO "[$TOTAL] Matriculando: ${etiqueta}"

    # -----------------------------------------------------------------------
    # Dry-run: solo mostrar lo que se ejecutaría.
    # -----------------------------------------------------------------------
    if $DRY_RUN; then
        if $USE_DOCKER; then
            log INFO "  [dry-run] docker exec --user www-data $CONTAINER moosh ${moosh_args[*]}"
        else
            log INFO "  [dry-run] moosh ${moosh_args[*]}"
        fi
        OK=$((OK + 1))
        OK_LINES+=("${etiqueta}  (dry-run)")
        continue
    fi

    # -----------------------------------------------------------------------
    # Ejecución real. Capturamos salida y código de retorno.
    # -----------------------------------------------------------------------
    salida="$(run_moosh "${moosh_args[@]}")"
    rc=$?

    # Volcar la salida del comando al log (indentada, para que se lea bien).
    if [[ -n "$salida" ]]; then
        while IFS= read -r linea; do
            printf '        | %s\n' "$linea" | tee -a "$LOG_FILE" >/dev/null
        done <<< "$salida"
    fi

    # Primera línea de salida "de interés" (ignorando warnings de PHP), para
    # mostrarla como motivo en el resumen. Si solo hay warnings, se usa la
    # primera línea no vacía tal cual.
    motivo="$(printf '%s\n' "$salida" | grep -v '^[[:space:]]*$' | grep -viE '^(PHP )?Warning:' | head -1)"
    [[ -z "$motivo" ]] && motivo="$(printf '%s\n' "$salida" | grep -v '^[[:space:]]*$' | head -1)"
    [[ -z "$motivo" ]] && motivo="(sin mensaje)"

    # -----------------------------------------------------------------------
    # Clasificación: OK si rc==0 y la salida no contiene indicios de error.
    #
    # "no manual enrolment instance" ocurre cuando el curso no tiene NINGÚN
    # método de matriculación configurado en Moodle: moosh no matricula a
    # nadie pero solo emite un warning de PHP y termina con rc=0, así que
    # hay que detectarlo explícitamente o quedaría marcado como OK sin serlo.
    # -----------------------------------------------------------------------
    if [[ $rc -eq 0 ]] && ! printf '%s' "$salida" | grep -qiE 'error|exception|not found|no such|could not|fail|no existe|no se (ha|han)|no manual enrolment'; then
        OK=$((OK + 1))
        OK_LINES+=("${etiqueta}")
        log INFO "  OK (rc=$rc)"
        # Registrar en el fichero de estado para no repetir esta matrícula en el futuro.
        ENROLLED["${key}"]=1
        printf '%s\t%s\n' "$username" "$shortname_course" >> "$STATE_FILE"
    else
        FALLOS=$((FALLOS + 1))
        FALLO_LINES+=("${etiqueta}  ->  ${motivo}")
        log ERROR "  FALLO (rc=$rc): ${motivo}"
    fi

done < "$CSV"

# ---------------------------------------------------------------------------
# Resumen final (por pantalla + log + fichero de resumen).
# ---------------------------------------------------------------------------
END_TS=$(date +%s)
ELAPSED=$(( END_TS - START_TS ))
ELAPSED_FMT=$(printf '%02d:%02d:%02d' $(( ELAPSED / 3600 )) $(( (ELAPSED % 3600) / 60 )) $(( ELAPSED % 60 )))

{
    echo "================================================================"
    echo " RESUMEN DE MATRÍCULAS DE PROFESORADO"
    echo " Fecha    : $(date '+%Y-%m-%d %H:%M:%S')"
    echo " CSV      : $CSV"
    echo " Duración : ${ELAPSED_FMT} (${ELAPSED}s)"
    echo "----------------------------------------------------------------"
    printf " Total procesadas : %d\n" "$TOTAL"
    printf " Correctas (OK)   : %d\n" "$OK"
    printf " Fallidas         : %d\n" "$FALLOS"
    [[ "$OMITIDAS" -gt 0 ]] && printf " Omitidas         : %d\n" "$OMITIDAS"
    echo "================================================================"
    echo ""
    echo "----- MATRÍCULAS REALIZADAS CORRECTAMENTE (${OK}) -----"
    if [[ ${#OK_LINES[@]} -eq 0 ]]; then
        echo "  (ninguna)"
    else
        for l in "${OK_LINES[@]}"; do echo "  [OK]    $l"; done
    fi
    echo ""
    echo "----- MATRÍCULAS FALLIDAS (${FALLOS}) -----"
    if [[ ${#FALLO_LINES[@]} -eq 0 ]]; then
        echo "  (ninguna)"
    else
        for l in "${FALLO_LINES[@]}"; do echo "  [FALLO] $l"; done
    fi
} | tee "$RESUMEN_FILE" | tee -a "$LOG_FILE"

log INFO "Fin. Total=${TOTAL} OK=${OK} Fallos=${FALLOS} Omitidas=${OMITIDAS}. Duración: ${ELAPSED_FMT}."
log INFO "Log detallado : $LOG_FILE"
log INFO "Resumen       : $RESUMEN_FILE"

# Código de salida: 0 si no hubo fallos, 1 si hubo alguno.
[[ "$FALLOS" -eq 0 ]] && exit 0 || exit 1
