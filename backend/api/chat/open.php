<?php
require_once __DIR__ . '/../../config.php';
$claims = require_auth();
$userId = (int)($claims['id'] ?? 0);
$body = get_json_body();
require_fields($body, ['peer_user_id']);

$peer = (int)$body['peer_user_id'];
$providerId = isset($body['provider_id']) ? (string)$body['provider_id'] : null;

if ($peer <= 0 || $peer === $userId) json_error('BAD_REQUEST', 'peer invalide');

// Vérifier existence du user courant et du peer (évite FK failures)
$exists = db()->prepare('SELECT COUNT(*) FROM users WHERE id IN (:me, :peer)');
$exists->execute([':me' => $userId, ':peer' => $peer]);
// MySQL ne supporte pas IN avec paramètres nommés répétés selon le mode; fallback: deux requêtes
if ((int)$exists->fetchColumn() < 2) {
    $u1 = db()->prepare('SELECT 1 FROM users WHERE id = :id');
    $u1->execute([':id' => $userId]);
    $u2 = db()->prepare('SELECT 1 FROM users WHERE id = :id');
    $u2->execute([':id' => $peer]);
    if (!$u1->fetchColumn() || !$u2->fetchColumn()) {
        json_error('BAD_REQUEST', 'Utilisateur inconnu', 400);
    }
}

// Ordre stable pour (user_a, user_b)
$a = min($userId, $peer);
$b = max($userId, $peer);

// Normaliser providerId nul → NULL pour contrainte UNIQUE
$pid = $providerId !== null && $providerId !== '' ? (int)$providerId : null;

// Si provider fourni, vérifier qu'il existe
if ($pid !== null) {
    $pchk = db()->prepare('SELECT 1 FROM service_providers WHERE id = :id');
    $pchk->execute([':id' => $pid]);
    if (!$pchk->fetchColumn()) json_error('BAD_REQUEST', 'Prestataire introuvable', 400);
}

// Chercher conversation existante
$sel = db()->prepare('SELECT * FROM chat_conversations WHERE user_a_id = :a AND user_b_id = :b AND ((provider_id IS NULL AND :pid IS NULL) OR provider_id = :pid)');
$sel->bindValue(':a', $a, PDO::PARAM_INT);
$sel->bindValue(':b', $b, PDO::PARAM_INT);
if ($pid === null) {
    $sel->bindValue(':pid', null, PDO::PARAM_NULL);
} else {
    $sel->bindValue(':pid', $pid, PDO::PARAM_INT);
}
$sel->execute();
$conv = $sel->fetch(PDO::FETCH_ASSOC);

if (!$conv) {
    $ins = db()->prepare('INSERT INTO chat_conversations(user_a_id, user_b_id, provider_id, last_message, last_at) VALUES (:a, :b, :pid, \'\', NULL)');
    $ins->bindValue(':a', $a, PDO::PARAM_INT);
    $ins->bindValue(':b', $b, PDO::PARAM_INT);
    if ($pid === null) {
        $ins->bindValue(':pid', null, PDO::PARAM_NULL);
    } else {
        $ins->bindValue(':pid', $pid, PDO::PARAM_INT);
    }
    $ins->execute();
    $id = (int)db()->lastInsertId();
    $conv = db()->query('SELECT * FROM chat_conversations WHERE id = ' . (int)$id)->fetch(PDO::FETCH_ASSOC);
}

// Trouver le peer pour cette conv
$peerId = ($conv['user_a_id'] == $userId) ? (int)$conv['user_b_id'] : (int)$conv['user_a_id'];
$u = db()->prepare('SELECT id, name, avatar_url, phone FROM users WHERE id = :id');
$u->execute([':id' => $peerId]);
$peerRow = $u->fetch(PDO::FETCH_ASSOC) ?: ['id' => $peerId, 'name' => 'Utilisateur', 'avatar_url' => ''];

$unread = ($conv['user_a_id'] == $userId) ? (int)$conv['unread_a'] : (int)$conv['unread_b'];

json_ok([
    'id' => (int)$conv['id'],
    'peer_user_id' => (int)$peerRow['id'],
    'peer_name' => (string)($peerRow['name'] ?? 'Utilisateur'),
    'peer_avatar_url' => (string)($peerRow['avatar_url'] ?? ''),
    'peer_phone' => (string)($peerRow['phone'] ?? ''),
    'last_message' => (string)($conv['last_message'] ?? ''),
    'last_at' => $conv['last_at'] ? date('c', strtotime($conv['last_at'])) : null,
    'unread_count' => $unread,
    'provider_id' => $conv['provider_id'] !== null ? (string)$conv['provider_id'] : null,
]);
