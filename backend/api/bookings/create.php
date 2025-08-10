<?php
require_once __DIR__ . '/../../config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_error('METHOD_NOT_ALLOWED', 'Use POST', 405);
}
$body = get_json_body();
require_fields($body, ['provider_id', 'service_category', 'scheduled_at', 'duration', 'total_price']);

// si token présent, on ignore user_id et on prend sub
$claims = null;
try {
    $claims = require_auth();
} catch (Throwable $e) { /* facultatif */
}
$userId = isset($claims['sub']) ? (int)$claims['sub'] : (int)($body['user_id'] ?? 0);
if ($userId <= 0) json_error('UNAUTHORIZED', 'user_id required (token or field)', 401);

$repo = new \Kivou\Repositories\BookingRepository();
$id = $repo->create([
    'user_id' => $userId,
    'provider_id' => (int)$body['provider_id'],
    'service_category' => $body['service_category'],
    'service_description' => $body['service_description'] ?? null,
    'scheduled_at' => $body['scheduled_at'],
    'duration' => (float)$body['duration'],
    'total_price' => (float)$body['total_price'],
]);
// Create a notification for the provider (not the client)
try {
    $pdo = db();
    $stN = $pdo->prepare('INSERT INTO notifications (user_id, provider_id, title, body) VALUES (NULL,?,?,?)');
    $title = 'Nouvelle commande';
    $bodyMsg = 'Vous avez une nouvelle commande prévue le ' . $body['scheduled_at'];
    $stN->execute([(int)$body['provider_id'], $title, $bodyMsg]);
} catch (Throwable $e) { /* ignore notification errors */
}

json_ok(['id' => (int)$id], 201);
