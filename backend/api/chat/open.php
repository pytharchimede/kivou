<?php
require_once __DIR__ . '/../../config.php';
$claims = require_auth();
$userId = (int)($claims['id'] ?? 0);
$body = get_json_body();
require_fields($body, ['peer_user_id']);

$peer = (int)$body['peer_user_id'];
$providerId = isset($body['provider_id']) ? (string)$body['provider_id'] : null;

// TODO: Find or create conversation in DB
json_ok([
    'id' => random_int(10, 999),
    'peer_user_id' => $peer,
    'peer_name' => 'Interlocuteur',
    'peer_avatar_url' => '',
    'last_message' => '',
    'last_at' => date('c'),
    'unread_count' => 0,
    'provider_id' => $providerId,
]);
