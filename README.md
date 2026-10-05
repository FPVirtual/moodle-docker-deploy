# moodle-docker-deploy

Arquitecture de deploy moodle containers

## Customize new deploy

1. Copy .env-sample to .env in root directory and customize creation new moodle's to your infraestrcture

2. Copy .env-sample to .env in nginx-proxy customize your proxy and phpmyadmin connection

3. To create DNS dinamic with OVH provider (api-ovh), you can use api-ovh. Copy .env-sample to .env and customize your API connection with OVH. (not mandatory)
   1. It's necessary to run npm install in api-ovh directory for dependences

4. Think and create a template directory (with this name) to deploy

5. Run createMoodle.sh with this template

## Update Upgrade deploy

1. Think and create a template directory to update your deploy

2. Copy env-sample-update to .env-update and customize new variables to add or modify variables (not mandatory)

3. Run upgradeMoodle over your deploy using the template

Note: The update/upgrade process make a backup of all data of the deploy in the root directoy

## Actualizaciones a pasar de Moodle 4.1.19+ a Moodle 4.5.7

Fecha: junio de 2026

## Cambio 1

Listo. He actualizado las **54 líneas** donde se invoca `moosh category-create` en el script para extraer únicamente el ID numérico de la salida.

**Cambio aplicado en cada línea:**
```bash
# Antes
ID_CATEGORY_sg=$(moosh category-create -p 0 -v 1 -d "22002521" "IES SIERRA DE GUARA")

# Después
ID_CATEGORY_sg=$(moosh category-create -p 0 -v 1 -d "22002521" "IES SIERRA DE GUARA" | grep -o '[0-9]*' | tail -1)
```

Esto captura el último número de la salida (p. ej. `22` de `Created category IES SIERRA DE GUARA 2 with id: 22.`), independientemente del texto precedente. También funciona correctamente en categorías con paréntesis en el nombre, como *"Educación Infantil (Formación Profesional)"*.

## Cambio 2

He revisado y corregido el script activo `import_FPD_categories_and_courses.sh` (el backup servía de referencia). El problema era que moosh 1.34 ahora devuelve frases completas en lugar de solo el ID numérico.

He aplicado el mismo patrón de extracción que ya se usaba para `category-create` (`| grep -o '[0-9]*' | tail -1`) a todos los comandos moosh que capturan IDs en variables:

**Cambios realizados:**

1. **`moosh course-create`** (línea 767):
   ```bash
   COURSE_ID=$(moosh course-create ... | grep -o '[0-9]*' | tail -1)
   ```

2. **`moosh course-restore`** (líneas 771-772):
   Unificado en una sola línea más robusta:
   ```bash
   COURSE_ID=$(moosh course-restore ... | tail -n 1 | grep -o '[0-9]*' | tail -1)
   ```

3. **`moosh user-create`** — Todas las capturas de IDs de usuario:
   - `FPD_ADMIN_USER_ID`
   - `INSPECCION_USER_ID`
   - `JE_SG_USER_ID` ... `JE_MM_USER_ID`
   - `FPD_APP_USER_STUDENT_ID` y `FPD_APP_USER_TEACHER_ID`

4. **`moosh role-create`** — Todas las capturas de IDs de rol:
   - `INSPECCION_ROLE_ID`
   - `JEFATURA_ROLE_ID`

Con estos cambios, todas las variables quedan únicamente con el número de ID, independientemente de la frase que devuelva moosh 1.34.

¿Quieres que aplique la misma corrección a los demás scripts (`import_IES_categories_and_courses.sh`, etc.) si los hubiera, o actualice también el archivo `_backup`?


## Sistema de gestión de plugins

A partir de junio de 2026, la plantilla `template-fpm-4.5.7-fpvirtualaragon` (y `template-fpm-4.5.7-unoconv`) utiliza un catálogo centralizado de plugins:

- **`init-scripts/plugins.json`**: catálogo maestro con metadatos de cada plugin (`name`, `component`, `moodle_path`, `default_enabled`, `school_types`, `install_types`, etc.).
- **`init-scripts/lib/plugins-lib.sh`**: helpers para leer el catálogo y determinar qué plugins están habilitados según variables `PLUGIN_*` del `.env`.
- **`init-scripts/new-install/plugins.sh`** y **`init-scripts/upgrade/plugins.sh`**: instalan y configuran los plugins habilitados mediante `moosh`.

### Habilitar/deshabilitar plugins

En el `.env` de cada instancia (generado por `createMoodle.sh`):

