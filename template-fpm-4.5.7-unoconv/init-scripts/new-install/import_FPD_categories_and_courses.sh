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
##########################################

echo >&2 "Importing categories and courses..."

#############################################################################################
# Creo los usuarios, roles,... específicos de FPD:
#############################################################################################
echo "Creating users, roles,... of PFD"

# Create admin user for FPD

echo "Creating admin user for FP..."
FPD_ADMIN_USER_ID=$(moosh user-create --password "${FPD_PASSWORD}" --email "${FPD_EMAIL}" --digest 2 --city Aragón --country ES --firstname fp --lastname distancia admin2 | grep -o '[0-9]*' | tail -1)
moosh config-set siteadmins 2,"${FPD_ADMIN_USER_ID}"

# Crear rol y usuario de inspección
echo "Creating inspeccion role and configuring it..."
INSPECCION_ROLE_ID=$(moosh role-create -d "Los usuarios con rol de inspección tienen acceso a determinados informes" -a manager -n "Inspeccion" inspeccion | grep -o '[0-9]*' | tail -1)

# set permissions to inspeccion role
moosh role-import -f /init-scripts/themes/fpdist/roles/role-inspeccion.xml

# Creating user
INSPECCION_USER_ID=$(moosh user-create --password "${MANAGER_PASSWORD}" --email inspeccion@educa.aragon.es --digest 2 --city Aragón --country ES --firstname Inspección --lastname Inspección profinspector | grep -o '[0-9]*' | tail -1)

# Assiging user to r
moosh user-assign-system-role profinspector inspeccion

# Crear rol de jefaturas y usuarios
echo "Creating jefatura-estudios role and configuring it..."
JEFATURA_ROLE_ID=$(moosh role-create -d "Los usuarios con rol de inspección tienen acceso a determinados informes" -c system,category,course,block -n "Jefatura de estudios" jefatura-estudios | grep -o '[0-9]*' | tail -1)

# Setting permissions to jefatura de estudios role
moosh role-import -f /init-scripts/themes/fpdist/roles/role-jefatura-estudios.xml

# Creating users
JE_SG_USER_ID=$(moosh user-create --password "${MANAGER_PASSWORD}" --email jefaturas@educa.aragon.es --digest 2 --city Aragón --country ES --firstname "Jefatura de estudios" --lastname "IES Sierra de Guara" prof_je_sg | grep -o '[0-9]*' | tail -1)
JE_SE_USER_ID=$(moosh user-create --password "${MANAGER_PASSWORD}" --email jefaturas@educa.aragon.es --digest 2 --city Aragón --country ES --firstname "Jefatura de estudios" --lastname "IES SANTA EMERENCIANA" prof_je_se | grep -o '[0-9]*' | tail -1)
JE_TM_USER_ID=$(moosh user-create --password "${MANAGER_PASSWORD}" --email jefaturas@educa.aragon.es --digest 2 --city Aragón --country ES --firstname "Jefatura de estudios" --lastname "IES TIEMPOS MODERNOS" prof_je_tm | grep -o '[0-9]*' | tail -1)
JE_LE_USER_ID=$(moosh user-create --password "${MANAGER_PASSWORD}" --email jefaturas@educa.aragon.es --digest 2 --city Aragón --country ES --firstname "Jefatura de estudios" --lastname "CPIFP LOS ENLACES" prof_je_le | grep -o '[0-9]*' | tail -1)
JE_CA_USER_ID=$(moosh user-create --password "${MANAGER_PASSWORD}" --email jefaturas@educa.aragon.es --digest 2 --city Aragón --country ES --firstname "Jefatura de estudios" --lastname "CPIFP CORONA DE ARAGÓN" prof_je_ca | grep -o '[0-9]*' | tail -1)
JE_PI_USER_ID=$(moosh user-create --password "${MANAGER_PASSWORD}" --email jefaturas@educa.aragon.es --digest 2 --city Aragón --country ES --firstname "Jefatura de estudios" --lastname "CPIFP PIRÁMIDE" prof_je_pi | grep -o '[0-9]*' | tail -1)
JE_SB_USER_ID=$(moosh user-create --password "${MANAGER_PASSWORD}" --email jefaturas@educa.aragon.es --digest 2 --city Aragón --country ES --firstname "Jefatura de estudios" --lastname "CPIFP SAN BLAS" prof_je_sb | grep -o '[0-9]*' | tail -1)
JE_MI_USER_ID=$(moosh user-create --password "${MANAGER_PASSWORD}" --email jefaturas@educa.aragon.es --digest 2 --city Aragón --country ES --firstname "Jefatura de estudios" --lastname "IES MIRALBUENO" prof_je_mi | grep -o '[0-9]*' | tail -1)
JE_PS_USER_ID=$(moosh user-create --password "${MANAGER_PASSWORD}" --email jefaturas@educa.aragon.es --digest 2 --city Aragón --country ES --firstname "Jefatura de estudios" --lastname "IES PABLO SERRANO" prof_je_ps | grep -o '[0-9]*' | tail -1)
JE_BA_USER_ID=$(moosh user-create --password "${MANAGER_PASSWORD}" --email jefaturas@educa.aragon.es --digest 2 --city Aragón --country ES --firstname "Jefatura de estudios" --lastname "CPIFP BAJO ARAGÓN" prof_je_ba | grep -o '[0-9]*' | tail -1)
JE_RG_USER_ID=$(moosh user-create --password "${MANAGER_PASSWORD}" --email jefaturas@educa.aragon.es --digest 2 --city Aragón --country ES --firstname "Jefatura de estudios" --lastname "IES RÍO GÁLLEGO" prof_je_rg | grep -o '[0-9]*' | tail -1)
JE_VT_USER_ID=$(moosh user-create --password "${MANAGER_PASSWORD}" --email jefaturas@educa.aragon.es --digest 2 --city Aragón --country ES --firstname "Jefatura de estudios" --lastname "IES VEGA DEL TURIA" prof_je_vt | grep -o '[0-9]*' | tail -1)
JE_LB_USER_ID=$(moosh user-create --password "${MANAGER_PASSWORD}" --email jefaturas@educa.aragon.es --digest 2 --city Aragón --country ES --firstname "Jefatura de estudios" --lastname "IES LUIS BUÑUEL" prof_je_lb | grep -o '[0-9]*' | tail -1)
JE_MO_USER_ID=$(moosh user-create --password "${MANAGER_PASSWORD}" --email jefaturas@educa.aragon.es --digest 2 --city Aragón --country ES --firstname "Jefatura de estudios" --lastname "CPIFP MONTEARAGON" prof_je_mo | grep -o '[0-9]*' | tail -1)
JE_MV_USER_ID=$(moosh user-create --password "${MANAGER_PASSWORD}" --email jefaturas@educa.aragon.es --digest 2 --city Aragón --country ES --firstname "Jefatura de estudios" --lastname "IES MARTÍNEZ VARGAS" prof_je_mv | grep -o '[0-9]*' | tail -1)
JE_AV_USER_ID=$(moosh user-create --password "${MANAGER_PASSWORD}" --email jefaturas@educa.aragon.es --digest 2 --city Aragón --country ES --firstname "Jefatura de estudios" --lastname "IES AVEMPACE" prof_je_av | grep -o '[0-9]*' | tail -1)
JE_MM_USER_ID=$(moosh user-create --password "${MANAGER_PASSWORD}" --email jefaturas@educa.aragon.es --digest 2 --city Aragón --country ES --firstname "Jefatura de estudios" --lastname "IES MARÍA MOLINER" prof_je_mm | grep -o '[0-9]*' | tail -1)

