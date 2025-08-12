<?php
require_once __DIR__ . '/../../config.php';

// Auth requis
$claims = require_auth();
$userId = (int)($claims['id'] ?? 0);

$body = get_json_body();

$token = isset($body['token']) ? trim((string)$body['token']) : '';
$toUserId = isset($body['user_id']) ? (int)$body['user_id'] : 0;
$title = isset($body['title']) ? (string)$body['title'] : 'Test Push';
$msg   = isset($body['body']) ? (string)$body['body'] : 'Ping from Kivou';
$data  = isset($body['data']) && is_array($body['data']) ? $body['data'] : [];

// Sécurité simple: si user_id est précisé, il doit être le user courant (éviter spam d'autres utilisateurs)
if ($toUserId && $toUserId !== $userId) {
    json_error('FORBIDDEN', 'user_id non autorisé', 403);
}

$push = new \Kivou\Services\PushService();
$debugFlag = isset($body['debug']) && ($body['debug'] === true || $body['debug'] === 1 || $body['debug'] === 'true');
if ($debugFlag) {
    putenv('PUSH_DEBUG=1');
}
if (!$push->isConfigured()) {
    json_error('PUSH_NOT_CONFIGURED', 'Push non configuré');
}

$ok = false;
if ($token !== '') {
    // Envoi direct à un token fourni
    $ok = $push->sendToTokens([$token], $title, $msg, $data);
} else {
    // Envoi aux tokens de l'utilisateur courant (ou de user_id==courant)
    $ok = $push->sendToUser($userId, $title, $msg, $data);
}

$out = [
    'ok' => (bool)$ok,
    'hint' => $debugFlag ? 'Logs FCM écrits dans backend/logs/push.log' : null,
];
json_ok($out);
