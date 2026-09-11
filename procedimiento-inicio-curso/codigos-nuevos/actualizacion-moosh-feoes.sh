# Renombra el shortname de los cursos "-feoe" a su shortname definitivo.
#
# CORREGIDO: moosh course-config-set espera el ID NUMERICO del curso como
# argumento, no el shortname. El script original pasaba el shortname antiguo
# ("50020125-IFC201-feoe") en lugar del courseid, por lo que moosh devolvia
# "OK" pero no encontraba ningun curso que actualizar (no hacia nada).
#
# IDs obtenidos de: moosh -n course-list | grep feoe   (2026-09-11)
#
# NOTA: 44004550-IMA302-feoe no existe actualmente en Moodle (no aparece en
# course-list), asi que esa fila se ha omitido. Revisar aparte si ese curso
# deberia haberse creado ya.
#
# El curso id=19 (50020125-IFC201-feoe -> 50020125-IFC201-20295) ya se aplico
# manualmente el 2026-09-11 al diagnosticar el problema; se deja aqui para
# que el script sea idempotente si se vuelve a ejecutar entero.

moosh -n course-config-set course 19 shortname 50020125-IFC201-20295    # era 50020125-IFC201-feoe
moosh -n course-config-set course 40 shortname 50020125-IFC301-20306    # era 50020125-IFC301-feoe
moosh -n course-config-set course 61 shortname 50020125-IFC302-20307    # era 50020125-IFC302-feoe
moosh -n course-config-set course 81 shortname 50020125-IFC303-20308    # era 50020125-IFC303-feoe
moosh -n course-config-set course 115 shortname 44010537-IFC302-20307   # era 44010537-IFC302-feoe
moosh -n course-config-set course 135 shortname 50018829-ADG302-20300   # era 50018829-ADG302-feoe
moosh -n course-config-set course 156 shortname 50018829-ADG301-20299   # era 50018829-ADG301-feoe
moosh -n course-config-set course 175 shortname 50018829-QUI301-20311   # era 50018829-QUI301-feoe
moosh -n course-config-set course 195 shortname 50010314-COM201-20293   # era 50010314-COM201-feoe
moosh -n course-config-set course 216 shortname 50010314-COM301-20301   # era 50010314-COM301-feoe
moosh -n course-config-set course 237 shortname 50010314-COM302-20302   # era 50010314-COM302-feoe
moosh -n course-config-set course 257 shortname 50010314-COM303-20303   # era 50010314-COM303-feoe
moosh -n course-config-set course 276 shortname 50010314-IMS302-20310   # era 50010314-IMS302-feoe
moosh -n course-config-set course 294 shortname 50010314-IFC201-20295   # era 50010314-IFC201-feoe
moosh -n course-config-set course 314 shortname 50010314-IFC303-20308   # era 50010314-IFC303-feoe
moosh -n course-config-set course 333 shortname 22010712-ELE202-20294   # era 22010712-ELE202-feoe
moosh -n course-config-set course 354 shortname 44003028-SEA301-20312   # era 44003028-SEA301-feoe
moosh -n course-config-set course 374 shortname 50009348-SSC302-20313   # era 50009348-SSC302-feoe
moosh -n course-config-set course 394 shortname 50008460-SSC201-20298   # era 50008460-SSC201-feoe
moosh -n course-config-set course 415 shortname 50008642-SSC303-20314   # era 50008642-SSC303-feoe
moosh -n course-config-set course 435 shortname 22004611-SSC302-20313   # era 22004611-SSC302-feoe
moosh -n course-config-set course 455 shortname 50010156-HOT301-20305   # era 50010156-HOT301-feoe
moosh -n course-config-set course 476 shortname 50010144-IFC301-20306   # era 50010144-IFC301-feoe
moosh -n course-config-set course 495 shortname 50009567-SAN202-20296   # era 50009567-SAN202-feoe
moosh -n course-config-set course 515 shortname 50009567-SAN203-20297   # era 50009567-SAN203-feoe
moosh -n course-config-set course 536 shortname 50009567-ELE304-20304   # era 50009567-ELE304-feoe
moosh -n course-config-set course 555 shortname 44003211-ADG201-20292   # era 44003211-ADG201-feoe
moosh -n course-config-set course 574 shortname 22002521-ADG201-20292   # era 22002521-ADG201-feoe
moosh -n course-config-set course 592 shortname 50010511-ADG201-20292   # era 50010511-ADG201-feoe
moosh -n course-config-set course 612 shortname 44003235-SAN203-20297   # era 44003235-SAN203-feoe

# PENDIENTE (curso no encontrado en course-list, no se ha podido renombrar):
# 44004550-IMA302-feoe -> 44004550-IMA302-20309
