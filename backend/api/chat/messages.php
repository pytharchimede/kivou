<?php
require_once __DIR__ . '/../../config.php';
$claims = require_auth();
$userId = (int)($claims['id'] ?? 0);
$convId = (int)($_GET['conversation_id'] ?? 0);
if ($convId <= 0) json_error('BAD_REQUEST', 'conversation_id manquant');

// Vérifier que l'utilisateur appartient à la conversation
$chk = db()->prepare('SELECT 1 FROM chat_conversations WHERE id = :id AND (user_a_id = :u OR user_b_id = :u)');
$chk->execute([':id' => $convId, ':u' => $userId]);
if (!$chk->fetchColumn()) json_error('FORBIDDEN', 'Accès refusé', 403);

$limit = isset($_GET['limit']) ? max(1, min(200, (int)$_GET['limit'])) : 100;
$since = isset($_GET['since']) ? (int)$_GET['since'] : 0; // id > since

$sql = 'SELECT id, conversation_id, from_user_id, to_user_id, body, attachment_url, created_at, read_at
                    FROM chat_messages
                 WHERE conversation_id = :cid ' . ($since > 0 ? ' AND id > :since' : '') . '
                 ORDER BY id DESC
                 LIMIT :lim';

$stmt = db()->prepare($sql);
$stmt->bindValue(':cid', $convId, PDO::PARAM_INT);
if ($since > 0) $stmt->bindValue(':since', $since, PDO::PARAM_INT);
$stmt->bindValue(':lim', $limit, PDO::PARAM_INT);
$stmt->execute();
$rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

$out = [];
foreach ($rows as $r) {
    $out[] = [
        'id' => (int)$r['id'],
        'conversation_id' => (int)$r['conversation_id'],
        'from_user_id' => (int)$r['from_user_id'],
        'to_user_id' => (int)$r['to_user_id'],
        'body' => (string)$r['body'],
        'attachment_url' => $r['attachment_url'],
        'created_at' => date('c', strtotime($r['created_at'])),
        'read_at' => $r['read_at'] ? date('c', strtotime($r['read_at'])) : null,
    ];
}

// Retourner du plus ancien au plus récent côté client
json_ok(array_reverse($out));
