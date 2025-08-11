<?php
require_once __DIR__ . '/../../config.php';
$claims = require_auth();
$userId = (int)($claims['id'] ?? 0);
$body = get_json_body();
require_fields($body, ['conversation_id', 'body']);

$convId = (int)$body['conversation_id'];
$msg = [
    'id' => random_int(100, 99999),
    'conversation_id' => $convId,
    'from_user_id' => $userId,
    'to_user_id' => 42,
    'body' => $body['body'],
    'created_at' => date('c'),
];

// TODO: Persist message in DB and push notifications
json_ok($msg);
