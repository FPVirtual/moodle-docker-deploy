#!/bin/bash
##########################################
# 2026_09_09_01.sh
#
# Corrección post-despliegue.
# Importa las categorías y cursos que fallaron al crearse en el despliegue
# inicial porque sus categorías todavía no existían, crea/configura el jefe
# de estudios de CFP CAMPUS DIGITAL (prof_je_cd), que no llegó a crearse, y
# crea los cursos generales (salas) que faltaban.
#
# Acciones:
#   1) Crea el usuario prof_je_cd (Jefatura de estudios - CFP CAMPUS DIGITAL).
#   2) Asigna a prof_je_cd su campo personalizado de categoría (fieldid=1 = 49)
#      y lo añade a la cohorte "jefaturas".
#   3) Crea la categoría "Recursos y Servicios en la Nube" (CESIFC04) en CFP CAMPUS DIGITAL (id=49).
#   4) Crea la categoría "Desarrollo de Aplicaciones en Lenguaje Python" (CESIFC05) en CFP CAMPUS DIGITAL (id=49).
#   5) Crea la categoría "Ciberseguridad en Entornos de las Tecnologías de la Información" (CESIFC01) en IES SIERRA DE GUARA (id=4).
#   6) Crea e importa (restaura) TODOS los cursos del CSV: los de esas tres categorías
#      y los cursos generales (coordinacion, profesorado, ayuda) en la categoría General (id=2),
#      matriculando en los cursos generales sus cohortes correspondientes.
#   7) Matricula a prof_je_sg (rol jefatura-estudios) en TODOS los cursos de IES SIERRA DE GUARA (subárbol id=4).
#   8) Matricula a prof_je_cd (rol jefatura-estudios) en TODOS los cursos de CFP CAMPUS DIGITAL (subárbol id=49).
#
# Cursos a crear/importar: /init-scripts/update/2026_09_09_01_courses_FPD.csv
#   formato por línea: category_varname,shortname,fullname,visible
#
# Ejecutar dentro del contenedor de Moodle (donde moosh y ${MANAGER_PASSWORD} están disponibles).
##########################################

echo >&2 "[2026_09_09_01] Importando categorías, cursos y usuarios que fallaron..."

#############################################################################################
# IDs de las categorías padre YA EXISTENTES en el despliegue
#############################################################################################
ID_CATEGORY_general=2   # General
ID_CATEGORY_sg=4        # IES SIERRA DE GUARA
ID_CATEGORY_cd=49       # CFP CAMPUS DIGITAL

#############################################################################################
# 1) Crear el usuario prof_je_cd (Jefatura de estudios de CFP CAMPUS DIGITAL)
#############################################################################################
echo "[2026_09_09_01] Creando usuario prof_je_cd..."
JE_CD_USER_ID=$(moosh user-create --password "${MANAGER_PASSWORD}" --email info@campusdigitalfp.com --digest 2 --city Aragón --country ES --firstname "Jefatura de estudios" --lastname "CFP CAMPUS DIGITAL" prof_je_cd | grep -o '[0-9]*' | tail -1)
echo "[2026_09_09_01] prof_je_cd creado con id ${JE_CD_USER_ID}"

#############################################################################################
# 2) Campo personalizado (categoría) y cohorte de jefaturas para prof_je_cd
#    El campo personalizado (fieldid=1) ya existe en el despliegue (userprofilefields-import
#    se ejecutó en la instalación inicial); aquí solo asignamos su valor.
#############################################################################################
echo "[2026_09_09_01] Asignando campo personalizado (categoría) a prof_je_cd..."
moosh sql-run "INSERT INTO mdl_user_info_data (userid, fieldid, data, dataformat) values ($JE_CD_USER_ID, 1, $ID_CATEGORY_cd, 0)"

echo "[2026_09_09_01] Añadiendo prof_je_cd a la cohorte jefaturas..."
moosh cohort-enrol -u "${JE_CD_USER_ID}" "jefaturas"

