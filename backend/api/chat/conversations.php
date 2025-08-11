<?php
require_once __DIR__ . '/../../config.php';
$claims = require_auth();
$userId = (int)($claims['id'] ?? 0);

// TODO: Replace with DB implementation
// Expected output: list of conversations with peer info and last message
json_ok([
    [
        'id' => 1,
        'peer_user_id' => 42,
        'peer_name' => 'Prestataire Démo',
        'peer_avatar_url' => '',
        'last_message' => 'Bonjour, comment puis-je vous aider ?',
        'last_at' => date('c'),
        'unread_count' => 0,
        'provider_id' => '1',
    ],
]);
