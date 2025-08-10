<?php
require_once __DIR__ . '/../config.php';

try {
    // Vérifie la connexion DB
    $ok = db()->query('SELECT 1')->fetchColumn() == 1;
    json_ok([
        'status' => 'ok',
        'db' => $ok,
        'time' => date('c')
    ]);
} catch (Throwable $e) {
    json_error('HEALTH_FAIL', $e->getMessage(), 500);
}
