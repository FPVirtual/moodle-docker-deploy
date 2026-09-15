# Corrige shortnames de cursos en wwwfpvirtualaragones-moodle-1 cuyo
# id_modulo no coincide con el IDMATERIA correcto del catalogo LFP 2026
# (columna IDMATERIA de 20260722_MateriasFPDistancia2026_LFP.xlsx), que es
# el mismo codigo que ya tiene cargado fp-app en la tabla ciclo_modulo.
#
# Los cursos con id_modulo terminado en "t" (Coordinacion-Tutoria) y los
# cursos residuales del plan LOE (Formacion en centros de trabajo LOE,
# Proyecto ... LOE) se han dejado fuera porque no tienen equivalente en el
# xlsx: no son un codigo incorrecto, son cursos que no existen en el
# catalogo 2026.
#
# El curso 524 (50009567-ELE304-13941, "Proyecto de sistemas de
# telecomunicaciones e informaticos LOE") tampoco se incluye: el shortname
# correcto 50009567-ELE304-15778 ya lo tiene el curso 518 (el curso LFP
# equivalente ya existe por separado), renombrar el 524 provocaria colision.
#
# Generado el 2026-09-15 comparando:
#   - fp-app: tablas centro_ciclo / ciclo_modulo / modulos
#   - xlsx:   20260722_MateriasFPDistancia2026_LFP.xlsx (columna IDMATERIA)
#   - moodle: moosh -n course-list en wwwfpvirtualaragones-moodle-1

moosh -n course-config-set course 93  shortname 50020125-CESIFC02-19128  # era 50020125-CESIFC02-14346   (IABD - Sistemas de Big Data)
moosh -n course-config-set course 209 shortname 50010314-COM301-15407    # era 50010314-COM301-115377    (CI - Sostenibilidad aplicada al sistema productivo)
moosh -n course-config-set course 222 shortname 50010314-COM302-15426    # era 50010314-COM302-1116466   (GVEC - Gestion de productos y promociones en el punto de venta)
moosh -n course-config-set course 228 shortname 50010314-COM302-15422    # era 50010314-COM302-115449    (GVEC - Politicas de marketing)
moosh -n course-config-set course 236 shortname 50010314-COM302-15409    # era 50010314-COM302-1118508   (GVEC - Digitalizacion aplicada a los sectores productivos (GS))
moosh -n course-config-set course 646 shortname 22002521-CESIFC01-19116  # era 22002521-CESIFC01-14344   (CETI - Normativa de ciberseguridad)
moosh -n course-config-set course 647 shortname 22002521-CESIFC01-19112  # era 22002521-CESIFC01-14343   (CETI - Hacking etico)
moosh -n course-config-set course 648 shortname 22002521-CESIFC01-19108  # era 22002521-CESIFC01-14342   (CETI - Analisis forense informatico)
moosh -n course-config-set course 649 shortname 22002521-CESIFC01-19118  # era 22002521-CESIFC01-14341   (CETI - Puesta en produccion segura)
moosh -n course-config-set course 650 shortname 22002521-CESIFC01-19110  # era 22002521-CESIFC01-14340   (CETI - Bastionado de redes y sistemas)
moosh -n course-config-set course 651 shortname 22002521-CESIFC01-19114  # era 22002521-CESIFC01-14339   (CETI - Incidentes de ciberseguridad)