ADMIN2=$(moosh user-create --password "${MANAGER_PASSWORD}" --email fpdistancia@aragon.es --digest 2 --city Aragón --country ES --firstname "Administrador" --lastname "Campus Digital FP - Virtual" admin2 | grep -o '[0-9]*' | tail -1)
ADMIN3=$(moosh user-create --password "${MANAGER_PASSWORD}" --email amcandialq@campusdigitalfp.com --digest 2 --city Aragón --country ES --firstname "Administrador" --lastname "Ana María Candial" admin3 | grep -o '[0-9]*' | tail -1)
ADMIN4=$(moosh user-create --password "${MANAGER_PASSWORD}" --email jefaturas@educa.aragon.es --digest 2 --city Aragón --country ES --firstname "Administrador" --lastname "Darío Axel Ureña" admin4 | grep -o '[0-9]*' | tail -1)
ADMIN5=$(moosh user-create --password "${MANAGER_PASSWORD}" --email jefaturas@educa.aragon.es --digest 2 --city Aragón --country ES --firstname "Administrador" --lastname "Prácticas" admin5 | grep -o '[0-9]*' | tail -1)

#############################################################################################
# Creo las categorías:
#############################################################################################
echo "Creating structure for categories..."

ID_CATEGORY_miscelanea=1
ID_CATEGORY_general=$(moosh category-create -p 0 -v 1 -d "general" "General" | grep -o '[0-9]*' | tail -1)
ID_CATEGORY_app=$(moosh category-create -p 0 -v 1 -d "app" "NO BORRAR - APP MOVIL" | grep -o '[0-9]*' | tail -1)

ID_CATEGORY_sg=$(moosh category-create -p 0 -v 1 -d "22002521" "IES SIERRA DE GUARA" | grep -o '[0-9]*' | tail -1)
ID_CATEGORY_sg_ga=$(moosh category-create -p "${ID_CATEGORY_sg}" -v 1 -d "ADG201" "Gestión Administrativa" | grep -o '[0-9]*' | tail -1)

ID_CATEGORY_se=$(moosh category-create -p 0 -v 1 -d "44003211" "IES SANTA EMERENCIANA" | grep -o '[0-9]*' | tail -1)
ID_CATEGORY_se_ga=$(moosh category-create -p "${ID_CATEGORY_se}" -v 1 -d "ADG201" "Gestión Administrativa" | grep -o '[0-9]*' | tail -1)

ID_CATEGORY_tm=$(moosh category-create -p 0 -v 1 -d "50010511" "IES TIEMPOS MODERNOS" | grep -o '[0-9]*' | tail -1)
ID_CATEGORY_tm_ga=$(moosh category-create -p "${ID_CATEGORY_tm}" -v 1 -d "ADG201" "Gestión Administrativa" | grep -o '[0-9]*' | tail -1)

