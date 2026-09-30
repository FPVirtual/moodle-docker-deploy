#!/bin/bash
##########################################
# Garantiza que cada curso de "Coordinación - Tutoría" (shortname terminado en t,
# p. ej. 50020125-IFC201-627t) tiene la sincronización con su cohorte, cuyo
# nombre es el shortname hasta el 2º guion sin incluir (50020125-IFC201).
#
# En new-install lo hace import_FPD_categories_and_courses.sh al crear los cursos,
# pero si la cohorte se añade a la plantilla después de la instalación la
# sincronización nunca llega a crearse (pasó en www con las de 50020125).
# moosh cohort-enrol no duplica la sincronización si ya existe, así que el
# script puede relanzarse sin efectos secundarios.
##########################################

echo >&2 "Checking cohort sync in tutoría courses..."

mapfile -t TUTORIAS < <(moosh -n sql-run "SELECT shortname FROM {course} WHERE shortname LIKE '%-%-%t'" | grep -oP '\[shortname\] => \K\S+')

for SHORTNAME in "${TUTORIAS[@]}"
do
    COHORT=$(echo "${SHORTNAME}" | cut -d '-' -f 1,2)
    COURSE_ID=$(moosh -n sql-run "SELECT id FROM {course} WHERE shortname = '${SHORTNAME}'" | grep -oP '\d+' | tail -1)
    COHORT_ID=$(moosh -n sql-run "SELECT id FROM {cohort} WHERE name = '${COHORT}'" | grep -oP '\d+' | tail -1)

    if [ -z "${COHORT_ID}" ]; then
        echo >&2 "****** WARNING: cohort ${COHORT} doesn't exist, course ${SHORTNAME} (id ${COURSE_ID}) left without cohort sync"
        continue
    fi

    echo "****** Enrolling the cohort ${COHORT} into the course ${SHORTNAME} (id ${COURSE_ID})"
    moosh -n cohort-enrol -c "${COURSE_ID}" "${COHORT}"
done

echo >&2 "... checking cohort sync in tutoría courses. Done!"
