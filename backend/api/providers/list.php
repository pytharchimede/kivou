<?php
require_once __DIR__ . '/../../config.php';

// Optional filters via query: category, minRating, q
$filters = [
    'category' => isset($_GET['category']) ? trim($_GET['category']) : null,
    'minRating' => isset($_GET['minRating']) ? floatval($_GET['minRating']) : null,
    'q' => isset($_GET['q']) ? trim($_GET['q']) : null,
];

$repo = new \Kivou\Repositories\ServiceProviderRepository();
$items = $repo->list($filters);
json_ok(array_map(fn($p) => $p->json(), $items));
