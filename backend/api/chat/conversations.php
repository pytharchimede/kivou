<?php
require_once __DIR__ . '/../../config.php';
$claims = require_auth();
$userId = (int)($claims['id'] ?? 0);

// Récupère toutes les conversations où l'utilisateur est A ou B, joint le peer et retourne le compteur d'UNREAD côté courant
$sql = "
    SELECT c.id,
                 c.user_a_id, c.user_b_id,
                 c.provider_id,
                 c.last_message,
                 c.last_at,
                 CASE WHEN c.user_a_id = :uid THEN c.unread_a ELSE c.unread_b END AS unread_count,
                 upeer.id AS peer_user_id,
                 upeer.name AS peer_name,
                 upeer.avatar_url AS peer_avatar_url
        FROM chat_conversations c
        JOIN users upeer
            ON upeer.id = CASE WHEN c.user_a_id = :uid THEN c.user_b_id ELSE c.user_a_id END
     WHERE c.user_a_id = :uid OR c.user_b_id = :uid
     ORDER BY COALESCE(c.last_at, c.created_at) DESC, c.id DESC
";

$stmt = db()->prepare($sql);
$stmt->execute([':uid' => $userId]);
$rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

$out = [];
foreach ($rows as $r) {
    $out[] = [
        'id' => (int)$r['id'],
        'peer_user_id' => (int)$r['peer_user_id'],
        'peer_name' => $r['peer_name'] ?? 'Utilisateur',
        'peer_avatar_url' => (string)($r['peer_avatar_url'] ?? ''),
        'last_message' => (string)($r['last_message'] ?? ''),
        'last_at' => $r['last_at'] ? date('c', strtotime($r['last_at'])) : null,
        'unread_count' => (int)$r['unread_count'],
        'provider_id' => $r['provider_id'] !== null ? (string)$r['provider_id'] : null,
    ];
}

json_ok($out);
