<?php
require_once __DIR__ . '/../../config.php';
$pdo = \Kivou\Support\Database::pdo();
$total = (int)$pdo->query('SELECT COUNT(*) FROM service_providers')->fetchColumn();
json_ok(['total' => $total]);
