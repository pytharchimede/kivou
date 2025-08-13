<?php
require_once __DIR__ . '/../../config.php';
$claims = require_auth();
$userId = (int)($claims['id'] ?? 0);
$body = get_json_body();
require_fields($body, ['kind', 'title']);

$kind = strtolower(trim((string)$body['kind'])); // request|offer
if (!in_array($kind, ['request', 'offer'], true)) {
    json_error('BAD_REQUEST', 'kind must be request or offer', 400);
}
$title = trim((string)$body['title']);
if ($title === '') json_error('BAD_REQUEST', 'title is required', 400);
$description = isset($body['description']) ? trim((string)$body['description']) : null;
$imageUrl = isset($body['image_url']) ? trim((string)$body['image_url']) : null;
$imageLegacy = isset($body['image']) ? trim((string)$body['image']) : null;
$imagesArray = isset($body['images']) && is_array($body['images']) ? $body['images'] : [];
$imagesCsv = isset($body['image_urls']) ? trim((string)$body['image_urls']) : '';
$amount = isset($body['amount']) ? (float)$body['amount'] : null;
$currency = isset($body['currency']) ? strtoupper(trim((string)$body['currency'])) : 'XOF';
$category = isset($body['category']) ? trim((string)$body['category']) : null;
$lat = isset($body['lat']) ? (float)$body['lat'] : null;
$lng = isset($body['lng']) ? (float)$body['lng'] : null;
$authorType = isset($body['author_type']) ? strtolower(trim((string)$body['author_type'])) : 'client'; // client|provider
if (!in_array($authorType, ['client', 'provider'], true)) $authorType = 'client';
$providerId = isset($body['provider_id']) ? (int)$body['provider_id'] : null;

// Si publication en tant que provider, vérifier ownership
if ($authorType === 'provider') {
    if (!$providerId) json_error('BAD_REQUEST', 'provider_id requis pour author_type=provider', 400);
    $st = db()->prepare('SELECT owner_user_id FROM service_providers WHERE id=?');
    $st->execute([$providerId]);
    $row = $st->fetch(PDO::FETCH_ASSOC);
    if (!$row) json_error('BAD_REQUEST', 'Prestataire introuvable', 400);
    if ((int)($row['owner_user_id'] ?? 0) !== $userId) {
        json_error('FORBIDDEN', 'Vous n\'êtes pas propriétaire de ce prestataire', 403);
    }
}

// Normalize image path to server-relative uploads path when possible
$normalize = function ($p) {
    $p = trim((string)$p);
    if ($p === '') return '';
    if (preg_match('~/(?:kivou/)?backend/uploads/([^\s?#]+)~i', $p, $m)) {
        return 'uploads/' . $m[1];
    }
    if (strpos($p, '/uploads/') === 0) {
        return ltrim($p, '/');
    }
    if (strpos($p, 'uploads/') === 0) {
        return $p;
    }
    if (preg_match('~/uploads/([^\s?#]+)~i', $p, $m2)) {
        return 'uploads/' . $m2[1];
    }
    return $p;
};

// Determine first image candidate
$firstImage = '';
if (!empty($imagesArray)) {
    foreach ($imagesArray as $im) {
        if (!is_string($im)) continue;
        $n = $normalize($im);
        if ($n !== '') {
            $firstImage = $n;
            break;
        }
    }
}
if ($firstImage === '' && $imagesCsv !== '') {
    foreach (explode(',', $imagesCsv) as $im) {
        $n = $normalize($im);
        if ($n !== '') {
            $firstImage = $n;
            break;
        }
    }
}
if ($firstImage === '' && !empty($imageLegacy)) {
    $firstImage = $normalize($imageLegacy);
}
if ($firstImage === '' && !empty($imageUrl)) {
    $firstImage = $normalize($imageUrl);
}

$ins = db()->prepare('INSERT INTO ads(author_user_id,author_type,provider_id,kind,title,description,image_url,amount,currency,category,lat,lng,status) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,\'active\')');
$ins->execute([$userId, $authorType, $providerId, $kind, $title, $description, ($firstImage !== '' ? $firstImage : null), $amount, $currency, $category, $lat, $lng]);
$id = (int)db()->lastInsertId();

$ad = db()->prepare('SELECT * FROM ads WHERE id=?');
$ad->execute([$id]);
$row = $ad->fetch(PDO::FETCH_ASSOC);

json_ok([
    'id' => (int)$row['id'],
    'author_user_id' => (int)$row['author_user_id'],
    'author_type' => $row['author_type'],
    'provider_id' => $row['provider_id'] !== null ? (int)$row['provider_id'] : null,
    'kind' => $row['kind'],
    'title' => (string)$row['title'],
    'description' => (string)($row['description'] ?? ''),
    'image_url' => (string)($row['image_url'] ?? ''),
    'amount' => isset($row['amount']) ? (float)$row['amount'] : null,
    'currency' => (string)($row['currency'] ?? 'XOF'),
    'category' => (string)($row['category'] ?? ''),
    'lat' => isset($row['lat']) ? (float)$row['lat'] : null,
    'lng' => isset($row['lng']) ? (float)$row['lng'] : null,
    'status' => (string)$row['status'],
    'created_at' => date('c', strtotime($row['created_at'])),
    'updated_at' => date('c', strtotime($row['updated_at'])),
    // Optionally echo back a simple images array built from ad_images table
    'images' => (function ($adId) {
        $st = db()->prepare('SELECT url FROM ad_images WHERE ad_id=? ORDER BY sort_order ASC, id ASC');
        $st->execute([$adId]);
        $r = $st->fetchAll(PDO::FETCH_ASSOC);
        $out = array_map(function ($x) {
            return (string)$x['url'];
        }, $r);
        return $out;
    })($id),
]);
