#!/bin/bash
##########################################
#                                                       MUY IMPORTANTE
#                                                       MUY IMPORTANTE
#                                                       MUY IMPORTANTE
# MUY IMPORTANTE                  MUY IMPORTANTE
#     MUY IMPORTANTE          MUY IMPORTANTE
#         MUY IMPORTANTE  MUY IMPORTANTE
#     MUY IMPORTANTE          MUY IMPORTANTE
# MUY IMPORTANTE                  MUY IMPORTANTE
#                                                       MUY IMPORTANTE
#                                                       MUY IMPORTANTE
#                                                       MUY IMPORTANTE
#
# Los IDs de las categorias y cursos son invariables
# NO deben modificarse entre despliegues para mantener la compatibilidad
# con plugin de videollamadas y edición de contenidos
#
# NOTA: todas las llamadas a moosh usan -n porque, sin ese flag, moosh emite un
# aviso interactivo ("... run moosh with -n flag to skip that test") al detectar
# que /var/www/moodledata/repository pertenece a www-data y no a root; en modo no
# interactivo (docker exec) ese aviso puede abortar la operación sin devolver el
# id creado, dejando variables vacías (usuarios, categorías o cursos no creados).
# El script es además idempotente: comprueba antes de crear usuarios, categorías
# y cursos, para poder relanzarse tras un fallo parcial sin duplicar lo ya hecho.
##########################################

echo >&2 "Importing categories and courses..."

#############################################################################################
# Funciones auxiliares para creación idempotente (comprueban antes de crear)
#############################################################################################

# get_or_create_user <username> <resto de argumentos de "moosh user-create" sin el username>
get_or_create_user () {
    local USERNAME="$1"
    shift
    local ID
    ID=$(moosh -n sql-run "SELECT id FROM {user} WHERE username = '${USERNAME}'" | grep -oP '\d+' | tail -1)
    if [ -z "${ID}" ]; then
        ID=$(moosh -n user-create "$@" "${USERNAME}" | grep -o '[0-9]*' | tail -1)
    fi
    echo "${ID}"
}

