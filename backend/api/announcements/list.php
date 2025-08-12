<?php
require_once __DIR__ . '/../../config.php';
$claims = require_auth();
$userId = (int)($claims['id'] ?? 0);

$type = isset($_GET['type']) ? trim((string)$_GET['type']) : null; // request|offer
$authorRole = isset($_GET['author_role']) ? trim((string)$_GET['author_role']) : null; // client|provider
$limit = isset($_GET['limit']) ? max(1, min(100, (int)$_GET['limit'])) : 30;
$offset = isset($_GET['offset']) ? max(0, (int)$_GET['offset']) : 0;

$sql = "SELECT a.*, 
  COALESCE(sp.owner_user_id, a.author_user_id) AS publisher_user_id,
  u.name AS publisher_name,
  u.avatar_url AS publisher_avatar_url
FROM announcements a
LEFT JOIN service_providers sp ON sp.id = a.provider_id
LEFT JOIN users u ON u.id = COALESCE(sp.owner_user_id, a.author_user_id)
WHERE 1=1";

$params = [];
if ($type) {
    $sql .= " AND a.type = :type";
    $params[':type'] = $type;
}
if ($authorRole) {
    $sql .= " AND a.author_role = :ar";
    $params[':ar'] = $authorRole;
}
$sql .= " ORDER BY a.id DESC LIMIT :lim OFFSET :off";

$stmt = db()->prepare($sql);
foreach ($params as $k => $v) $stmt->bindValue($k, $v);
$stmt->bindValue(':lim', $limit, PDO::PARAM_INT);
$stmt->bindValue(':off', $offset, PDO::PARAM_INT);
$stmt->execute();
$rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

$out = [];
foreach ($rows as $r) {
    $images = [];
    if (!empty($r['images'])) {
        $decoded = json_decode($r['images'], true);
        if (is_array($decoded)) $images = array_values(array_filter($decoded, 'is_string'));
    }
    $out[] = [
        'id' => (int)$r['id'],
        'type' => $r['type'],
        'author_role' => $r['author_role'],
        'provider_id' => $r['provider_id'] !== null ? (int)$r['provider_id'] : null,
        'title' => (string)$r['title'],
        'description' => (string)($r['description'] ?? ''),
        'price' => $r['price'] !== null ? (float)$r['price'] : null,
        'images' => $images,
        'created_at' => date('c', strtotime($r['created_at'])),
        'publisher_user_id' => (int)$r['publisher_user_id'],
        'publisher_name' => (string)$r['publisher_name'],
        'publisher_avatar_url' => $r['publisher_avatar_url'],
    ];
}

json_ok($out);
