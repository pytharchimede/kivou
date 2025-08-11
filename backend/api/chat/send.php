<?php
require_once __DIR__ . '/../../config.php';
$claims = require_auth();
$userId = (int)($claims['id'] ?? 0);
$body = get_json_body();
require_fields($body, ['conversation_id', 'body']);

$convId = (int)$body['conversation_id'];
if ($convId <= 0) json_error('BAD_REQUEST', 'conversation_id invalide');
if (!is_string($body['body']) || trim($body['body']) === '') json_error('BAD_REQUEST', 'Message vide');

// Vérifier appartenance convo et déterminer le destinataire
$row = db()->prepare('SELECT user_a_id, user_b_id FROM chat_conversations WHERE id = :id');
$row->execute([':id' => $convId]);
$conv = $row->fetch(PDO::FETCH_ASSOC);
if (!$conv) json_error('NOT_FOUND', 'Conversation introuvable', 404);
if ($conv['user_a_id'] != $userId && $conv['user_b_id'] != $userId) json_error('FORBIDDEN', 'Accès refusé', 403);

$to = ($conv['user_a_id'] == $userId) ? (int)$conv['user_b_id'] : (int)$conv['user_a_id'];

$ins = db()->prepare('INSERT INTO chat_messages(conversation_id, from_user_id, to_user_id, body) VALUES (:c, :f, :t, :b)');
$ins->execute([':c' => $convId, ':f' => $userId, ':t' => $to, ':b' => $body['body']]);
$id = (int)db()->lastInsertId();
// Le trigger met à jour last_message/last_at et unread_*

$msg = db()->prepare('SELECT id, conversation_id, from_user_id, to_user_id, body, created_at FROM chat_messages WHERE id = :id');
$msg->execute([':id' => $id]);
$m = $msg->fetch(PDO::FETCH_ASSOC);

json_ok([
    'id' => (int)$m['id'],
    'conversation_id' => (int)$m['conversation_id'],
    'from_user_id' => (int)$m['from_user_id'],
    'to_user_id' => (int)$m['to_user_id'],
    'body' => (string)$m['body'],
    'created_at' => date('c', strtotime($m['created_at'])),
]);
