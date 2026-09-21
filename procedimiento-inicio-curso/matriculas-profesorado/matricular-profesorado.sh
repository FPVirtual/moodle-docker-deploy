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
# Si no se indica --csv, el propio script obtiene los últimos datos
# directamente de la tabla "docente_modulo_ciclo" de la BD de fp-app (a
# través del contenedor --db-container, por defecto "fp-app", que tiene las
# credenciales de la BD en sus variables de entorno) y los guarda en un CSV
# nuevo llamado docente_modulo_ciclo_AAAA_MM_DD_HH_MM_SS.csv, que es el que se
# usa para la matrícula.
#
# Este script:
#   1. Obtiene (salvo que se indique --csv) los últimos datos de
#      docente_modulo_ciclo desde el contenedor de fp-app y los guarda en un
#      CSV nuevo con marca de tiempo.
#   2. Construye el comando moosh de cada fila a partir de las columnas 1-7.
#   3. Lo ejecuta con moosh dentro del contenedor Docker de Moodle.
#   4. Guarda TODA la salida (stdout + stderr) de cada comando en un fichero
#      de log con marca de tiempo.
#   5. Al terminar genera un RESUMEN con las matrículas que se han realizado
#      correctamente y las que han fallado (con el motivo del fallo), tanto por
#      pantalla como en un fichero de resumen aparte.
#
# NO modifica el CSV original (si se indica --csv) ni la tabla docente_modulo_ciclo.
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
DB_CONTAINER="fp-app"   # contenedor de fp-app desde el que se lee docente_modulo_ciclo
CSV=""                  # vacío => se genera automáticamente desde docente_modulo_ciclo
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

  --csv RUTA            Ruta a un CSV de matrículas ya existente (columnas
                        id,dni,id_ciclo,id_modulo,id_centro,created_at,updated_at).
                        Si se omite (comportamiento por defecto), se obtienen
                        los últimos datos de docente_modulo_ciclo desde
                        --db-container y se genera un CSV nuevo llamado
                        docente_modulo_ciclo_AAAA_MM_DD_HH_MM_SS.csv.

  --db-container NOMBRE Contenedor Docker de fp-app desde el que se leen los
                        últimos datos de docente_modulo_ciclo cuando no se
                        indica --csv.
                        Por defecto: ${DB_CONTAINER}

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
        --db-container) DB_CONTAINER="$2"; shift 2 ;;
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
# obtener_matriculas_editingteacher_moodle(): consulta directamente en la
# BD de Moodle (a través de "moosh php-eval", usando la propia API $DB de
# Moodle) qué usuarios tienen YA el rol editingteacher en qué cursos,
# independientemente de cómo se hayan matriculado. Devuelve por stdout
# líneas "usuario<TAB>curso".
# ---------------------------------------------------------------------------
obtener_matriculas_editingteacher_moodle() {
    local php_code
    php_code="$(cat <<'PHP'
global $DB;
$sql = "SELECT u.username AS username, c.shortname AS shortname
        FROM {role_assignments} ra
        JOIN {context} cx ON cx.id = ra.contextid AND cx.contextlevel = 50
        JOIN {course} c ON c.id = cx.instanceid
        JOIN {user} u ON u.id = ra.userid
        JOIN {role} r ON r.id = ra.roleid AND r.shortname = 'editingteacher'
        WHERE u.deleted = 0";
$rs = $DB->get_recordset_sql($sql);
foreach ($rs as $r) {
    echo $r->username . "\t" . $r->shortname . "\n";
}
$rs->close();
PHP
)"
    run_moosh -n php-eval "$php_code"
}