```env
PLUGIN_MOD_GOOGLEMEET=true
# PLUGIN_MOD_GOOGLEMEET_LEGACY=true
```

- `true`: el plugin se instala/configura.
- `false` o línea comentada: se omite.
- Si no se define la variable, se usa `default_enabled` de `plugins.json`.

### Plugin `local_educaaragon` (FPD)

Para centros FPD, el plugin `local_educaaragon` se configura automáticamente durante la instalación/upgrade. Requiere:

1. Variable `EDUCAARAGON_RESOURCES_PATH` en `.env` (por defecto `./recursos-editables`).
2. Que el directorio apuntado exista en el host.
3. Que `createMoodle.sh` pueda montarlo en `moodle-data/repository/recursos-editables`.

### Añadir un nuevo plugin

1. Incluir el plugin en `template/init-scripts/plugins.json`.
2. Si necesita acciones post-instalación, añadir el caso en `template/init-scripts/new-install/plugins.sh`.
3. Añadir la variable `PLUGIN_<NOMBRE>` a `env-sample` si se quiere controlar por `.env`.
4. Reconstruir/actualizar las instancias afectadas.


## Ficheros PHP modificados en producción (www.fpvirtualaragon.es)

Fecha: septiembre de 2026 (Moodle 4.5.12)

Cambios hechos a mano sobre `www.fpvirtualaragon.es/moodle-code` que se apartan del código original de Moodle o de los plugins. **Si se redespliega desde cero o se hace un upgrade, hay que revisar que siguen aplicados.** Los marcados como *automático* se reaplican con la plantilla; el resto hay que rehacerlos a mano.

Para comprobar qué ficheros del núcleo difieren del original, dentro del contenedor:

```bash
cd /usr/src/moodle && find . -name "*.php" -type f | while read f; do
  cmp -s "$f" "/var/www/html/$f" || echo "MODIFICADO $f"; done
```

### Núcleo de Moodle (sobrescritos)

| Fichero | Cambio | Motivo | Reaplicación |
|---|---|---|---|
| `course/lib.php` (`course_get_user_administration_options`, ~l. 3752) | El enlace «Importar» exige además `moodle/backup:backupcourse` | Al profesorado se le da `backuptargetimport`/`restoretargetimport` solo para poder **duplicar** recursos y secciones, no para importar | Automático: `init-scripts/patches/fpd/import-requiere-backupcourse.patch` |
| `backup/import.php` (~l. 52) | `require_capability('moodle/backup:backupcourse')` al entrar en la página | Igual que el anterior, bloquea el acceso directo por URL | Automático: mismo parche |

### Plugins (sobrescritos)

| Fichero | Cambio | Motivo | Reaplicación |
|---|---|---|---|
| `blocks/sharing_cart/classes/task/asynchronous_backup_task.php` (~l. 121) | `$messageenabled = false` | La bolsa de recursos no envía el email de «copia de seguridad completada» al copiar un recurso. Las copias/restauraciones de curso del núcleo siguen avisando (`backup_async_message_users` sigue activo) | Automático *si el plugin está instalado*: `init-scripts/patches/fpd/sharing-cart-sin-email-async.patch` |
| `blocks/sharing_cart/classes/task/asynchronous_restore_task.php` (~l. 80) | `$messageenabled = false` | Igual que el anterior, al pegar | Automático, mismo parche |

`block_sharing_cart` se instala desde `plugins.json` (solo FPD) con `moosh`, que elige la versión más reciente compatible con el Moodle del sitio: en 4.5 es la 5.1 (2026020901), la que tiene www. La 5.2 exige Moodle 5.2 y ya trae su propio ajuste `block_sharing_cart | backup_async_message_users`, así que al pasar a Moodle 5.2 el parche de email dejará de encajar y habrá que sustituirlo por ese ajuste.

Los parches los aplica `init-scripts/lib/apply-patches.sh` (llamado desde `init.sh`) solo en sitios `SCHOOL_TYPE=FPD`. Es idempotente; si un parche no encaja con una versión nueva de Moodle o del plugin, deja un `WARNING` en el log del contenedor y no toca nada: en ese caso hay que regenerar el `.patch`.

### Código añadido que no gestiona la plantilla