ID_CATEGORY_se_ga=$(moosh category-create -p "${ID_CATEGORY_se}" -v 1 -d "ADG201" "Gestión Administrativa" | grep -o '[0-9]*' | tail -1)

ID_CATEGORY_le=$(moosh category-create -p 0 -v 1 -d "50010314" "CPIFP LOS ENLACES" | grep -o '[0-9]*' | tail -1)
ID_CATEGORY_le_smr=$(moosh category-create -p "${ID_CATEGORY_le}" -v 1 -d "IFC201" "Sistemas Microinformáticos y Redes" | grep -o '[0-9]*' | tail -1)
ID_CATEGORY_le_ac=$(moosh category-create -p "${ID_CATEGORY_le}" -v 1 -d "COM201" "Actividades Comerciales" | grep -o '[0-9]*' | tail -1)
ID_CATEGORY_le_ci=$(moosh category-create -p "${ID_CATEGORY_le}" -v 1 -d "COM301" "Comercio Internacional" | grep -o '[0-9]*' | tail -1)
ID_CATEGORY_le_gvec=$(moosh category-create -p "${ID_CATEGORY_le}" -v 1 -d "COM302" "Gestión de Ventas y Espacios Comerciales" | grep -o '[0-9]*' | tail -1)
ID_CATEGORY_le_tl=$(moosh category-create -p "${ID_CATEGORY_le}" -v 1 -d "COM303" "Transporte y Logística" | grep -o '[0-9]*' | tail -1)
ID_CATEGORY_le_daw=$(moosh category-create -p "${ID_CATEGORY_le}" -v 1 -d "IFC303" "Desarrollo de Aplicaciones WEB" | grep -o '[0-9]*' | tail -1)
ID_CATEGORY_le_pae=$(moosh category-create -p "${ID_CATEGORY_le}" -v 1 -d "IMS302" "Producción de Audiovisuales y Espectáculos" | grep -o '[0-9]*' | tail -1)

ID_CATEGORY_ca=$(moosh category-create -p 0 -v 1 -d "50018829" "CPIFP CORONA DE ARAGÓN" | grep -o '[0-9]*' | tail -1)
ID_CATEGORY_ca_ad=$(moosh category-create -p "${ID_CATEGORY_ca}" -v 1 -d "ADG302" "Asistencia a la Dirección" | grep -o '[0-9]*' | tail -1)
ID_CATEGORY_ca_af=$(moosh category-create -p "${ID_CATEGORY_ca}" -v 1 -d "ADG301" "Administración y Finanzas" | grep -o '[0-9]*' | tail -1)
ID_CATEGORY_ca_lacc=$(moosh category-create -p "${ID_CATEGORY_ca}" -v 1 -d "QUI301" "Laboratorio de Análisis y de Control de Calidad" | grep -o '[0-9]*' | tail -1)

ID_CATEGORY_pi=$(moosh category-create -p 0 -v 1 -d "22010712" "CPIFP PIRÁMIDE" | grep -o '[0-9]*' | tail -1)
ID_CATEGORY_pi_iea=$(moosh category-create -p "${ID_CATEGORY_pi}" -v 1 -d "ELE202" "Instalaciones Eléctricas y Automáticas" | grep -o '[0-9]*' | tail -1)

ID_CATEGORY_sb=$(moosh category-create -p 0 -v 1 -d "44003028" "CPIFP SAN BLAS" | grep -o '[0-9]*' | tail -1)
ID_CATEGORY_sb_eca=$(moosh category-create -p "${ID_CATEGORY_sb}" -v 1 -d "SEA301" "Educación y Control Ambiental" | grep -o '[0-9]*' | tail -1)

ID_CATEGORY_mi=$(moosh category-create -p 0 -v 1 -d "50010156" "IES MIRALBUENO" | grep -o '[0-9]*' | tail -1)
ID_CATEGORY_mi_avge=$(moosh category-create -p "${ID_CATEGORY_mi}" -v 1 -d "HOT301" "Agencias de Viajes y Gestión de Eventos" | grep -o '[0-9]*' | tail -1)

ID_CATEGORY_ps=$(moosh category-create -p 0 -v 1 -d "50010144" "IES PABLO SERRANO" | grep -o '[0-9]*' | tail -1)
ID_CATEGORY_ps_asir=$(moosh category-create -p "${ID_CATEGORY_ps}" -v 1 -d "IFC301" "Administración de Sistemas Informáticos en Red" | grep -o '[0-9]*' | tail -1)

ID_CATEGORY_ba=$(moosh category-create -p 0 -v 1 -d "44010537" "CPIFP BAJO ARAGÓN" | grep -o '[0-9]*' | tail -1)
ID_CATEGORY_ba_dam=$(moosh category-create -p "${ID_CATEGORY_ba}" -v 1 -d "IFC301" "Desarrollo de Aplicaciones Multiplataforma" | grep -o '[0-9]*' | tail -1)