# get_or_create_category <parent_id> <idnumber> <name>
get_or_create_category () {
    local PARENT="$1"
    local IDNUMBER="$2"
    local NAME="$3"
    local ESCAPED_NAME=${NAME//\'/\'\'}
    local ID
    ID=$(moosh -n sql-run "SELECT id FROM {course_categories} WHERE parent = ${PARENT} AND name = '${ESCAPED_NAME}'" | grep -oP '\d+' | tail -1)
    if [ -z "${ID}" ]; then
        ID=$(moosh -n category-create -p "${PARENT}" -v 1 -d "${IDNUMBER}" "${NAME}" | grep -oP '\d+' | tail -1)
    fi
    echo "${ID}"
}

# assign_category_field <user_id> <category_id>
assign_category_field () {
    local USERID="$1"
    local CATEGORYID="$2"
    local EXISTS
    EXISTS=$(moosh -n sql-run "SELECT id FROM {user_info_data} WHERE userid = ${USERID} AND fieldid = 1" | grep -oP '\d+' | tail -1)
    if [ -z "${EXISTS}" ]; then
        moosh -n sql-run "INSERT INTO mdl_user_info_data (userid, fieldid, data, dataformat) values (${USERID}, 1, ${CATEGORYID}, 0)"
    fi
}

#############################################################################################
# Creo los usuarios, roles,... específicos de FPD:
#############################################################################################
echo "Creating users, roles,... of PFD"

# Create admin user for FPD

echo "Creating admin user for FP..."
FPD_ADMIN_USER_ID=$(get_or_create_user admin2 --password "${FPD_PASSWORD}" --email "${FPD_EMAIL}" --digest 2 --city Aragón --country ES --firstname fp --lastname distancia)
moosh -n config-set siteadmins 2,"${FPD_ADMIN_USER_ID}"

# Crear rol y usuario de inspección
echo "Creating inspeccion role and configuring it..."
INSPECCION_ROLE_ID=$(moosh -n role-create -d "Los usuarios con rol de inspección tienen acceso a determinados informes" -a manager -n "Inspeccion" inspeccion | grep -o '[0-9]*' | tail -1)

# set permissions to inspeccion role
moosh -n role-import -f /init-scripts/themes/fpdist/roles/role-inspeccion.xml

# Creating user
INSPECCION_USER_ID=$(get_or_create_user profinspector --password "${MANAGER_PASSWORD}" --email inspeccion@educa.aragon.es --digest 2 --city Aragón --country ES --firstname Inspección --lastname Inspección)

# Assiging user to r
moosh -n user-assign-system-role profinspector inspeccion

# Crear rol de jefaturas y usuarios
echo "Creating jefatura-estudios role and configuring it..."
JEFATURA_ROLE_ID=$(moosh -n role-create -d "Los usuarios con rol de inspección tienen acceso a determinados informes" -c system,category,course,block -n "Jefatura de estudios" jefatura-estudios | grep -o '[0-9]*' | tail -1)

# Setting permissions to jefatura de estudios role
moosh -n role-import -f /init-scripts/themes/fpdist/roles/role-jefatura-estudios.xml

# Creating users
JE_SG_USER_ID=$(get_or_create_user prof_je_sg --password "${MANAGER_PASSWORD}" --email iessguhuesca@educa.aragon.es --digest 2 --city Aragón --country ES --firstname "Jefatura de estudios" --lastname "IES Sierra de Guara")
JE_SE_USER_ID=$(get_or_create_user prof_je_se --password "${MANAGER_PASSWORD}" --email iessemteruel@educa.aragon.es --digest 2 --city Aragón --country ES --firstname "Jefatura de estudios" --lastname "IES SANTA EMERENCIANA")
JE_TM_USER_ID=$(get_or_create_user prof_je_tm --password "${MANAGER_PASSWORD}" --email iestiemposmodernos@educa.aragon.es --digest 2 --city Aragón --country ES --firstname "Jefatura de estudios" --lastname "IES TIEMPOS MODERNOS")
JE_LE_USER_ID=$(get_or_create_user prof_je_le --password "${MANAGER_PASSWORD}" --email cpilosenlaces@educa.aragon.es --digest 2 --city Aragón --country ES --firstname "Jefatura de estudios" --lastname "CPIFP LOS ENLACES")
JE_CA_USER_ID=$(get_or_create_user prof_je_ca --password "${MANAGER_PASSWORD}" --email cpifpcorona@educa.aragon.es --digest 2 --city Aragón --country ES --firstname "Jefatura de estudios" --lastname "CPIFP CORONA DE ARAGÓN")
JE_PI_USER_ID=$(get_or_create_user prof_je_pi --password "${MANAGER_PASSWORD}" --email cpifppiramide@educa.aragon.es --digest 2 --city Aragón --country ES --firstname "Jefatura de estudios" --lastname "CPIFP PIRÁMIDE")
JE_SB_USER_ID=$(get_or_create_user prof_je_sb --password "${MANAGER_PASSWORD}" --email ifpeteruel@educa.aragon.es --digest 2 --city Aragón --country ES --firstname "Jefatura de estudios" --lastname "CPIFP SAN BLAS")
JE_MI_USER_ID=$(get_or_create_user prof_je_mi --password "${MANAGER_PASSWORD}" --email iesmirzaragoza@educa.aragon.es --digest 2 --city Aragón --country ES --firstname "Jefatura de estudios" --lastname "IES MIRALBUENO")
JE_PS_USER_ID=$(get_or_create_user prof_je_ps --password "${MANAGER_PASSWORD}" --email iespsezaragoza@educa.aragon.es --digest 2 --city Aragón --country ES --firstname "Jefatura de estudios" --lastname "IES PABLO SERRANO")
JE_BA_USER_ID=$(get_or_create_user prof_je_ba --password "${MANAGER_PASSWORD}" --email cpifpbajoaragon@educa.aragon.es --digest 2 --city Aragón --country ES --firstname "Jefatura de estudios" --lastname "CPIFP BAJO ARAGÓN")
JE_RG_USER_ID=$(get_or_create_user prof_je_rg --password "${MANAGER_PASSWORD}" --email iesrgazaragoza@educa.aragon.es --digest 2 --city Aragón --country ES --firstname "Jefatura de estudios" --lastname "IES RÍO GÁLLEGO")
JE_VT_USER_ID=$(get_or_create_user prof_je_vt --password "${MANAGER_PASSWORD}" --email iesvtteruel@educa.aragon.es --digest 2 --city Aragón --country ES --firstname "Jefatura de estudios" --lastname "IES VEGA DEL TURIA")
JE_LB_USER_ID=$(get_or_create_user prof_je_lb --password "${MANAGER_PASSWORD}" --email ieslbuzaragoza@educa.aragon.es --digest 2 --city Aragón --country ES --firstname "Jefatura de estudios" --lastname "IES LUIS BUÑUEL")
JE_MV_USER_ID=$(get_or_create_user prof_je_mv --password "${MANAGER_PASSWORD}" --email iesmvbarbastro@educa.aragon.es --digest 2 --city Aragón --country ES --firstname "Jefatura de estudios" --lastname "IES MARTÍNEZ VARGAS")
JE_AV_USER_ID=$(get_or_create_user prof_je_av --password "${MANAGER_PASSWORD}" --email iesavempace@educa.aragon.es --digest 2 --city Aragón --country ES --firstname "Jefatura de estudios" --lastname "IES AVEMPACE")
JE_MM_USER_ID=$(get_or_create_user prof_je_mm --password "${MANAGER_PASSWORD}" --email iesmmozaragoza@educa.aragon.es --digest 2 --city Aragón --country ES --firstname "Jefatura de estudios" --lastname "IES MARÍA MOLINER")
JE_CD_USER_ID=$(get_or_create_user prof_je_cd --password "${MANAGER_PASSWORD}" --email info@campusdigitalfp.com --digest 2 --city Aragón --country ES --firstname "Jefatura de estudios" --lastname "CFP CAMPUS DIGITAL")
JE_FLC_USER_ID=$(get_or_create_user prof_je_flc --password "${MANAGER_PASSWORD}" --email iesutrillas@educa.aragon.es --digest 2 --city Aragón --country ES --firstname "Jefatura de estudios" --lastname "IES FERNANDO LÁZARO CARRETER")

ADMIN2=$(get_or_create_user admin2 --password "${MANAGER_PASSWORD}" --email fpdistancia@aragon.es --digest 2 --city Aragón --country ES --firstname "Administrador" --lastname "Campus Digital FP - Virtual")
ADMIN3=$(get_or_create_user admin3 --password "${MANAGER_PASSWORD}" --email amcandialq@campusdigitalfp.com --digest 2 --city Aragón --country ES --firstname "Administrador" --lastname "Ana María Candial")
ADMIN4=$(get_or_create_user admin4 --password "${MANAGER_PASSWORD}" --email jefaturas@educa.aragon.es --digest 2 --city Aragón --country ES --firstname "Administrador" --lastname "Darío Axel Ureña")
ADMIN5=$(get_or_create_user admin5 --password "${MANAGER_PASSWORD}" --email jefaturas@educa.aragon.es --digest 2 --city Aragón --country ES --firstname "Administrador" --lastname "Prácticas")

#############################################################################################
# Creo las categorías:
#############################################################################################
echo "Creating structure for categories..."

ID_CATEGORY_miscelanea=1
ID_CATEGORY_general=$(get_or_create_category 0 "general" "General")
ID_CATEGORY_app=$(get_or_create_category 0 "app" "NO BORRAR - APP MOVIL")

ID_CATEGORY_sg=$(get_or_create_category 0 "22002521" "IES SIERRA DE GUARA")
ID_CATEGORY_sg_ga=$(get_or_create_category "${ID_CATEGORY_sg}" "ADG201" "Gestión Administrativa")
ID_CATEGORY_sg_ceti=$(get_or_create_category "${ID_CATEGORY_sg}" "CESIFC01" "Ciberseguridad en Entornos de las Tecnologías de la Información")

ID_CATEGORY_se=$(get_or_create_category 0 "44003211" "IES SANTA EMERENCIANA")
ID_CATEGORY_se_ga=$(get_or_create_category "${ID_CATEGORY_se}" "ADG201" "Gestión Administrativa")

ID_CATEGORY_tm=$(get_or_create_category 0 "50010511" "IES TIEMPOS MODERNOS")
ID_CATEGORY_tm_ga=$(get_or_create_category "${ID_CATEGORY_tm}" "ADG201" "Gestión Administrativa")

ID_CATEGORY_le=$(get_or_create_category 0 "50010314" "CPIFP LOS ENLACES")
ID_CATEGORY_le_smr=$(get_or_create_category "${ID_CATEGORY_le}" "IFC201" "Sistemas Microinformáticos y Redes")
ID_CATEGORY_le_ac=$(get_or_create_category "${ID_CATEGORY_le}" "COM201" "Actividades Comerciales")
ID_CATEGORY_le_ci=$(get_or_create_category "${ID_CATEGORY_le}" "COM301" "Comercio Internacional")
ID_CATEGORY_le_gvec=$(get_or_create_category "${ID_CATEGORY_le}" "COM302" "Gestión de Ventas y Espacios Comerciales")
ID_CATEGORY_le_tl=$(get_or_create_category "${ID_CATEGORY_le}" "COM303" "Transporte y Logística")
ID_CATEGORY_le_daw=$(get_or_create_category "${ID_CATEGORY_le}" "IFC303" "Desarrollo de Aplicaciones WEB")
ID_CATEGORY_le_pae=$(get_or_create_category "${ID_CATEGORY_le}" "IMS302" "Producción de Audiovisuales y Espectáculos")

ID_CATEGORY_ca=$(get_or_create_category 0 "50018829" "CPIFP CORONA DE ARAGÓN")
ID_CATEGORY_ca_ad=$(get_or_create_category "${ID_CATEGORY_ca}" "ADG302" "Asistencia a la Dirección")
ID_CATEGORY_ca_af=$(get_or_create_category "${ID_CATEGORY_ca}" "ADG301" "Administración y Finanzas")
ID_CATEGORY_ca_lacc=$(get_or_create_category "${ID_CATEGORY_ca}" "QUI301" "Laboratorio de Análisis y de Control de Calidad")

ID_CATEGORY_pi=$(get_or_create_category 0 "22010712" "CPIFP PIRÁMIDE")
ID_CATEGORY_pi_iea=$(get_or_create_category "${ID_CATEGORY_pi}" "ELE202" "Instalaciones Eléctricas y Automáticas")

ID_CATEGORY_sb=$(get_or_create_category 0 "44003028" "CPIFP SAN BLAS")
ID_CATEGORY_sb_eca=$(get_or_create_category "${ID_CATEGORY_sb}" "SEA301" "Educación y Control Ambiental")

ID_CATEGORY_mi=$(get_or_create_category 0 "50010156" "IES MIRALBUENO")
ID_CATEGORY_mi_avge=$(get_or_create_category "${ID_CATEGORY_mi}" "HOT301" "Agencias de Viajes y Gestión de Eventos")

ID_CATEGORY_ps=$(get_or_create_category 0 "50010144" "IES PABLO SERRANO")
ID_CATEGORY_ps_asir=$(get_or_create_category "${ID_CATEGORY_ps}" "IFC301" "Administración de Sistemas Informáticos en Red")

ID_CATEGORY_ba=$(get_or_create_category 0 "44010537" "CPIFP BAJO ARAGÓN")
ID_CATEGORY_ba_dam=$(get_or_create_category "${ID_CATEGORY_ba}" "IFC301" "Desarrollo de Aplicaciones Multiplataforma")

ID_CATEGORY_rg=$(get_or_create_category 0 "50009567" "IES RÍO GÁLLEGO")
ID_CATEGORY_rg_sti=$(get_or_create_category "${ID_CATEGORY_rg}" "ELE304" "Sistemas de Telecomunicaciones e Informáticos")
ID_CATEGORY_rg_fp=$(get_or_create_category "${ID_CATEGORY_rg}" "SAN202" "Farmacia y Parafarmacia")
ID_CATEGORY_rg_es=$(get_or_create_category "${ID_CATEGORY_rg}" "SAN203" "Emergencias Sanitarias")

ID_CATEGORY_vt=$(get_or_create_category 0 "44003235" "IES VEGA DEL TURIA")
ID_CATEGORY_vt_es=$(get_or_create_category "${ID_CATEGORY_vt}" "SAN203" "Emergencias Sanitarias")

ID_CATEGORY_lb=$(get_or_create_category 0 "50008460" "IES LUIS BUÑUEL")
ID_CATEGORY_lb_apsd=$(get_or_create_category "${ID_CATEGORY_lb}" "SSC201" "Atención a Personas en situación de Dependencia")


ID_CATEGORY_mv=$(get_or_create_category 0 "22004611" "IES MARTÍNEZ VARGAS")
ID_CATEGORY_mv_ei=$(get_or_create_category "${ID_CATEGORY_mv}" "SSC302" "Educación Infantil (Formación Profesional)")

ID_CATEGORY_av=$(get_or_create_category 0 "50009348" "IES AVEMPACE")
ID_CATEGORY_av_ei=$(get_or_create_category "${ID_CATEGORY_av}" "SSC302" "Educación Infantil (Formación Profesional)")

ID_CATEGORY_mm=$(get_or_create_category 0 "50008642" "IES MARÍA MOLINER")
ID_CATEGORY_mm_is=$(get_or_create_category "${ID_CATEGORY_mm}" "SSC303" "Integración Social")

ID_CATEGORY_flc=$(get_or_create_category 0 "44004550" "IES FERNANDO LÁZARO CARRETER")
ID_CATEGORY_flc_mi=$(get_or_create_category "${ID_CATEGORY_flc}" "IMA302" "Mecatrónica Industrial")

ID_CATEGORY_cd=$(get_or_create_category 0 "50020125" "CFP CAMPUS DIGITAL")
ID_CATEGORY_cd_smr=$(get_or_create_category "${ID_CATEGORY_cd}" "IFC201" "Sistemas Microinformáticos y Redes")
ID_CATEGORY_cd_asir=$(get_or_create_category "${ID_CATEGORY_cd}" "IFC301" "Administración de Sistemas Informáticos en Red")
ID_CATEGORY_cd_dam=$(get_or_create_category "${ID_CATEGORY_cd}" "IFC302" "Desarrollo de Aplicaciones Multiplataforma")
ID_CATEGORY_cd_daw=$(get_or_create_category "${ID_CATEGORY_cd}" "IFC303" "Desarrollo de Aplicaciones WEB")
ID_CATEGORY_cd_iabd=$(get_or_create_category "${ID_CATEGORY_cd}" "CESIFC02" "Inteligencia Artificial y Big Data")
ID_CATEGORY_cd_ceti=$(get_or_create_category "${ID_CATEGORY_cd}" "CESIFC01" "Ciberseguridad en Entornos de las Tecnologías de la Información")
ID_CATEGORY_cd_rsn=$(get_or_create_category "${ID_CATEGORY_cd}" "CESIFC04" "Recursos y Servicios en la Nube")
ID_CATEGORY_cd_dalp=$(get_or_create_category "${ID_CATEGORY_cd}" "CESIFC05" "Desarrollo de Aplicaciones en Lenguaje Python")

#############################################################################################
# A los usuarios jefes de estudios les cambio su campo personalizado para que tengan el valor correspondiente a su categoría
#############################################################################################

# Añadir el campo personalizado a los usuarios y asignar a cada jefe de estudios el suyo
echo "Creating custom fields for jefatura estudios..."
# # Creo el campo personalizado
moosh -n userprofilefields-import /init-scripts/themes/fpdist/custom-fields/user_profile_fields.csv

# # Asignar a cada usuario el valor que le corresponde en el campo personalizado
assign_category_field "${JE_SG_USER_ID}" "${ID_CATEGORY_sg}"
assign_category_field "${JE_SE_USER_ID}" "${ID_CATEGORY_se}"
assign_category_field "${JE_TM_USER_ID}" "${ID_CATEGORY_tm}"
assign_category_field "${JE_LE_USER_ID}" "${ID_CATEGORY_le}"
assign_category_field "${JE_CA_USER_ID}" "${ID_CATEGORY_ca}"
assign_category_field "${JE_PI_USER_ID}" "${ID_CATEGORY_pi}"
assign_category_field "${JE_SB_USER_ID}" "${ID_CATEGORY_sb}"
assign_category_field "${JE_MI_USER_ID}" "${ID_CATEGORY_mi}"
assign_category_field "${JE_PS_USER_ID}" "${ID_CATEGORY_ps}"
assign_category_field "${JE_BA_USER_ID}" "${ID_CATEGORY_ba}"
assign_category_field "${JE_RG_USER_ID}" "${ID_CATEGORY_rg}"
assign_category_field "${JE_VT_USER_ID}" "${ID_CATEGORY_vt}"
assign_category_field "${JE_LB_USER_ID}" "${ID_CATEGORY_lb}"
assign_category_field "${JE_MV_USER_ID}" "${ID_CATEGORY_mv}"
assign_category_field "${JE_AV_USER_ID}" "${ID_CATEGORY_av}"
assign_category_field "${JE_MM_USER_ID}" "${ID_CATEGORY_mm}"
assign_category_field "${JE_FLC_USER_ID}" "${ID_CATEGORY_flc}"
assign_category_field "${JE_CD_USER_ID}" "${ID_CATEGORY_cd}"


#############################################################################################
# Creo las cohortes
#############################################################################################
echo "Creating cohorts..."

moosh -n cohort-create -d "alumnado" -i alumnado -c "${ID_CATEGORY_general}" "alumnado"
moosh -n cohort-create -d "profesorado" -i profesorado -c "${ID_CATEGORY_general}" "profesorado"
moosh -n cohort-create -d "coordinacion" -i coordinacion -c "${ID_CATEGORY_general}" "coordinacion"
moosh -n cohort-create -d "jefaturas" -i jefaturas -c "${ID_CATEGORY_general}" "jefaturas"

moosh -n cohort-create -d "22002521-ADG201" -i 22002521-ADG201 -c "${ID_CATEGORY_sg}" "22002521-ADG201"
moosh -n cohort-create -d "22004611-SSC302" -i 22004611-SSC302 -c "${ID_CATEGORY_mv}" "22004611-SSC302"
moosh -n cohort-create -d "22010712-ELE202" -i 22010712-ELE202 -c "${ID_CATEGORY_pi}" "22010712-ELE202"
moosh -n cohort-create -d "44003028-SEA301" -i 44003028-SEA301 -c "${ID_CATEGORY_sb}" "44003028-SEA301"
moosh -n cohort-create -d "44003211-ADG201" -i 44003211-ADG201 -c "${ID_CATEGORY_se}" "44003211-ADG201"
moosh -n cohort-create -d "44003235-SAN203" -i 44003235-SAN203 -c "${ID_CATEGORY_vt}" "44003235-SAN203"
moosh -n cohort-create -d "44010537-IFC302" -i 44010537-IFC302 -c "${ID_CATEGORY_ba}" "44010537-IFC302"
moosh -n cohort-create -d "50008460-SSC201" -i 50008460-SSC201 -c "${ID_CATEGORY_lb}" "50008460-SSC201"
moosh -n cohort-create -d "50008642-SSC303" -i 50008642-SSC303 -c "${ID_CATEGORY_mm}" "50008642-SSC303"
moosh -n cohort-create -d "50009348-SSC302" -i 50009348-SSC302 -c "${ID_CATEGORY_av}" "50009348-SSC302"
moosh -n cohort-create -d "50009567-ELE304" -i 50009567-ELE304 -c "${ID_CATEGORY_rg}" "50009567-ELE304"
moosh -n cohort-create -d "50009567-SAN202" -i 50009567-SAN202 -c "${ID_CATEGORY_rg}" "50009567-SAN202"
moosh -n cohort-create -d "50009567-SAN203" -i 50009567-SAN203 -c "${ID_CATEGORY_rg}" "50009567-SAN203"
moosh -n cohort-create -d "50010144-IFC301" -i 50010144-IFC301 -c "${ID_CATEGORY_ps}" "50010144-IFC301"
moosh -n cohort-create -d "50010156-HOT301" -i 50010156-HOT301 -c "${ID_CATEGORY_mi}" "50010156-HOT301"
moosh -n cohort-create -d "50010314-COM201" -i 50010314-COM201 -c "${ID_CATEGORY_le}" "50010314-COM201"
moosh -n cohort-create -d "50010314-COM301" -i 50010314-COM301 -c "${ID_CATEGORY_le}" "50010314-COM301"
moosh -n cohort-create -d "50010314-COM302" -i 50010314-COM302 -c "${ID_CATEGORY_le}" "50010314-COM302"
moosh -n cohort-create -d "50010314-COM303" -i 50010314-COM303 -c "${ID_CATEGORY_le}" "50010314-COM303"
moosh -n cohort-create -d "50010314-IFC201" -i 50010314-IFC201 -c "${ID_CATEGORY_le}" "50010314-IFC201"
moosh -n cohort-create -d "50010314-IFC303" -i 50010314-IFC303 -c "${ID_CATEGORY_le}" "50010314-IFC303"
moosh -n cohort-create -d "50010314-IMS302" -i 50010314-IMS302 -c "${ID_CATEGORY_le}" "50010314-IMS302"
moosh -n cohort-create -d "50010511-ADG201" -i 50010511-ADG201 -c "${ID_CATEGORY_tm}" "50010511-ADG201"
moosh -n cohort-create -d "50018829-ADG301" -i 50018829-ADG301 -c "${ID_CATEGORY_ca}" "50018829-ADG301"
moosh -n cohort-create -d "50018829-ADG302" -i 50018829-ADG302 -c "${ID_CATEGORY_ca}" "50018829-ADG302"
moosh -n cohort-create -d "50018829-QUI301" -i 50018829-QUI301 -c "${ID_CATEGORY_ca}" "50018829-QUI301"
moosh -n cohort-create -d "44004550-IMA302" -i 44004550-IMA302 -c "${ID_CATEGORY_flc}" "44004550-IMA302"

#############################################################################################
# Añado a la cohorte de jefatura de estudios a los diferentes usuarios de jefes de estudios
#############################################################################################
echo "Adding jefatura users to cohort jefaturas..."

moosh -n cohort-enrol -u "${JE_SG_USER_ID}" "jefaturas"
moosh -n cohort-enrol -u "${JE_SE_USER_ID}" "jefaturas"
moosh -n cohort-enrol -u "${JE_TM_USER_ID}" "jefaturas"
moosh -n cohort-enrol -u "${JE_LE_USER_ID}" "jefaturas"
moosh -n cohort-enrol -u "${JE_CA_USER_ID}" "jefaturas"
moosh -n cohort-enrol -u "${JE_PI_USER_ID}" "jefaturas"
moosh -n cohort-enrol -u "${JE_SB_USER_ID}" "jefaturas"
moosh -n cohort-enrol -u "${JE_MI_USER_ID}" "jefaturas"
moosh -n cohort-enrol -u "${JE_PS_USER_ID}" "jefaturas"
moosh -n cohort-enrol -u "${JE_BA_USER_ID}" "jefaturas"
moosh -n cohort-enrol -u "${JE_RG_USER_ID}" "jefaturas"
moosh -n cohort-enrol -u "${JE_VT_USER_ID}" "jefaturas"
moosh -n cohort-enrol -u "${JE_LB_USER_ID}" "jefaturas"
moosh -n cohort-enrol -u "${JE_MV_USER_ID}" "jefaturas"
moosh -n cohort-enrol -u "${JE_AV_USER_ID}" "jefaturas"
moosh -n cohort-enrol -u "${JE_MM_USER_ID}" "jefaturas"
moosh -n cohort-enrol -u "${JE_FLC_USER_ID}" "jefaturas"
moosh -n cohort-enrol -u "${JE_CD_USER_ID}" "jefaturas"


#############################################################################################
# Creo los cursos intentando restaurar su contenido
#############################################################################################

# IMPORTANTE (Lee abajo)
# IMPORTANTE (Lee abajo)
# IMPORTANTE (Lee abajo)
# La siguiente lista de cursos NO puede ser modificada en su orden. Si un curso desaparece se cambiará
# el 1 del final por un 0. Si se añaden nuevos cursos se añadirán al final, nunca
# junto a los de su centro o estudio pues eso cambiaría el orden
# IMPORTANTE (Lee arriba)
# IMPORTANTE (Lee arriba)
# IMPORTANTE (Lee arriba)

# Lista de cursos en /init-scripts/new-install/courses_FPD.csv
# formato por línea: category,shortname,fullname,visible
mapfile -t COURSES < /init-scripts/new-install/courses_FPD.csv

echo "***** Processing courses..."
for COURSE in "${COURSES[@]}"
do
    echo "***** Processing line ${COURSE}"
    CATEGORY=$(echo "${COURSE}" | cut -d ',' -f 1)
    SHORTNAME=$(echo "${COURSE}" | cut -d ',' -f 2)
    FULLNAME=$(echo "${COURSE}" | cut -d ',' -f 3)
    VISIBLE=$(echo "${COURSE}" | cut -d ',' -f 4)
    echo "CATEGORY '${CATEGORY}' - SHORTNAME '${SHORTNAME}' - FULLNAME '${FULLNAME}' - VISIBLE '${VISIBLE}'"

    COURSE_ID=$(moosh -n sql-run "SELECT id FROM {course} WHERE shortname = '${SHORTNAME}'" | grep -oP '\d+' | tail -1)

    if [ -n "${COURSE_ID}" ]; then
        echo "***** The course '${SHORTNAME}' already exists with id ${COURSE_ID}, skipping creation"
    elif [ ! -f "/var/www/moodledata/repository/mbzs_curso_anterior/${SHORTNAME}.mbz" ]; then
        # Si no existe el curso, lo creo
        echo "***** The course /var/www/moodledata/repository/mbzs_curso_anterior/${SHORTNAME}.mbz doesn't exist, creating empty course ${COURSE} into category ${CATEGORY}"
        COURSE_ID=$(moosh -n course-create --category "${!CATEGORY}" --fullname "${FULLNAME}" --description "${FULLNAME}" "${SHORTNAME}" | grep -o '[0-9]*' | tail -1)
        moosh -n course-config-set course "${COURSE_ID}" fullname "${FULLNAME}"
    else
        # Si existe el curso lo restauro
        echo "***** Restoring /var/www/moodledata/repository/mbzs_curso_anterior/${SHORTNAME}.mbz course to category ${CATEGORY}"
        RESTORE_OUTPUT=$(moosh -n course-restore /var/www/moodledata/repository/mbzs_curso_anterior/${SHORTNAME}.mbz "${!CATEGORY}")
        COURSE_ID=$(echo "${RESTORE_OUTPUT}" | grep "^Restoring" | sed 's/.*): //' | cut -d',' -f1)
        # Configuro full y short names por si al restaurar había datos erróneos en origen
        moosh -n course-config-set course "${COURSE_ID}" shortname "${SHORTNAME}"
        moosh -n course-config-set course "${COURSE_ID}" fullname "${FULLNAME}"
    fi
    moosh -n course-config-set course "${COURSE_ID}" visible "${VISIBLE}"
    # TODO: valorar si los que no son visible los borro una vez creados <- verificar no afecta a los IDs

    # matriculo en el curso de ayuda a las cohortes alumnado, profesorado, coordinacion y jefaturas
    if [[ ${SHORTNAME} == 'ayuda' ]];
    then
        COHORT=$(echo "${SHORTNAME}" | cut -d '-' -f 1,2)
        echo "****** Enrolling the cohorts alumnado, profesorado, coordinacion and jefaturas into the course_id ${COURSE_ID}"
        moosh -n cohort-enrol -c "${COURSE_ID}" "alumnado"
        moosh -n cohort-enrol -c "${COURSE_ID}" "profesorado"
        moosh -n cohort-enrol -c "${COURSE_ID}" "coordinacion"
        moosh -n cohort-enrol -c "${COURSE_ID}" "jefaturas"
    fi

    # matriculo en el curso de profesorado a las cohortes profesorado, coordinacion y jefaturas
    if [[ ${SHORTNAME} == 'profesorado' ]];
    then
        COHORT=$(echo "${SHORTNAME}" | cut -d '-' -f 1,2)
        echo "****** Enrolling the cohorts profesorado, coordinacion and jefaturas into the course_id ${COURSE_ID}"
        moosh -n cohort-enrol -c "${COURSE_ID}" "profesorado"
        moosh -n cohort-enrol -c "${COURSE_ID}" "coordinacion"
        moosh -n cohort-enrol -c "${COURSE_ID}" "jefaturas"
    fi

    # matriculo en el curso de coordinacion a las cohortes coordinacion y jefaturas
    if [[ ${SHORTNAME} == 'coordinacion' ]];
    then
        COHORT=$(echo "${SHORTNAME}" | cut -d '-' -f 1,2)
        echo "****** Enrolling the cohorts coordinacion and jefaturas into the course_id ${COURSE_ID}"
        moosh -n cohort-enrol -c "${COURSE_ID}" "coordinacion"
        moosh -n cohort-enrol -c "${COURSE_ID}" "jefaturas"
    fi

    # matriculo en el curso de marketplaces a los usuarios que nos piden desde la app
    if [[ ${SHORTNAME} == 'marketplaces' ]];
    then
        COHORT=$(echo "${SHORTNAME}" | cut -d '-' -f 1,2)
        echo "****** Creating and enrolling the users for marketplaces into the course_id ${COURSE_ID}"
        FPD_APP_USER_STUDENT_ID=$(get_or_create_user demoapp --password "${APP_PASSWORD}" --email alumnado@education.catedu.es --digest 2 --city Aragón --country ES --firstname student --lastname demoapp)
        FPD_APP_USER_TEACHER_ID=$(get_or_create_user profesor1 --password "${APP_TEACHER_PASSWORD}" --email alumnado@education.catedu.es --digest 2 --city Aragón --country ES --firstname teacher --lastname demoapp)

        moosh -n course-enrol -r editingteacher -i "${COURSE_ID}" "${FPD_APP_USER_TEACHER_ID}"
        moosh -n course-enrol -r student -i "${COURSE_ID}" "${FPD_APP_USER_STUDENT_ID}"
    fi

    # si el cod_ensenanza contiene una t al final (es una tutoría) entonces matriculo a la cohorte en ese curso
    if [[ ${SHORTNAME} == *t ]];
    then
        COHORT=$(echo "${SHORTNAME}" | cut -d '-' -f 1,2)
        echo "****** Enrolling the cohort ${COHORT} into the course_id ${COURSE_ID}"
        moosh -n cohort-enrol -c "${COURSE_ID}" "${COHORT}"
    fi

    # Matricular a jefes de estudios en los cursos en base al ID centro del shortname
    if [[ ${SHORTNAME} == *-*-* ]];
    then
        CODCENTRO=$(echo "${SHORTNAME}" | cut -d '-' -f 1)
        case "${CODCENTRO}" in
            "22002521") # IES Sierra de Guara
                echo "****** Enrolling the user ${JE_SG_USER_ID} into the course_id ${COURSE_ID} with role jefatura-estudios"
                moosh -n course-enrol -r jefatura-estudios -i "${COURSE_ID}" "${JE_SG_USER_ID}"
                ;;
            "44003211") # IES SANTA EMERENCIANA
                echo "****** Enrolling the user ${JE_SE_USER_ID} into the course_id ${COURSE_ID} with role jefatura-estudios"
                moosh -n course-enrol -r jefatura-estudios -i "${COURSE_ID}" "${JE_SE_USER_ID}"
                ;;
            "50010511") # IES TIEMPOS MODERNOS
                echo "****** Enrolling the user ${JE_TM_USER_ID} into the course_id ${COURSE_ID} with role jefatura-estudios"
                moosh -n course-enrol -r jefatura-estudios -i "${COURSE_ID}" "${JE_TM_USER_ID}"
                ;;
            "50010314") # CPIFP LOS ENLACES
                echo "****** Enrolling the user ${JE_LE_USER_ID} into the course_id ${COURSE_ID} with role jefatura-estudios"
                moosh -n course-enrol -r jefatura-estudios -i "${COURSE_ID}" "${JE_LE_USER_ID}"
                ;;
            "50018829") # CPIFP CORONA DE ARAGÓN
                echo "****** Enrolling the user ${JE_CA_USER_ID} into the course_id ${COURSE_ID} with role jefatura-estudios"
                moosh -n course-enrol -r jefatura-estudios -i "${COURSE_ID}" "${JE_CA_USER_ID}"
                ;;
            "22010712") # CPIFP PIRÁMIDE
                echo "****** Enrolling the user ${JE_PI_USER_ID} into the course_id ${COURSE_ID} with role jefatura-estudios"
                moosh -n course-enrol -r jefatura-estudios -i "${COURSE_ID}" "${JE_PI_USER_ID}"
                ;;
            "44003028") # CPIFP SAN BLAS
                echo "****** Enrolling the user ${JE_SB_USER_ID} into the course_id ${COURSE_ID} with role jefatura-estudios"
                moosh -n course-enrol -r jefatura-estudios -i "${COURSE_ID}" "${JE_SB_USER_ID}"
                ;;
            "50010156") # IES MIRALBUENO
                echo "****** Enrolling the user ${JE_MI_USER_ID} into the course_id ${COURSE_ID} with role jefatura-estudios"
                moosh -n course-enrol -r jefatura-estudios -i "${COURSE_ID}" "${JE_MI_USER_ID}"
                ;;
            "50010144") # IES PABLO SERRANO
                echo "****** Enrolling the user ${JE_PS_USER_ID} into the course_id ${COURSE_ID} with role jefatura-estudios"
                moosh -n course-enrol -r jefatura-estudios -i "${COURSE_ID}" "${JE_PS_USER_ID}"
                ;;
            "44010537") # CPIFP BAJO ARAGÓN
                echo "****** Enrolling the user ${JE_BA_USER_ID} into the course_id ${COURSE_ID} with role jefatura-estudios"
                moosh -n course-enrol -r jefatura-estudios -i "${COURSE_ID}" "${JE_BA_USER_ID}"
                ;;
            "50009567") # IES RÍO GÁLLEGO
                echo "****** Enrolling the user ${JE_RG_USER_ID} into the course_id ${COURSE_ID} with role jefatura-estudios"
                moosh -n course-enrol -r jefatura-estudios -i "${COURSE_ID}" "${JE_RG_USER_ID}"
                ;;
            "44003235") # IES VEGA DEL TURIA
                echo "****** Enrolling the user ${JE_VT_USER_ID} into the course_id ${COURSE_ID} with role jefatura-estudios"
                moosh -n course-enrol -r jefatura-estudios -i "${COURSE_ID}" "${JE_VT_USER_ID}"
                ;;
            "50008460") # IES LUIS BUÑUEL
                echo "****** Enrolling the user ${JE_LB_USER_ID} into the course_id ${COURSE_ID} with role jefatura-estudios"
                moosh -n course-enrol -r jefatura-estudios -i "${COURSE_ID}" "${JE_LB_USER_ID}"
                ;;
            "22004611") # IES MARTÍNEZ VARGAS
                echo "****** Enrolling the user ${JE_MV_USER_ID} into the course_id ${COURSE_ID} with role jefatura-estudios"
                moosh -n course-enrol -r jefatura-estudios -i "${COURSE_ID}" "${JE_MV_USER_ID}"
                ;;
            "50009348") # IES AVEMPACE
                echo "****** Enrolling the user ${JE_AV_USER_ID} into the course_id ${COURSE_ID} with role jefatura-estudios"
                moosh -n course-enrol -r jefatura-estudios -i "${COURSE_ID}" "${JE_AV_USER_ID}"
                ;;
            "50008642") # IES MARÍA MOLINER
                echo "****** Enrolling the user ${JE_MM_USER_ID} into the course_id ${COURSE_ID} with role jefatura-estudios"
                moosh -n course-enrol -r jefatura-estudios -i "${COURSE_ID}" "${JE_MM_USER_ID}"
                ;;
            "44004550") # IES FERNANDO LÁZARO CARRETER
                echo "****** Enrolling the user ${JE_FLC_USER_ID} into the course_id ${COURSE_ID} with role jefatura-estudios"
                moosh -n course-enrol -r jefatura-estudios -i "${COURSE_ID}" "${JE_FLC_USER_ID}"
                ;;
            "50020125") # CFP CAMPUS DIGITAL
                echo "****** Enrolling the user ${JE_CD_USER_ID} into the course_id ${COURSE_ID} with role jefatura-estudios"
                moosh -n course-enrol -r jefatura-estudios -i "${COURSE_ID}" "${JE_CD_USER_ID}"
                ;;
        esac
    fi
done

echo >&2 "... importing categories and courses. Done!"