| Ruta | Qué es | Cómo restaurarlo |
|---|---|---|
| `private-reports/` (`docentes.php`, `inspeccion.php`, `jefaturas.php`, `mensajeria.php`) | Informes propios, repositorio https://github.com/FPVirtual/private-reports | Clonar el repositorio y copiar los `.php` **sin `.git`** (nginx no bloquea ficheros ocultos) a `moodle-code/private-reports`, propietario `www-data` |
| `soporte/` (`index.php`, `action.php`, `captcha.php`, `upload.php`, `secret.php`, `log.txt`) | Formulario de soporte, repositorio https://github.com/FPVirtual/formulario-soporte (en www es un clon git) | Clonar el repositorio en `moodle-code/soporte`, propietario `www-data`. **Guardar antes `secret.php`** (credenciales, no está en el repositorio) y, si se quiere conservar, `log.txt` (histórico de solicitudes, con datos personales) |
| `faqs/` (`faq3`…`faq9`, `login.png`, `google*.png`, `forgot-password.png`, `recordar-pass.png`) | Imágenes de las FAQ de la pantalla principal | Son idénticas a `init-scripts/themes/fpdist/faqs/` de la plantilla: copiar su **contenido** a `moodle-code/faqs`, propietario `www-data` |

Aunque `new-install/theme.sh` y `upgrade/theme.sh` intentan copiar `soporte/` y `faqs/`, **no se puede confiar en ellos**, así que hay que revisar ambas carpetas tras un redespliegue:

- `init-scripts/themes/fpdist/soporte/` no existe en la plantilla, así que la copia de `soporte` falla.
- Si existiera, se copiaría `secret-sample.php` encima de `secret.php`, perdiendo las credenciales.
- `mkdir …/faqs/` seguido de `cp -R …/fpdist/faqs /var/www/html/faqs` crea `faqs/faqs/` (anidado) en lugar de copiar el contenido; lo mismo pasaría con `soporte`. En www están sin anidar porque se colocaron a mano.

**nginx**: `moodle-code` se sirve tal cual, así que `soporte/log.txt` (datos personales) y cualquier `.git` (de `soporte`, `private-reports` o plugins instalados con `git_clone`) eran descargables. Desde el 29/09/2026 el `nginx/default.conf` de la plantilla, de www, pre y curso2526 devuelve 404 para rutas que empiezan por `.` (salvo `.well-known`) y para `soporte/*.txt|*.log`. Tras un redespliegue, comprobar que siguen bloqueadas:

```bash
for u in /soporte/log.txt /soporte/.git/HEAD /mod/googlemeet/.git/HEAD; do
  curl -s -o /dev/null -w "$u %{http_code}\n" https://www.fpvirtualaragon.es$u; done   # debe dar 404
```

### Configuración en base de datos relacionada

No son ficheros, pero los parches anteriores dependen de ella. Se aplicó a mano en www y pre (contexto de sistema) y **no está en la plantilla**:

- `editingteacher`: permitido `moodle/backup:backupactivity`, `moodle/restore:restoreactivity`, `moodle/backup:backuptargetimport`, `moodle/restore:restoretargetimport`; prohibido `moodle/backup:backupcourse`, `backupsection`, `configure`, `downloadfile`, `moodle/restore:restorecourse`, `restoresection`, `uploadfile`.
- `teacher`: prohibido `moodle/backup:backupcourse`, `backupsection`, `backuptargetimport`, `downloadfile`, `moodle/restore:restorecourse`, `restoresection`, `restoretargetimport`, `uploadfile`.


### Nombre corto del curso (profesorado)

El nombre corto se usa en automatizaciones, así que el profesorado no debe poder cambiarlo. Estado de `moodle/course:changeshortname` para `editingteacher` en contexto de sistema:

| Sitio | Permiso | Origen |
|---|---|---|
| `moodle.campusdigitalfp.com` | Prohibir (`-1000`) | A mano el 05/10/2026 (antes estaba en Permitir) |
| `www.fpvirtualaragon.es`, `pre.fpvirtualaragon.es`, `formacion.fpvirtualaragon.es` | Prohibir (`-1000`) | Ya estaba así el 05/10/2026 |
| Instalaciones nuevas FPD | Prohibir (`-1000`) | Automático: `init-scripts/new-install/moodle.sh` |

La plantilla solo lo aplica en `new-install`; un `update` o `upgrade` no lo toca, así que en sitios existentes hay que ponerlo a mano:

```bash
moosh -n role-update-capability editingteacher moodle/course:changeshortname prohibit 1
```

Al ser Prohibir, quien sea gestor y además profesor de un curso tampoco puede cambiar el nombre corto en ese curso. `moodle/course:changefullname` sigue permitido para `editingteacher` en `moodle.campusdigitalfp.com`. El rol `teacher` tiene ambas capacidades prohibidas desde la plantilla.