ID_CATEGORY_rg=$(moosh category-create -p 0 -v 1 -d "50009567" "IES RÍO GÁLLEGO" | grep -o '[0-9]*' | tail -1)
ID_CATEGORY_rg_sti=$(moosh category-create -p "${ID_CATEGORY_rg}" -v 1 -d "ELE304" "Sistemas de Telecomunicaciones e Informáticos" | grep -o '[0-9]*' | tail -1)
ID_CATEGORY_rg_fp=$(moosh category-create -p "${ID_CATEGORY_rg}" -v 1 -d "SAN202" "Farmacia y Parafarmacia" | grep -o '[0-9]*' | tail -1)
ID_CATEGORY_rg_es=$(moosh category-create -p "${ID_CATEGORY_rg}" -v 1 -d "SAN203" "Emergencias Sanitarias" | grep -o '[0-9]*' | tail -1)

ID_CATEGORY_vt=$(moosh category-create -p 0 -v 1 -d "44003235" "IES VEGA DEL TURIA" | grep -o '[0-9]*' | tail -1)
ID_CATEGORY_vt_es=$(moosh category-create -p "${ID_CATEGORY_vt}" -v 1 -d "SAN203" "Emergencias Sanitarias" | grep -o '[0-9]*' | tail -1)

ID_CATEGORY_lb=$(moosh category-create -p 0 -v 1 -d "50008460" "IES LUIS BUÑUEL" | grep -o '[0-9]*' | tail -1)
ID_CATEGORY_lb_apsd=$(moosh category-create -p "${ID_CATEGORY_lb}" -v 1 -d "SSC201" "Atención a Personas en situación de Dependencia" | grep -o '[0-9]*' | tail -1)

ID_CATEGORY_mo=$(moosh category-create -p 0 -v 1 -d "22002491" "CPIFP MONTEARAGON" | grep -o '[0-9]*' | tail -1)
ID_CATEGORY_mo_apsd=$(moosh category-create -p "${ID_CATEGORY_mo}" -v 1 -d "SSC201" "Atención a Personas en situación de Dependencia" | grep -o '[0-9]*' | tail -1)

ID_CATEGORY_mv=$(moosh category-create -p 0 -v 1 -d "22004611" "IES MARTÍNEZ VARGAS" | grep -o '[0-9]*' | tail -1)
ID_CATEGORY_mv_ei=$(moosh category-create -p "${ID_CATEGORY_mv}" -v 1 -d "SSC302" "Educación Infantil (Formación Profesional)" | grep -o '[0-9]*' | tail -1)

ID_CATEGORY_av=$(moosh category-create -p 0 -v 1 -d "50009348" "IES AVEMPACE" | grep -o '[0-9]*' | tail -1)
ID_CATEGORY_av_ei=$(moosh category-create -p "${ID_CATEGORY_av}" -v 1 -d "SSC302" "Educación Infantil (Formación Profesional)" | grep -o '[0-9]*' | tail -1)

ID_CATEGORY_mm=$(moosh category-create -p 0 -v 1 -d "50008642" "IES MARÍA MOLINER" | grep -o '[0-9]*' | tail -1)
ID_CATEGORY_mm_is=$(moosh category-create -p "${ID_CATEGORY_mm}" -v 1 -d "SSC303" "Integración Social" | grep -o '[0-9]*' | tail -1)

ID_CATEGORY_cd=$(moosh category-create -p 0 -v 1 -d "50020125" "Campus Digital FP" | grep -o '[0-9]*' | tail -1)
ID_CATEGORY_cd_smr=$(moosh category-create -p "${ID_CATEGORY_cd}" -v 1 -d "IFC201" "Sistemas Microinformáticos y Redes" | grep -o '[0-9]*' | tail -1)
ID_CATEGORY_cd_asir=$(moosh category-create -p "${ID_CATEGORY_cd}" -v 1 -d "IFC301" "Administración de Sistemas Informáticos en Red" | grep -o '[0-9]*' | tail -1)
ID_CATEGORY_cd_dam=$(moosh category-create -p "${ID_CATEGORY_cd}" -v 1 -d "IFC302" "Desarrollo de Aplicaciones Multiplataforma" | grep -o '[0-9]*' | tail -1)
ID_CATEGORY_cd_daw=$(moosh category-create -p "${ID_CATEGORY_cd}" -v 1 -d "IFC303" "Desarrollo de Aplicaciones WEB" | grep -o '[0-9]*' | tail -1)
ID_CATEGORY_cd_iabd=$(moosh category-create -p "${ID_CATEGORY_cd}" -v 1 -d "CESIFC02" "Inteligencia Artificial y Big Data" | grep -o '[0-9]*' | tail -1)
ID_CATEGORY_cd_ceti=$(moosh category-create -p "${ID_CATEGORY_cd}" -v 1 -d "CESIFC01" "Ciberseguridad en Entornos de las Tecnologías de la Información" | grep -o '[0-9]*' | tail -1)




#############################################################################################
# A los usuarios jefes de estudios les cambio su campo personalizado para que tengan el valor correspondiente a su categoría
#############################################################################################

# Añadir el campo personalizado a los usuarios y asignar a cada jefe de estudios el suyo 
echo "Creating custom fields for jefatura estudios..."
# # Creo el campo personalizado
moosh userprofilefields-import /init-scripts/themes/fpdist/custom-fields/user_profile_fields.csv