#############################################################################################
# 3-5) Crear las categorías que faltaban
#############################################################################################
echo "[2026_09_09_01] Creando categorías..."

# En CFP CAMPUS DIGITAL (id=49)
ID_CATEGORY_cd_rsn=$(moosh category-create -p "${ID_CATEGORY_cd}" -v 1 -d "CESIFC04" "Recursos y Servicios en la Nube" | grep -o '[0-9]*' | tail -1)
ID_CATEGORY_cd_dalp=$(moosh category-create -p "${ID_CATEGORY_cd}" -v 1 -d "CESIFC05" "Desarrollo de Aplicaciones en Lenguaje Python" | grep -o '[0-9]*' | tail -1)

# En IES SIERRA DE GUARA (id=4)
ID_CATEGORY_sg_ceti=$(moosh category-create -p "${ID_CATEGORY_sg}" -v 1 -d "CESIFC01" "Ciberseguridad en Entornos de las Tecnologías de la Información" | grep -o '[0-9]*' | tail -1)

echo "[2026_09_09_01] Categorías creadas -> RSN(CD)=${ID_CATEGORY_cd_rsn}  DALP(CD)=${ID_CATEGORY_cd_dalp}  CETI(SG)=${ID_CATEGORY_sg_ceti}"

#############################################################################################
# 6) Crear e importar (restaurar) TODOS los cursos del CSV.
#    Formato de cada línea: category_varname,shortname,fullname,visible
#    A los cursos generales (ayuda/profesorado/coordinacion) se les matriculan
#    sus cohortes correspondientes (misma lógica que new-install).
#############################################################################################
mapfile -t COURSES < /init-scripts/update/2026_09_09_01_courses_FPD.csv

echo "[2026_09_09_01] ***** Procesando cursos..."
for COURSE in "${COURSES[@]}"
do
    [ -z "${COURSE}" ] && continue
    echo "[2026_09_09_01] ***** Procesando línea ${COURSE}"
    CATEGORY=$(echo "${COURSE}" | cut -d ',' -f 1)
    SHORTNAME=$(echo "${COURSE}" | cut -d ',' -f 2)
    FULLNAME=$(echo "${COURSE}" | cut -d ',' -f 3)
    VISIBLE=$(echo "${COURSE}" | cut -d ',' -f 4)
    echo "[2026_09_09_01] CATEGORY '${CATEGORY}' (id=${!CATEGORY}) - SHORTNAME '${SHORTNAME}' - FULLNAME '${FULLNAME}' - VISIBLE '${VISIBLE}'"
    COURSE_ID=""

    if [ ! -f "/var/www/moodledata/repository/mbzs_curso_anterior/${SHORTNAME}.mbz" ]; then
        echo "[2026_09_09_01] ***** No existe /var/www/moodledata/repository/mbzs_curso_anterior/${SHORTNAME}.mbz, creando curso vacío en categoría ${!CATEGORY}"
        COURSE_ID=$(moosh course-create --category "${!CATEGORY}" --fullname "${FULLNAME}" --description "${FULLNAME}" "${SHORTNAME}" | grep -o '[0-9]*' | tail -1)
        moosh course-config-set course "${COURSE_ID}" fullname "${FULLNAME}"
    else
        echo "[2026_09_09_01] ***** Restaurando /var/www/moodledata/repository/mbzs_curso_anterior/${SHORTNAME}.mbz en categoría ${!CATEGORY}"
        RESTORE_OUTPUT=$(moosh course-restore /var/www/moodledata/repository/mbzs_curso_anterior/${SHORTNAME}.mbz "${!CATEGORY}")
        COURSE_ID=$(echo "${RESTORE_OUTPUT}" | grep "^Restoring" | sed 's/.*): //' | cut -d',' -f1)
        moosh course-config-set course "${COURSE_ID}" shortname "${SHORTNAME}"
        moosh course-config-set course "${COURSE_ID}" fullname "${FULLNAME}"
    fi
    moosh course-config-set course "${COURSE_ID}" visible "${VISIBLE}"

    # Matriculación de cohortes en los cursos generales (misma lógica que new-install)
    case "${SHORTNAME}" in
        "ayuda")
            echo "[2026_09_09_01] ****** Matriculando cohortes alumnado, profesorado, coordinacion y jefaturas en ${COURSE_ID}"
            moosh cohort-enrol -c "${COURSE_ID}" "alumnado"
            moosh cohort-enrol -c "${COURSE_ID}" "profesorado"
            moosh cohort-enrol -c "${COURSE_ID}" "coordinacion"
            moosh cohort-enrol -c "${COURSE_ID}" "jefaturas"
            ;;
        "profesorado")
            echo "[2026_09_09_01] ****** Matriculando cohortes profesorado, coordinacion y jefaturas en ${COURSE_ID}"
            moosh cohort-enrol -c "${COURSE_ID}" "profesorado"
            moosh cohort-enrol -c "${COURSE_ID}" "coordinacion"
            moosh cohort-enrol -c "${COURSE_ID}" "jefaturas"
            ;;
        "coordinacion")
            echo "[2026_09_09_01] ****** Matriculando cohortes coordinacion y jefaturas en ${COURSE_ID}"
            moosh cohort-enrol -c "${COURSE_ID}" "coordinacion"
            moosh cohort-enrol -c "${COURSE_ID}" "jefaturas"
            ;;
    esac
