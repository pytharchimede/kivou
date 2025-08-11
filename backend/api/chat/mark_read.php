<?php
require_once __DIR__ . '/../../config.php';
$claims = require_auth();
$userId = (int)($claims['id'] ?? 0);
$body = get_json_body();
require_fields($body, ['conversation_id']);
$convId = (int)$body['conversation_id'];
if ($convId <= 0) json_error('BAD_REQUEST', 'conversation_id invalide');

// Vérifier appartenance
$chk = db()->prepare('SELECT 1 FROM chat_conversations WHERE id = :id AND (user_a_id = :u OR user_b_id = :u)');
$chk->execute([':id' => $convId, ':u' => $userId]);
if (!$chk->fetchColumn()) json_error('FORBIDDEN', 'Accès refusé', 403);

// Marquer comme lu
db()->query('CALL sp_chat_mark_read(' . (int)$convId . ', ' . (int)$userId . ')');
json_ok(['ok' => true]);