# # Asignar a cada usuario el valor que le corresponde en el campo personalizado
moosh sql-run "INSERT INTO mdl_user_info_data (userid, fieldid, data, dataformat) values ($JE_SG_USER_ID, 1, $ID_CATEGORY_sg, 0)"
moosh sql-run "INSERT INTO mdl_user_info_data (userid, fieldid, data, dataformat) values ($JE_SE_USER_ID, 1, $ID_CATEGORY_se, 0)"
moosh sql-run "INSERT INTO mdl_user_info_data (userid, fieldid, data, dataformat) values ($JE_TM_USER_ID, 1, $ID_CATEGORY_tm, 0)"
moosh sql-run "INSERT INTO mdl_user_info_data (userid, fieldid, data, dataformat) values ($JE_LE_USER_ID, 1, $ID_CATEGORY_le, 0)"
moosh sql-run "INSERT INTO mdl_user_info_data (userid, fieldid, data, dataformat) values ($JE_CA_USER_ID, 1, $ID_CATEGORY_ca, 0)"
moosh sql-run "INSERT INTO mdl_user_info_data (userid, fieldid, data, dataformat) values ($JE_PI_USER_ID, 1, $ID_CATEGORY_pi, 0)"
moosh sql-run "INSERT INTO mdl_user_info_data (userid, fieldid, data, dataformat) values ($JE_SB_USER_ID, 1, $ID_CATEGORY_sb, 0)"
moosh sql-run "INSERT INTO mdl_user_info_data (userid, fieldid, data, dataformat) values ($JE_MI_USER_ID, 1, $ID_CATEGORY_mi, 0)"
moosh sql-run "INSERT INTO mdl_user_info_data (userid, fieldid, data, dataformat) values ($JE_PS_USER_ID, 1, $ID_CATEGORY_ps, 0)"
moosh sql-run "INSERT INTO mdl_user_info_data (userid, fieldid, data, dataformat) values ($JE_BA_USER_ID, 1, $ID_CATEGORY_ba, 0)"
moosh sql-run "INSERT INTO mdl_user_info_data (userid, fieldid, data, dataformat) values ($JE_RG_USER_ID, 1, $ID_CATEGORY_rg, 0)"
moosh sql-run "INSERT INTO mdl_user_info_data (userid, fieldid, data, dataformat) values ($JE_VT_USER_ID, 1, $ID_CATEGORY_vt, 0)"
moosh sql-run "INSERT INTO mdl_user_info_data (userid, fieldid, data, dataformat) values ($JE_LB_USER_ID, 1, $ID_CATEGORY_lb, 0)"
moosh sql-run "INSERT INTO mdl_user_info_data (userid, fieldid, data, dataformat) values ($JE_MO_USER_ID, 1, $ID_CATEGORY_mo, 0)"
moosh sql-run "INSERT INTO mdl_user_info_data (userid, fieldid, data, dataformat) values ($JE_MV_USER_ID, 1, $ID_CATEGORY_mv, 0)"
moosh sql-run "INSERT INTO mdl_user_info_data (userid, fieldid, data, dataformat) values ($JE_AV_USER_ID, 1, $ID_CATEGORY_av, 0)"
moosh sql-run "INSERT INTO mdl_user_info_data (userid, fieldid, data, dataformat) values ($JE_MM_USER_ID, 1, $ID_CATEGORY_mm, 0)"


#############################################################################################
# Creo las cohortes
#############################################################################################
echo "Creating cohorts..."

moosh cohort-create -d "alumnado" -i alumnado -c "${ID_CATEGORY_general}" "alumnado"
moosh cohort-create -d "profesorado" -i profesorado -c "${ID_CATEGORY_general}" "profesorado"
moosh cohort-create -d "coordinacion" -i coordinacion -c "${ID_CATEGORY_general}" "coordinacion"
moosh cohort-create -d "jefaturas" -i jefaturas -c "${ID_CATEGORY_general}" "jefaturas"

