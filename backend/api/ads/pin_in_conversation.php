<?php
require_once __DIR__ . '/../../config.php';
$claims = require_auth();
$userId = (int)($claims['id'] ?? 0);
$body = get_json_body();
require_fields($body, ['conversation_id', 'ad_id']);

$convId = (int)$body['conversation_id'];
$adId = (int)$body['ad_id'];
if ($convId <= 0 || $adId <= 0) json_error('BAD_REQUEST', 'IDs invalides');

// Vérifier l'appartenance à la conversation
$st = db()->prepare('SELECT user_a_id, user_b_id FROM chat_conversations WHERE id=?');
$st->execute([$convId]);
$conv = $st->fetch(PDO::FETCH_ASSOC);
if (!$conv) json_error('NOT_FOUND', 'Conversation introuvable', 404);
if ($conv['user_a_id'] != $userId && $conv['user_b_id'] != $userId) json_error('FORBIDDEN', 'Accès refusé', 403);

// Vérifier l'annonce
$ad = db()->prepare('SELECT id, title, description, image_url FROM ads WHERE id=? AND status=\'active\'');
$ad->execute([$adId]);
$row = $ad->fetch(PDO::FETCH_ASSOC);
if (!$row) json_error('NOT_FOUND', 'Annonce introuvable/fermée', 404);

$upd = db()->prepare('UPDATE chat_conversations SET pinned_ad_id=?, pinned_text=?, pinned_image_url=?, pinned_at=NOW() WHERE id=?');
$ptext = $row['title'];
if (!empty($row['description'])) {
    $ptext .= " — " . mb_substr($row['description'], 0, 120);
}
$upd->execute([$adId, $ptext, $row['image_url'] ?? null, $convId]);

json_ok(['conversation_id' => $convId, 'pinned' => ['ad_id' => $adId, 'text' => $ptext, 'image_url' => ($row['image_url'] ?? null)]]);
