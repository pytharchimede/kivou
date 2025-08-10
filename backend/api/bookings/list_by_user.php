<?php
require_once __DIR__ . '/../../config.php';

$claims = null;
try {
    $claims = require_auth();
} catch (Throwable $e) { /* facultatif */
}
$userId = isset($claims['sub']) ? (int)$claims['sub'] : (int)($_GET['user_id'] ?? 0);
if ($userId <= 0) json_error('UNAUTHORIZED', 'user_id required (token or query)', 401);

$repo = new \Kivou\Repositories\BookingRepository();
$items = $repo->listByUser($userId);
json_ok(array_map(fn($b) => $b->json(), $items));
