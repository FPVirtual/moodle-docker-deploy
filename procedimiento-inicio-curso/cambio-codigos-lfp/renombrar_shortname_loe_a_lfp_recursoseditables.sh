#!/usr/bin/env bash
# Renombra las carpetas de recursos editables sustituyendo códigos LOE por LFP.
# Lee un CSV con pares LFP,LOE y, por cada fila, busca en los directorios
# indicados todas las carpetas (de primer nivel) cuyo nombre contenga el
# código LOE y las renombra reemplazando esa subcadena por el código LFP
# correspondiente.
set -euo pipefail

# Directorio donde reside el propio script, usado para resolver rutas relativas
# (CSV y fichero de log) independientemente de desde dónde se invoque.
SCRIPT_DIR="$(dirname "$0")"
SCRIPT_NAME="$(basename "$0" .sh)"

# El fichero de log lleva la fecha del día en el nombre para facilitar la
# trazabilidad cuando el script se ejecuta periódicamente.
LOG_FILE="${SCRIPT_DIR}/${SCRIPT_NAME}_$(date '+%Y-%m-%d').log"

# Valores por defecto de los parámetros configurables.
CSV="${SCRIPT_DIR}/Relación IDs sigad cursos LFP y LOE - Hoja 1.csv"
DIRS_DEFAULT="/var/moodle-docker-deploy/zz_ftp_ministerio_htmls,/var/moodle-docker-deploy/zz_ftp_ministerio_htmls/editions"
DIRS_CSV="$DIRS_DEFAULT"
DRY_RUN=false

# Escribe una línea de log con timestamp y nivel (INFO, WARN, ERROR…)
# tanto en stdout como en el fichero de log (modo append).
log() {
    local level="$1"
    shift
    local msg="$*"
    local ts
    ts=$(date '+%Y-%m-%d %H:%M:%S')
    printf '%s [%-5s] %s\n' "$ts" "$level" "$msg" | tee -a "$LOG_FILE"
}

# Muestra la ayuda en stdout (sin pasar por el log) y termina.
usage() {
    cat <<EOF
Uso: $(basename "$0") [OPCIONES]

Recorre un fichero CSV y renombra las carpetas de recursos editables
sustituyendo el código LOE por el código LFP correspondiente, en cada uno
de los directorios indicados (solo carpetas de primer nivel).

Los mensajes se escriben tanto por pantalla como en el fichero de log:
  ${LOG_FILE}

OPCIONES:
  --dirs RUTA1,RUTA2,...  Lista de directorios (separados por comas) donde
                          buscar las carpetas a renombrar.
                          Por defecto: ${DIRS_DEFAULT}

  --csv RUTA              Ruta al fichero CSV de entrada (con cabecera LFP,LOE).
                          Por defecto: <directorio_del_script>/Relación IDs sigad cursos LFP y LOE - Hoja 1.csv

  --dry-run               Muestra los cambios que se realizarían sin
                          aplicarlos realmente (no renombra nada).

  --help                  Muestra esta ayuda y termina.

EJEMPLOS:

  # Ejecución síncrona con los valores por defecto:
  ./$(basename "$0")

  # Simulación sin aplicar cambios:
  ./$(basename "$0") --dry-run

  # Ejecución síncrona especificando parámetros:
  ./$(basename "$0") --csv ./otro_fichero.csv --dirs /ruta/uno,/ruta/dos

  # Ejecución en segundo plano con nohup (stdout/stderr van al log del script):
  nohup ./$(basename "$0") --csv ./otro_fichero.csv > /dev/null 2>&1 &
  echo "PID: \$!"
EOF
}

# Parseo de argumentos con nombre. Cualquier parámetro no reconocido aborta
# con error para evitar ejecuciones silenciosas con opciones incorrectas.
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dirs)
            DIRS_CSV="$2"
            shift 2
            ;;
        --csv)
            CSV="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            log ERROR "Parámetro desconocido: $1"
            exit 1
            ;;
    esac