done

#############################################################################################
# 7) Matricular a prof_je_sg (rol jefatura-estudios) en TODOS los cursos de
#    IES SIERRA DE GUARA (subárbol de la categoría id=4), incluidos los nuevos de CETI.
#############################################################################################
echo "[2026_09_09_01] Buscando id de prof_je_sg..."
JE_SG_USER_ID=$(moosh -n sql-run "SELECT id FROM {user} WHERE username = 'prof_je_sg'" | grep -oP '\d+' | tail -1)
echo "[2026_09_09_01] prof_je_sg id=${JE_SG_USER_ID}. Matriculándolo en los cursos de IES SIERRA DE GUARA (id=${ID_CATEGORY_sg})..."

SG_COURSE_IDS=$(moosh -n sql-run "SELECT c.id FROM {course} c JOIN {course_categories} cc ON c.category = cc.id WHERE (cc.path = '/${ID_CATEGORY_sg}' OR cc.path LIKE '/${ID_CATEGORY_sg}/%') AND c.id > 1" | grep -oP '\d+')
for CID in ${SG_COURSE_IDS}; do
    echo "[2026_09_09_01] ***** Matriculando prof_je_sg (id ${JE_SG_USER_ID}) en el curso ${CID} con rol jefatura-estudios"
    moosh course-enrol -r jefatura-estudios -i "${CID}" "${JE_SG_USER_ID}"
done

#############################################################################################
# 8) Matricular a prof_je_cd (rol jefatura-estudios) en TODOS los cursos de
#    CFP CAMPUS DIGITAL (subárbol de la categoría id=49).
#############################################################################################
echo "[2026_09_09_01] Matriculando prof_je_cd en los cursos de CFP CAMPUS DIGITAL (id=${ID_CATEGORY_cd})..."
CD_COURSE_IDS=$(moosh -n sql-run "SELECT c.id FROM {course} c JOIN {course_categories} cc ON c.category = cc.id WHERE (cc.path = '/${ID_CATEGORY_cd}' OR cc.path LIKE '/${ID_CATEGORY_cd}/%') AND c.id > 1" | grep -oP '\d+')
for CID in ${CD_COURSE_IDS}; do
    echo "[2026_09_09_01] ***** Matriculando prof_je_cd (id ${JE_CD_USER_ID}) en el curso ${CID} con rol jefatura-estudios"
    moosh course-enrol -r jefatura-estudios -i "${CID}" "${JE_CD_USER_ID}"
done

echo >&2 "[2026_09_09_01] ... proceso completado. Hecho!"
