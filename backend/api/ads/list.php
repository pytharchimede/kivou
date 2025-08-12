<?php
require_once __DIR__ . '/../../config.php';

// Auth facultative pour afficher les annonces publiques; mais on l'accepte aussi pour contextualiser plus tard
// $claims = require_auth();

// Filtres optionnels: kind (request|offer), author_type (client|provider), category, status (active par défaut), q, provider_id, limit
$kind = isset($_GET['kind']) ? strtolower(trim($_GET['kind'])) : null;
$authorType = isset($_GET['author_type']) ? strtolower(trim($_GET['author_type'])) : null;
$category = isset($_GET['category']) ? trim($_GET['category']) : null;
$status = isset($_GET['status']) ? strtolower(trim($_GET['status'])) : 'active';
$q = isset($_GET['q']) ? trim($_GET['q']) : null;
$providerId = isset($_GET['provider_id']) ? (int)$_GET['provider_id'] : null;
$limit = isset($_GET['limit']) ? max(1, min(100, (int)$_GET['limit'])) : 50;

$sql = "SELECT a.*, u.name AS author_name, u.avatar_url AS author_avatar, sp.name AS provider_name, sp.photo_url AS provider_photo
        FROM ads a
        JOIN users u ON u.id = a.author_user_id
        LEFT JOIN service_providers sp ON sp.id = a.provider_id";
$where = [];
$params = [];
if ($kind && in_array($kind, ['request', 'offer'], true)) {
    $where[] = 'a.kind = ?';
    $params[] = $kind;
}
if ($authorType && in_array($authorType, ['client', 'provider'], true)) {
    $where[] = 'a.author_type = ?';
    $params[] = $authorType;
}
if (!empty($category)) {
    $where[] = 'a.category = ?';
    $params[] = $category;
}
if (!empty($status)) {
    $where[] = 'a.status = ?';
    $params[] = $status;
}
if ($providerId) {
    $where[] = 'a.provider_id = ?';
    $params[] = $providerId;
}
if (!empty($q)) {
    $where[] = '(LOWER(a.title) LIKE ? OR LOWER(a.description) LIKE ?)';
    $qq = '%' . strtolower($q) . '%';
    $params[] = $qq;
    $params[] = $qq;
}
if ($where) {
    $sql .= ' WHERE ' . implode(' AND ', $where);
}
$sql .= ' ORDER BY a.created_at DESC, a.id DESC LIMIT ' . (int)$limit;

$st = db()->prepare($sql);
$st->execute($params);
$rows = $st->fetchAll(PDO::FETCH_ASSOC);

$out = array_map(function ($r) {
    return [
        'id' => (int)$r['id'],
        'author_user_id' => (int)$r['author_user_id'],
        'author_type' => $r['author_type'],
        'provider_id' => $r['provider_id'] !== null ? (int)$r['provider_id'] : null,
        'kind' => $r['kind'],
        'title' => (string)$r['title'],
        'description' => (string)($r['description'] ?? ''),
        'image_url' => (string)($r['image_url'] ?? ''),
        'amount' => isset($r['amount']) ? (float)$r['amount'] : null,
        'currency' => (string)($r['currency'] ?? 'XOF'),
        'category' => (string)($r['category'] ?? ''),
        'lat' => isset($r['lat']) ? (float)$r['lat'] : null,
        'lng' => isset($r['lng']) ? (float)$r['lng'] : null,
        'status' => (string)$r['status'],
        'created_at' => date('c', strtotime($r['created_at'])),
        'updated_at' => date('c', strtotime($r['updated_at'])),
        'author_name' => (string)($r['author_name'] ?? ''),
        'author_avatar_url' => (string)($r['author_avatar'] ?? ''),
        'provider_name' => (string)($r['provider_name'] ?? ''),
        'provider_photo_url' => (string)($r['provider_photo'] ?? ''),
    ];
}, $rows);

json_ok($out);