done

# Convierte la lista de directorios separados por comas en un array.
IFS=',' read -r -a DIRS <<< "$DIRS_CSV"

# Marca de tiempo de inicio en segundos (epoch) para calcular la duración total.
START_TS=$(date +%s)
log INFO "Inicio"

if $DRY_RUN; then
    log INFO "Modo DRY-RUN activado: no se aplicará ningún cambio real."
fi

# Comprobación temprana del CSV: si no existe no tiene sentido continuar.
if [[ ! -f "$CSV" ]]; then
    log ERROR "Fichero CSV no encontrado: $CSV"
    exit 1
fi

log INFO "Directorios: ${DIRS[*]}"
log INFO "CSV        : $CSV"
log INFO "Log        : $LOG_FILE"

# Comprobación temprana de los directorios: se avisa de los que no existan,
# pero no se aborta para permitir procesar el resto.
for dir in "${DIRS[@]}"; do
    if [[ ! -d "$dir" ]]; then
        log WARN "Directorio no encontrado, se omitirá: $dir"
    fi
done

# Lectura del CSV fila a fila. IFS=, separa las columnas por coma.
# La primera fila (cabecera) se salta con el flag first_row.
# Si el CSV tiene más de dos columnas, el resto se captura en "_resto"
# y se ignora; solo se usan las dos primeras (LFP y LOE).
first_row=true
while IFS=, read -r LFP LOE _resto; do
    if $first_row; then
        first_row=false
        continue
    fi

    # Eliminar espacios y retornos de carro (CSV con finales de línea CRLF
    # de Windows), que de lo contrario quedan pegados al final de LOE.
    LFP="${LFP//[$'\r ']/}"
    LOE="${LOE//[$'\r ']/}"

    # Ignorar filas vacías o incompletas.
    if [[ -z "$LFP" || -z "$LOE" ]]; then
        continue
    fi

    log INFO "Procesando fila: LOE='${LOE}' → LFP='${LFP}'"

    # Por cada directorio configurado se buscan las carpetas de primer nivel
    # cuyo nombre contiene el código LOE.
    for dir in "${DIRS[@]}"; do
        if [[ ! -d "$dir" ]]; then
            continue
        fi

        mapfile -t matches < <(find "$dir" -mindepth 1 -maxdepth 1 -type d -name "*${LOE}*" || true)

        if [[ ${#matches[@]} -eq 0 ]]; then
            log WARN "No se encontró ninguna carpeta en '${dir}' cuyo nombre contenga '${LOE}'"
            continue
        fi

        # Por cada carpeta encontrada se construye el nuevo nombre y se renombra.
        for old_path in "${matches[@]}"; do
            old_name="$(basename "$old_path")"

            # Reemplaza todas las ocurrencias de LOE por LFP dentro del nombre,
            # preservando el resto de la cadena intacta.
            new_name="${old_name//$LOE/$LFP}"
            new_path="${dir}/${new_name}"

            if [[ "$old_name" == "$new_name" ]]; then
                continue
            fi

            if [[ -e "$new_path" ]]; then
                log WARN "Destino ya existe, se omite: '${old_path}' → '${new_path}'"
                continue
            fi

            if $DRY_RUN; then
                log INFO "[DRY-RUN] '${old_path}' → '${new_path}'"
            else
                mv "$old_path" "$new_path"
                log INFO "Carpeta renombrada: '${old_path}' → '${new_path}'"
            fi
        done
    done

done < "$CSV"

# Calcula e imprime la duración total del script en formato HH:MM:SS.
END_TS=$(date +%s)
ELAPSED=$(( END_TS - START_TS ))
ELAPSED_FMT=$(printf '%02d:%02d:%02d' $(( ELAPSED / 3600 )) $(( (ELAPSED % 3600) / 60 )) $(( ELAPSED % 60 )))

log INFO "Fin. Duración: ${ELAPSED_FMT} (${ELAPSED}s)"
