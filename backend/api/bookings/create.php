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
// Create a notification for the provider owner (user who created the provider)
try {
    $pdo = db();
    // Récupérer directement le propriétaire du prestataire
    $ownerUserId = null;
    $stP = $pdo->prepare('SELECT owner_user_id FROM service_providers WHERE id=?');
    $stP->execute([(int)$body['provider_id']]);
    $prov = $stP->fetch();
    if ($prov && isset($prov['owner_user_id'])) {
        $ownerUserId = $prov['owner_user_id'] !== null ? (int)$prov['owner_user_id'] : null;
    }
    $stN = $pdo->prepare('INSERT INTO notifications (user_id, provider_id, title, body) VALUES (?,?,?,?)');
    $title = 'Nouvelle commande';
    $bodyMsg = 'Vous avez une nouvelle commande prévue le ' . $body['scheduled_at'];
    $stN->execute([$ownerUserId, (int)$body['provider_id'], $title, $bodyMsg]);

    // Push à l'owner si FCM configuré
    if (!empty($ownerUserId)) {
        $push = new \Kivou\Services\PushService();
        if ($push->isConfigured()) {
            $push->sendToUser((int)$ownerUserId, $title, $bodyMsg, [
                'type' => 'booking',
                'action' => 'created',
            ]);
        }
    }
} catch (Throwable $e) { /* ignore notification errors */
}

json_ok(['id' => (int)$id], 201);
