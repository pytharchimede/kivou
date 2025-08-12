<?php
require_once __DIR__ . '/../../config.php';
$claims = require_auth();
$userId = (int)($claims['id'] ?? 0);
$body = get_json_body();
require_fields($body, ['conversation_id']);

$convId = (int)$body['conversation_id'];
if ($convId <= 0) json_error('BAD_REQUEST', 'conversation_id invalide');
// Corps textuel optionnel si une pièce jointe ou une localisation sont présents
$text = isset($body['body']) ? trim((string)$body['body']) : '';
$attachment = isset($body['attachment_url']) ? trim((string)$body['attachment_url']) : null;
$lat = isset($body['lat']) ? (float)$body['lat'] : null;
$lng = isset($body['lng']) ? (float)$body['lng'] : null;
if ($text === '' && $attachment === null && ($lat === null || $lng === null)) {
    json_error('BAD_REQUEST', 'Message vide');
}

// Vérifier appartenance convo et déterminer le destinataire
$row = db()->prepare('SELECT user_a_id, user_b_id FROM chat_conversations WHERE id = :id');
$row->execute([':id' => $convId]);
$conv = $row->fetch(PDO::FETCH_ASSOC);
if (!$conv) json_error('NOT_FOUND', 'Conversation introuvable', 404);
if ($conv['user_a_id'] != $userId && $conv['user_b_id'] != $userId) json_error('FORBIDDEN', 'Accès refusé', 403);

$to = ($conv['user_a_id'] == $userId) ? (int)$conv['user_b_id'] : (int)$conv['user_a_id'];

$isPinned = isset($body['is_pinned']) ? ((int)$body['is_pinned'] ? 1 : 0) : 0;
$ins = db()->prepare('INSERT INTO chat_messages(conversation_id, from_user_id, to_user_id, body, attachment_url, lat, lng, is_pinned) VALUES (:c, :f, :t, :b, :a, :lat, :lng, :p)');
$ins->bindValue(':c', $convId, PDO::PARAM_INT);
$ins->bindValue(':f', $userId, PDO::PARAM_INT);
$ins->bindValue(':t', $to, PDO::PARAM_INT);
$ins->bindValue(':b', $text, PDO::PARAM_STR);
$ins->bindValue(':a', $attachment, $attachment === null ? PDO::PARAM_NULL : PDO::PARAM_STR);
if ($lat === null) {
    $ins->bindValue(':lat', null, PDO::PARAM_NULL);
    $ins->bindValue(':lng', null, PDO::PARAM_NULL);
} else {
    $ins->bindValue(':lat', $lat);
    $ins->bindValue(':lng', $lng);
}
$ins->bindValue(':p', $isPinned, PDO::PARAM_INT);
$ins->execute();
$id = (int)db()->lastInsertId();
// Le trigger met à jour last_message/last_at et unread_*

$msg = db()->prepare('SELECT id, conversation_id, from_user_id, to_user_id, body, attachment_url, lat, lng, is_pinned, created_at FROM chat_messages WHERE id = :id');
$msg->execute([':id' => $id]);
$m = $msg->fetch(PDO::FETCH_ASSOC);

// Push notification au destinataire si FCM configuré
try {
    $pdo = db();
    $stFrom = $pdo->prepare('SELECT name FROM users WHERE id=?');
    $stFrom->execute([$userId]);
    $fromUser = $stFrom->fetch();
    $senderName = $fromUser && !empty($fromUser['name']) ? $fromUser['name'] : 'Nouveau message';
    $title = $senderName;
    $bodyPush = $text !== '' ? $text : (($attachment !== null) ? '[Image]' : (($lat !== null && $lng !== null) ? '[Localisation]' : 'Nouveau message'));
    $push = new \Kivou\Services\PushService();
    if ($push->isConfigured()) {
        $push->sendToUser((int)$to, $title, $bodyPush, [
            'type' => 'chat',
            'conversation_id' => (int)$m['conversation_id'],
        ]);
    }
} catch (\Throwable $e) { /* ignore push errors */
}

json_ok([
    'id' => (int)$m['id'],
    'conversation_id' => (int)$m['conversation_id'],
    'from_user_id' => (int)$m['from_user_id'],
    'to_user_id' => (int)$m['to_user_id'],
    'body' => (string)$m['body'],
    'attachment_url' => $m['attachment_url'],
    'lat' => isset($m['lat']) ? (float)$m['lat'] : null,
    'lng' => isset($m['lng']) ? (float)$m['lng'] : null,
    'is_pinned' => (int)$m['is_pinned'] === 1,
    'created_at' => date('c', strtotime($m['created_at'])),
]);
