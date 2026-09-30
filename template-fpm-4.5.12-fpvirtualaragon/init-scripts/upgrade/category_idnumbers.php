<?php
// Asigna el idnumber a las categorías FPD creadas cuando get_or_create_category guardaba
// el código en la descripción (moosh category-create -d) en lugar de en el idnumber.
//   - Categoría de centro: idnumber = código de centro (50020125).
//   - Categoría de ciclo: idnumber = centro-ciclo (50020125-IFC301), como las cohortes.
// La descripción, que solo contenía el código, se vacía. Solo toca categorías sin idnumber
// cuya descripción es un código, así que puede relanzarse sin efectos secundarios.

define('CLI_SCRIPT', true);
require('/var/www/html/config.php');

$categories = $DB->get_records('course_categories', null, 'depth, sortorder', 'id, parent, name, idnumber, description');

foreach ($categories as $category) {
    $code = trim((string) $category->description);
    if ($category->idnumber !== '' || !preg_match('/^[A-Za-z0-9]+$/', $code)) {
        continue;
    }

    if ($category->parent == 0) {
        $idnumber = $code;
    } else {
        // Las categorías se recorren por profundidad, así que el padre ya tiene su idnumber.
        $parentidnumber = $categories[$category->parent]->idnumber ?? '';
        if ($parentidnumber === '') {
            echo "WARNING: la categoría padre de '{$category->name}' (id {$category->id}) no tiene idnumber, se omite\n";
            continue;
        }
        $idnumber = $parentidnumber . '-' . $code;
    }

    if ($DB->record_exists('course_categories', ['idnumber' => $idnumber])) {
        echo "WARNING: el idnumber {$idnumber} ya existe, se omite '{$category->name}' (id {$category->id})\n";
        continue;
    }

    core_course_category::get($category->id, MUST_EXIST, true)->update(['idnumber' => $idnumber, 'description' => '']);
    $categories[$category->id]->idnumber = $idnumber;
    echo "Categoría '{$category->name}' (id {$category->id}): idnumber={$idnumber}\n";
}
