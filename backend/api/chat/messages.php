<?php
require_once __DIR__ . '/../../config.php';
$claims = require_auth();
$userId = (int)($claims['id'] ?? 0);
$convId = (int)($_GET['conversation_id'] ?? 0);

// TODO: Replace with DB implementation
json_ok([
    [
        'id' => 1,
        'conversation_id' => $convId,
        'from_user_id' => $userId,
        'to_user_id' => 42,
        'body' => 'Bonjour !',
        'created_at' => date('c'),
    ],
    [
        'id' => 2,
        'conversation_id' => $convId,
        'from_user_id' => 42,
        'to_user_id' => $userId,
        'body' => 'Salut, je suis dispo demain.',
        'created_at' => date('c'),
    ],
]);