moosh cohort-create -d "22002491-SSC201" -i 22002491-SSC201 -c "${ID_CATEGORY_mo}" "22002491-SSC201"
moosh cohort-create -d "22002521-ADG201" -i 22002521-ADG201 -c "${ID_CATEGORY_sg}" "22002521-ADG201"
moosh cohort-create -d "22004611-SSC302" -i 22004611-SSC302 -c "${ID_CATEGORY_mv}" "22004611-SSC302"
moosh cohort-create -d "22010712-ELE202" -i 22010712-ELE202 -c "${ID_CATEGORY_pi}" "22010712-ELE202"
moosh cohort-create -d "44003028-SEA301" -i 44003028-SEA301 -c "${ID_CATEGORY_sb}" "44003028-SEA301"
moosh cohort-create -d "44003211-ADG201" -i 44003211-ADG201 -c "${ID_CATEGORY_se}" "44003211-ADG201"
moosh cohort-create -d "44003235-SAN203" -i 44003235-SAN203 -c "${ID_CATEGORY_vt}" "44003235-SAN203"
moosh cohort-create -d "44010537-IFC302" -i 44010537-IFC302 -c "${ID_CATEGORY_ba}" "44010537-IFC302"
moosh cohort-create -d "50008460-SSC201" -i 50008460-SSC201 -c "${ID_CATEGORY_lb}" "50008460-SSC201"
moosh cohort-create -d "50008642-SSC303" -i 50008642-SSC303 -c "${ID_CATEGORY_mm}" "50008642-SSC303"
moosh cohort-create -d "50009348-SSC302" -i 50009348-SSC302 -c "${ID_CATEGORY_av}" "50009348-SSC302"
moosh cohort-create -d "50009567-ELE304" -i 50009567-ELE304 -c "${ID_CATEGORY_rg}" "50009567-ELE304"
moosh cohort-create -d "50009567-SAN202" -i 50009567-SAN202 -c "${ID_CATEGORY_rg}" "50009567-SAN202"
moosh cohort-create -d "50009567-SAN203" -i 50009567-SAN203 -c "${ID_CATEGORY_rg}" "50009567-SAN203"
moosh cohort-create -d "50010144-IFC301" -i 50010144-IFC301 -c "${ID_CATEGORY_ps}" "50010144-IFC301"
moosh cohort-create -d "50010156-HOT301" -i 50010156-HOT301 -c "${ID_CATEGORY_mi}" "50010156-HOT301"
moosh cohort-create -d "50010314-COM201" -i 50010314-COM201 -c "${ID_CATEGORY_le}" "50010314-COM201"
moosh cohort-create -d "50010314-COM301" -i 50010314-COM301 -c "${ID_CATEGORY_le}" "50010314-COM301"
moosh cohort-create -d "50010314-COM302" -i 50010314-COM302 -c "${ID_CATEGORY_le}" "50010314-COM302"
moosh cohort-create -d "50010314-COM303" -i 50010314-COM303 -c "${ID_CATEGORY_le}" "50010314-COM303"
moosh cohort-create -d "50010314-IFC201" -i 50010314-IFC201 -c "${ID_CATEGORY_le}" "50010314-IFC201"
moosh cohort-create -d "50010314-IFC303" -i 50010314-IFC303 -c "${ID_CATEGORY_le}" "50010314-IFC303"
moosh cohort-create -d "50010314-IMS302" -i 50010314-IMS302 -c "${ID_CATEGORY_le}" "50010314-IMS302"
moosh cohort-create -d "50010511-ADG201" -i 50010511-ADG201 -c "${ID_CATEGORY_tm}" "50010511-ADG201"
moosh cohort-create -d "50018829-ADG301" -i 50018829-ADG301 -c "${ID_CATEGORY_ca}" "50018829-ADG301"
moosh cohort-create -d "50018829-ADG302" -i 50018829-ADG302 -c "${ID_CATEGORY_ca}" "50018829-ADG302"
moosh cohort-create -d "50018829-QUI301" -i 50018829-QUI301 -c "${ID_CATEGORY_ca}" "50018829-QUI301"

#############################################################################################
# Añado a la cohorte de jefatura de estudios a los diferentes usuarios de jefes de estudios
#############################################################################################
echo "Adding jefatura users to cohort jefaturas..."