# ---------------------------------------------------------------------------
# obtener_docente_modulo_ciclo(): consulta la tabla docente_modulo_ciclo de
# la BD de fp-app (a través de "docker exec" en DB_CONTAINER, usando las
# credenciales que ya tiene ese contenedor en sus variables de entorno
# DB_HOST/DB_PORT/DB_DATABASE/DB_USERNAME/DB_PASSWORD) y vuelca el resultado
# como CSV en la ruta indicada.
# ---------------------------------------------------------------------------
obtener_docente_modulo_ciclo() {
    local destino="$1"

    docker exec -i "$DB_CONTAINER" php > "$destino" <<'PHP'
<?php
$pdo = new PDO(
    "mysql:host=" . getenv("DB_HOST") . ";port=" . getenv("DB_PORT") . ";dbname=" . getenv("DB_DATABASE") . ";charset=utf8mb4",
    getenv("DB_USERNAME"),
    getenv("DB_PASSWORD")
);
$stmt = $pdo->query(
    "SELECT id, dni, id_ciclo, id_modulo, id_centro, created_at, updated_at FROM docente_modulo_ciclo ORDER BY id"
);
$out = fopen("php://stdout", "w");
fputcsv($out, ["id", "dni", "id_ciclo", "id_modulo", "id_centro", "created_at", "updated_at"]);
while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
    fputcsv($out, $row);
}
fclose($out);
PHP
}

# ---------------------------------------------------------------------------
# Obtención del CSV de partida.
#
# Si no se ha indicado --csv, se obtienen los últimos datos de
# docente_modulo_ciclo desde el contenedor de fp-app y se guardan en un CSV
# nuevo con marca de tiempo, que pasa a ser el CSV de esta ejecución.
# ---------------------------------------------------------------------------
if [[ -z "$CSV" ]]; then
    DB_STAMP="$(date '+%Y_%m_%d_%H_%M_%S')"
    CSV="${SCRIPT_DIR}/docente_modulo_ciclo_${DB_STAMP}.csv"

    log INFO "Obteniendo los últimos datos de docente_modulo_ciclo desde el contenedor '${DB_CONTAINER}'..."

    if ! obtener_docente_modulo_ciclo "$CSV"; then
        log ERROR "No se han podido obtener los datos de docente_modulo_ciclo desde el contenedor '${DB_CONTAINER}'."
        rm -f "$CSV"
        exit 1
    fi

    log INFO "CSV generado: $CSV ($(( $(wc -l < "$CSV") - 1 )) filas)"
fi

# ---------------------------------------------------------------------------
# Comprobaciones previas.
# ---------------------------------------------------------------------------
if [[ ! -f "$CSV" ]]; then
    log ERROR "No se encuentra el fichero CSV: $CSV"
    exit 1
fi

# ---------------------------------------------------------------------------
# Fichero de estado: qué combinaciones usuario+curso ya se han matriculado
# en ejecuciones anteriores (real, no dry-run) DE ESTE SCRIPT, para no
# repetirlas. Es un complemento a la consulta en vivo a Moodle de más abajo
# (que es la fuente de verdad real), útil sobre todo si en algún momento no
# se puede consultar Moodle directamente.
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

# ---------------------------------------------------------------------------
# Además del fichero de estado (que solo conoce lo que ha hecho ESTE script),
# se consulta directamente Moodle para saber qué matrículas de profesorado
# (rol editingteacher) existen YA en la plataforma, se hayan hecho como sea
# (matrícula manual, otro script, importación, etc.). Así no se repite el
# comando moosh sobre algo que ya está matriculado.
# ---------------------------------------------------------------------------
log INFO "Consultando en Moodle las matrículas de profesorado (editingteacher) ya existentes..."
MOODLE_ENROLADOS=0
if moodle_actual="$(obtener_matriculas_editingteacher_moodle)"; then
    while IFS=$'\t' read -r su sc; do
        [[ -z "$su" || -z "$sc" ]] && continue
        ENROLLED["${su}|${sc}"]=1
        MOODLE_ENROLADOS=$((MOODLE_ENROLADOS + 1))
    done <<< "$moodle_actual"
    log INFO "Matrículas editingteacher ya existentes en Moodle: ${MOODLE_ENROLADOS}"
else
    log WARN "No se ha podido consultar Moodle para ver las matrículas ya existentes; se usará solo el fichero de estado ($STATE_FILE)."
fi

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
