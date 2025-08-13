<?php
require_once __DIR__ . '/../../config.php';

$id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
if ($id <= 0) json_error('BAD_REQUEST', 'id requis');

$sql = 'SELECT a.*, u.name AS author_name, u.avatar_url AS author_avatar, sp.name AS provider_name, sp.photo_url AS provider_photo FROM ads a JOIN users u ON u.id=a.author_user_id LEFT JOIN service_providers sp ON sp.id=a.provider_id WHERE a.id=? LIMIT 1';
$st = db()->prepare($sql);
$st->execute([$id]);
$r = $st->fetch(PDO::FETCH_ASSOC);
if (!$r) json_error('NOT_FOUND', "Annonce $id introuvable", 404);

$imgs = db()->prepare('SELECT id, url, sort_order FROM ad_images WHERE ad_id=? ORDER BY sort_order ASC, id ASC');
$imgs->execute([$id]);
$imgRows = $imgs->fetchAll(PDO::FETCH_ASSOC);
$images = array_map(fn($x) => (string)$x['url'], $imgRows);
$imagesDetailed = array_map(fn($x) => ['id' => (int)$x['id'], 'url' => (string)$x['url'], 'sort_order' => (int)$x['sort_order']], $imgRows);

json_ok([
    'id' => (int)$r['id'],
    'author_user_id' => (int)$r['author_user_id'],
    'author_type' => $r['author_type'],
    'provider_id' => $r['provider_id'] !== null ? (int)$r['provider_id'] : null,
    'kind' => $r['kind'],
    'title' => (string)$r['title'],
    'description' => (string)($r['description'] ?? ''),
    'image_url' => (string)($r['image_url'] ?? ''),
    'images' => $images,
    'images_detailed' => $imagesDetailed,
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
]);