moosh cohort-enrol -u "${JE_SG_USER_ID}" "jefaturas"
moosh cohort-enrol -u "${JE_SE_USER_ID}" "jefaturas"
moosh cohort-enrol -u "${JE_TM_USER_ID}" "jefaturas"
moosh cohort-enrol -u "${JE_LE_USER_ID}" "jefaturas"
moosh cohort-enrol -u "${JE_CA_USER_ID}" "jefaturas"
moosh cohort-enrol -u "${JE_PI_USER_ID}" "jefaturas"
moosh cohort-enrol -u "${JE_SB_USER_ID}" "jefaturas"
moosh cohort-enrol -u "${JE_MI_USER_ID}" "jefaturas"
moosh cohort-enrol -u "${JE_PS_USER_ID}" "jefaturas"
moosh cohort-enrol -u "${JE_BA_USER_ID}" "jefaturas"
moosh cohort-enrol -u "${JE_RG_USER_ID}" "jefaturas"
moosh cohort-enrol -u "${JE_VT_USER_ID}" "jefaturas"
moosh cohort-enrol -u "${JE_LB_USER_ID}" "jefaturas"
moosh cohort-enrol -u "${JE_MO_USER_ID}" "jefaturas"
moosh cohort-enrol -u "${JE_MV_USER_ID}" "jefaturas"
moosh cohort-enrol -u "${JE_AV_USER_ID}" "jefaturas"
moosh cohort-enrol -u "${JE_MM_USER_ID}" "jefaturas"


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
    COURSE_ID=""
    
    if [ ! -f "/var/www/moodledata/repository/mbzs_curso_anterior/${SHORTNAME}.mbz" ]; then
        # Si no existe el curso, lo creo
        echo "***** The course /var/www/moodledata/repository/mbzs_curso_anterior/${SHORTNAME}.mbz doesn't exist, creating empty course ${COURSE} into category ${CATEGORY}"
        COURSE_ID=$(moosh course-create --category "${!CATEGORY}" --fullname "${FULLNAME}" --description "${FULLNAME}" "${SHORTNAME}" | grep -o '[0-9]*' | tail -1)
        moosh course-config-set course "${COURSE_ID}" fullname "${FULLNAME}"
    else
        # Si existe el curso lo restauro
        echo "***** Restoring /var/www/moodledata/repository/mbzs_curso_anterior/${SHORTNAME}.mbz course to category ${CATEGORY}"
        RESTORE_OUTPUT=$(moosh course-restore /var/www/moodledata/repository/mbzs_curso_anterior/${SHORTNAME}.mbz "${!CATEGORY}")
        COURSE_ID=$(echo "${RESTORE_OUTPUT}" | grep "^Restoring" | sed 's/.*): //' | cut -d',' -f1)
        # Configuro full y short names por si al restaurar había datos erróneos en origen
        moosh course-config-set course "${COURSE_ID}" shortname "${SHORTNAME}"
        moosh course-config-set course "${COURSE_ID}" fullname "${FULLNAME}"
    fi
    moosh course-config-set course "${COURSE_ID}" visible "${VISIBLE}"
    # TODO: valorar si los que no son visible los borro una vez creados <- verificar no afecta a los IDs

    # matriculo en el curso de ayuda a las cohortes alumnado, profesorado, coordinacion y jefaturas
    if [[ ${SHORTNAME} == 'ayuda' ]]; 
    then
        COHORT=$(echo "${SHORTNAME}" | cut -d '-' -f 1,2)
        echo "****** Enrolling the cohorts alumnado, profesorado, coordinacion and jefaturas into the course_id ${COURSE_ID}"
        moosh cohort-enrol -c "${COURSE_ID}" "alumnado"
        moosh cohort-enrol -c "${COURSE_ID}" "profesorado"
        moosh cohort-enrol -c "${COURSE_ID}" "coordinacion"
        moosh cohort-enrol -c "${COURSE_ID}" "jefaturas"
    fi

    # matriculo en el curso de profesorado a las cohortes profesorado, coordinacion y jefaturas
    if [[ ${SHORTNAME} == 'profesorado' ]]; 
    then
        COHORT=$(echo "${SHORTNAME}" | cut -d '-' -f 1,2)
        echo "****** Enrolling the cohorts profesorado, coordinacion and jefaturas into the course_id ${COURSE_ID}"
        moosh cohort-enrol -c "${COURSE_ID}" "profesorado"
        moosh cohort-enrol -c "${COURSE_ID}" "coordinacion"
        moosh cohort-enrol -c "${COURSE_ID}" "jefaturas"
    fi

    # matriculo en el curso de coordinacion a las cohortes coordinacion y jefaturas
    if [[ ${SHORTNAME} == 'coordinacion' ]]; 
    then
        COHORT=$(echo "${SHORTNAME}" | cut -d '-' -f 1,2)
        echo "****** Enrolling the cohorts coordinacion and jefaturas into the course_id ${COURSE_ID}"
        moosh cohort-enrol -c "${COURSE_ID}" "coordinacion"
        moosh cohort-enrol -c "${COURSE_ID}" "jefaturas"
    fi

    # matriculo en el curso de marketplaces a los usuarios que nos piden desde la app
    if [[ ${SHORTNAME} == 'marketplaces' ]]; 
    then
        COHORT=$(echo "${SHORTNAME}" | cut -d '-' -f 1,2)
        echo "****** Creating and enrolling the users for marketplaces into the course_id ${COURSE_ID}"
        FPD_APP_USER_STUDENT_ID=$(moosh user-create --password "${APP_PASSWORD}" --email alumnado@education.catedu.es --digest 2 --city Aragón --country ES --firstname student --lastname demoapp demoapp | grep -o '[0-9]*' | tail -1)
        FPD_APP_USER_TEACHER_ID=$(moosh user-create --password "${APP_TEACHER_PASSWORD}" --email alumnado@education.catedu.es --digest 2 --city Aragón --country ES --firstname teacher --lastname demoapp profesor1 | grep -o '[0-9]*' | tail -1)

        moosh course-enrol -r editingteacher -i "${COURSE_ID}" "${FPD_APP_USER_TEACHER_ID}"
        moosh course-enrol -r student -i "${COURSE_ID}" "${FPD_APP_USER_STUDENT_ID}"
    fi

    # si el cod_ensenanza contiene una t al final (es una tutoría) entonces matriculo a la cohorte en ese curso
    if [[ ${SHORTNAME} == *t ]]; 
    then
        COHORT=$(echo "${SHORTNAME}" | cut -d '-' -f 1,2)
        echo "****** Enrolling the cohort ${COHORT} into the course_id ${COURSE_ID}"
        moosh cohort-enrol -c "${COURSE_ID}" "${COHORT}"
    fi

    # Matricular a jefes de estudios en los cursos en base al ID centro del shortname
    if [[ ${SHORTNAME} == *-*-* ]];
    then
        CODCENTRO=$(echo "${SHORTNAME}" | cut -d '-' -f 1)
        case "${CODCENTRO}" in
            "22002521") # IES Sierra de Guara
                echo "****** Enrolling the user ${JE_SG_USER_ID} into the course_id ${COURSE_ID} with role jefatura-estudios"
                moosh course-enrol -r jefatura-estudios -i "${COURSE_ID}" "${JE_SG_USER_ID}"
                ;;
            "44003211") # IES SANTA EMERENCIANA
                echo "****** Enrolling the user ${JE_SE_USER_ID} into the course_id ${COURSE_ID} with role jefatura-estudios"
                moosh course-enrol -r jefatura-estudios -i "${COURSE_ID}" "${JE_SE_USER_ID}"
                ;;
            "50010511") # IES TIEMPOS MODERNOS
                echo "****** Enrolling the user ${JE_TM_USER_ID} into the course_id ${COURSE_ID} with role jefatura-estudios"
                moosh course-enrol -r jefatura-estudios -i "${COURSE_ID}" "${JE_TM_USER_ID}"
                ;;
            "50010314") # CPIFP LOS ENLACES
                echo "****** Enrolling the user ${JE_LE_USER_ID} into the course_id ${COURSE_ID} with role jefatura-estudios"
                moosh course-enrol -r jefatura-estudios -i "${COURSE_ID}" "${JE_LE_USER_ID}"
                ;;
            "50018829") # CPIFP CORONA DE ARAGÓN
                echo "****** Enrolling the user ${JE_CA_USER_ID} into the course_id ${COURSE_ID} with role jefatura-estudios"
                moosh course-enrol -r jefatura-estudios -i "${COURSE_ID}" "${JE_CA_USER_ID}"
                ;;
            "22010712") # CPIFP PIRÁMIDE
                echo "****** Enrolling the user ${JE_PI_USER_ID} into the course_id ${COURSE_ID} with role jefatura-estudios"
                moosh course-enrol -r jefatura-estudios -i "${COURSE_ID}" "${JE_PI_USER_ID}"
                ;;
            "44003028") # CPIFP SAN BLAS
                echo "****** Enrolling the user ${JE_SB_USER_ID} into the course_id ${COURSE_ID} with role jefatura-estudios"
                moosh course-enrol -r jefatura-estudios -i "${COURSE_ID}" "${JE_SB_USER_ID}"
                ;;
            "50010156") # IES MIRALBUENO
                echo "****** Enrolling the user ${JE_MI_USER_ID} into the course_id ${COURSE_ID} with role jefatura-estudios"
                moosh course-enrol -r jefatura-estudios -i "${COURSE_ID}" "${JE_MI_USER_ID}"
                ;;
            "50010144") # IES PABLO SERRANO
                echo "****** Enrolling the user ${JE_PS_USER_ID} into the course_id ${COURSE_ID} with role jefatura-estudios"
                moosh course-enrol -r jefatura-estudios -i "${COURSE_ID}" "${JE_PS_USER_ID}"
                ;;
            "44010537") # CPIFP BAJO ARAGÓN
                echo "****** Enrolling the user ${JE_BA_USER_ID} into the course_id ${COURSE_ID} with role jefatura-estudios"
                moosh course-enrol -r jefatura-estudios -i "${COURSE_ID}" "${JE_BA_USER_ID}"
                ;;
            "50009567") # IES RÍO GÁLLEGO
                echo "****** Enrolling the user ${JE_RG_USER_ID} into the course_id ${COURSE_ID} with role jefatura-estudios"
                moosh course-enrol -r jefatura-estudios -i "${COURSE_ID}" "${JE_RG_USER_ID}"
                ;;
            "44003235") # IES VEGA DEL TURIA
                echo "****** Enrolling the user ${JE_VT_USER_ID} into the course_id ${COURSE_ID} with role jefatura-estudios"
                moosh course-enrol -r jefatura-estudios -i "${COURSE_ID}" "${JE_VT_USER_ID}"
                ;;
            "50008460") # IES LUIS BUÑUEL
                echo "****** Enrolling the user ${JE_LB_USER_ID} into the course_id ${COURSE_ID} with role jefatura-estudios"
                moosh course-enrol -r jefatura-estudios -i "${COURSE_ID}" "${JE_LB_USER_ID}"
                ;;
            "22002491") # CPIFP MONTEARAGON
                echo "****** Enrolling the user ${JE_MO_USER_ID} into the course_id ${COURSE_ID} with role jefatura-estudios"
                moosh course-enrol -r jefatura-estudios -i "${COURSE_ID}" "${JE_MO_USER_ID}"
                ;;
            "22004611") # IES MARTÍNEZ VARGAS
                echo "****** Enrolling the user ${JE_MV_USER_ID} into the course_id ${COURSE_ID} with role jefatura-estudios"
                moosh course-enrol -r jefatura-estudios -i "${COURSE_ID}" "${JE_MV_USER_ID}"
                ;;
            "50009348") # IES AVEMPACE
                echo "****** Enrolling the user ${JE_AV_USER_ID} into the course_id ${COURSE_ID} with role jefatura-estudios"
                moosh course-enrol -r jefatura-estudios -i "${COURSE_ID}" "${JE_AV_USER_ID}"
                ;;
            "50008642") # IES MARÍA MOLINER
                echo "****** Enrolling the user ${JE_MM_USER_ID} into the course_id ${COURSE_ID} with role jefatura-estudios"
                moosh course-enrol -r jefatura-estudios -i "${COURSE_ID}" "${JE_MM_USER_ID}"
                ;;
        esac
    fi
done

echo >&2 "... importing categories and courses. Done!"