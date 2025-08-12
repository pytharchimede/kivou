<?php
require_once __DIR__ . '/../../config.php';
$claims = require_auth();
$userId = (int)($claims['id'] ?? 0);

// Récupère toutes les conversations où l'utilisateur est A ou B, joint le peer et retourne le compteur d'UNREAD côté courant
$sql = "
    SELECT c.id,
                     c.user_a_id, c.user_b_id,
                     c.provider_id,
             c.pinned_ad_id, c.pinned_text, c.pinned_image_url, c.pinned_at,
                     c.last_message,
                     c.last_at,
                     CASE WHEN c.user_a_id = :uid THEN c.unread_a ELSE c.unread_b END AS unread_count,
                     upeer.id   AS peer_user_id,
                     upeer.name AS peer_name,
                     upeer.avatar_url AS peer_avatar_url,
                     sp.name AS provider_name,
                     sp.photo_url AS provider_avatar_url,
                     sp.owner_user_id AS provider_owner_user_id,
                     CASE 
                         WHEN c.provider_id IS NOT NULL AND sp.owner_user_id = c.user_a_id THEN c.user_b_id
                         WHEN c.provider_id IS NOT NULL AND sp.owner_user_id = c.user_b_id THEN c.user_a_id
                         ELSE NULL
                     END AS client_user_id,
                     uclient.name AS client_name,
                     uclient.avatar_url AS client_avatar_url
        FROM chat_conversations c
        JOIN users upeer
            ON upeer.id = CASE WHEN c.user_a_id = :uid THEN c.user_b_id ELSE c.user_a_id END
        LEFT JOIN service_providers sp ON sp.id = c.provider_id
        LEFT JOIN users uclient ON uclient.id = CASE 
                         WHEN c.provider_id IS NOT NULL AND sp.owner_user_id = c.user_a_id THEN c.user_b_id
                         WHEN c.provider_id IS NOT NULL AND sp.owner_user_id = c.user_b_id THEN c.user_a_id
                         ELSE NULL END
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
        'pinned_ad_id' => isset($r['pinned_ad_id']) ? (int)$r['pinned_ad_id'] : null,
        'pinned_text' => isset($r['pinned_text']) ? (string)$r['pinned_text'] : null,
        'pinned_image_url' => isset($r['pinned_image_url']) ? (string)$r['pinned_image_url'] : null,
        'pinned_at' => isset($r['pinned_at']) && $r['pinned_at'] ? date('c', strtotime($r['pinned_at'])) : null,
        'last_message' => (string)($r['last_message'] ?? ''),
        'last_at' => $r['last_at'] ? date('c', strtotime($r['last_at'])) : null,
        'unread_count' => (int)$r['unread_count'],
        'provider_id' => $r['provider_id'] !== null ? (string)$r['provider_id'] : null,
        'provider_name' => isset($r['provider_name']) ? (string)$r['provider_name'] : '',
        'provider_avatar_url' => isset($r['provider_avatar_url']) ? (string)$r['provider_avatar_url'] : '',
        'provider_owner_user_id' => isset($r['provider_owner_user_id']) ? (int)$r['provider_owner_user_id'] : null,
        'client_user_id' => isset($r['client_user_id']) ? (int)$r['client_user_id'] : null,
        'client_name' => isset($r['client_name']) ? (string)$r['client_name'] : '',
        'client_avatar_url' => isset($r['client_avatar_url']) ? (string)$r['client_avatar_url'] : '',
    ];
}

json_ok($out);
