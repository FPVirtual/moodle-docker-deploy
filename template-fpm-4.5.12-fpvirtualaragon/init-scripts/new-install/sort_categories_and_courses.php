<?php
/**
 * Ordena alfabéticamente las categorías, subcategorías y cursos del sitio.
 *
 * Solo cambia el campo sortorder (orden de visualización); los IDs de
 * categorías y cursos no se modifican, por lo que es compatible con la
 * restricción de IDs invariables de import_FPD_categories_and_courses.sh.
 *
 * - Categorías y subcategorías: por nombre.
 * - Cursos dentro de cada categoría: por nombre completo (fullname).
 *
 * Es idempotente: puede relanzarse sin efectos secundarios.
 */

define('CLI_SCRIPT', true);
require_once('/var/www/html/config.php');

mtrace('=== Ordenando categorías y cursos alfabéticamente ===');

// Primero las categorías de primer nivel y después, recursivamente, el resto.
core_course_category::top()->resort_subcategories('name');

$categories = $DB->get_records('course_categories', null, 'depth, sortorder', 'id, name');
foreach ($categories as $category) {
    $coursecat = core_course_category::get($category->id, MUST_EXIST, true);
    $coursecat->resort_subcategories('name');
    $coursecat->resort_courses('fullname');
    mtrace("Ordenada [{$category->id}] {$category->name}");
}

cache_helper::purge_all();
mtrace('=== Categorías y cursos ordenados ===');
