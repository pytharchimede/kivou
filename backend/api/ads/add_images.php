<?php
require_once __DIR__ . '/../../config.php';

$claims = require_auth();
$userId = (int)($claims['id'] ?? 0);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_error('METHOD_NOT_ALLOWED', 'Use POST', 405);
}

$body = get_json_body();
require_fields($body, ['ad_id', 'images']);

$adId = (int)$body['ad_id'];
$images = $body['images'];
if (!is_array($images)) {
    json_error('BAD_REQUEST', 'images must be an array');
}

// Normalize a single image path to a server-relative uploads path when possible
function norm_path($p)
{
    $p = trim((string)$p);
    if ($p === '') return '';
    // capture after backend/uploads/ or /uploads/
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
    return $p; // as-is
}

// Check ad ownership
$st = db()->prepare('SELECT id, author_user_id, image_url FROM ads WHERE id=?');
$st->execute([$adId]);
$ad = $st->fetch(PDO::FETCH_ASSOC);
if (!$ad) {
    json_error('NOT_FOUND', 'Ad not found', 404);
}
if ((int)$ad['author_user_id'] !== $userId) {
    json_error('FORBIDDEN', 'You cannot modify this ad', 403);
}

// Fetch existing URLs to avoid duplicates
$existing = db()->prepare('SELECT url FROM ad_images WHERE ad_id = ?');
$existing->execute([$adId]);
$existingUrls = array_map(function ($r) {
    return (string)$r['url'];
}, $existing->fetchAll(PDO::FETCH_ASSOC));
$existingSet = array_fill_keys($existingUrls, true);

// Determine start order
$maxSt = db()->prepare('SELECT COALESCE(MAX(sort_order), -1) AS m FROM ad_images WHERE ad_id = ?');
$maxSt->execute([$adId]);
$row = $maxSt->fetch(PDO::FETCH_ASSOC);
$order = (int)($row['m'] ?? -1);

$ins = db()->prepare('INSERT INTO ad_images(ad_id, url, sort_order) VALUES (?,?,?)');
$created = [];
foreach ($images as $idx => $img) {
    if (!is_string($img)) continue;
    $u = norm_path($img);
    if ($u === '') continue;
    if (isset($existingSet[$u])) continue; // skip duplicates
    $order++;
    $ins->execute([$adId, $u, $order]);
    $created[] = $u;
}

// If no thumbnail set yet and at least one created, set first as image_url
if ((empty($ad['image_url']) || trim((string)$ad['image_url']) === '') && !empty($created)) {
    $upd = db()->prepare('UPDATE ads SET image_url = ? WHERE id = ?');
    $upd->execute([$created[0], $adId]);
}

json_ok([
    'ad_id' => $adId,
    'inserted' => count($created),
    'images' => $created,
]);
