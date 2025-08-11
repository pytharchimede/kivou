<?php
require_once __DIR__ . '/../../config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    json_error('METHOD_NOT_ALLOWED', 'Use GET', 405);
}

$pdo = db();
// Table: service_categories (id INT AI PK, name VARCHAR(100) UNIQUE NOT NULL, is_active TINYINT(1) DEFAULT 1)
$st = $pdo->query('SELECT id,name FROM service_categories WHERE is_active=1 ORDER BY name ASC');
$rows = $st->fetchAll();

$items = array_map(function ($r) {
    return [
        'id' => (int)$r['id'],
        'name' => $r['name'],
    ];
}, $rows);

json_ok($items);
