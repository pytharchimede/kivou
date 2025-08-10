<?php
require_once __DIR__ . '/../../config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_error('METHOD_NOT_ALLOWED', 'Use POST', 405);
}
$body = get_json_body();
require_fields($body, ['booking_id', 'provider_id', 'rating']);

$claims = null;
try {
    $claims = require_auth();
} catch (Throwable $e) { /* facultatif */
}
$userId = isset($claims['sub']) ? (int)$claims['sub'] : (int)($body['user_id'] ?? 0);
if ($userId <= 0) json_error('UNAUTHORIZED', 'user_id required (token or field)', 401);

$repo = new \Kivou\Repositories\ReviewRepository();
$id = $repo->create([
    'booking_id' => (int)$body['booking_id'],
    'user_id' => $userId,
    'provider_id' => (int)$body['provider_id'],
    'rating' => (float)$body['rating'],
    'comment' => $body['comment'] ?? null,
    'photos' => $body['photos'] ?? null,
]);
json_ok(['id' => (int)$id], 201);
