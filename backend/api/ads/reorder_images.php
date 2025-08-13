<?php
require_once __DIR__ . '/../../config.php';

$claims = require_auth();
$userId = (int)($claims['id'] ?? 0);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_error('METHOD_NOT_ALLOWED', 'Use POST', 405);
}

$body = get_json_body();
require_fields($body, ['ad_id', 'order']);

$adId = (int)$body['ad_id'];
$order = $body['order']; // array of image ids in desired order OR array of urls
if (!is_array($order) || empty($order)) {
    json_error('BAD_REQUEST', 'order must be a non-empty array');
}

// Check ad ownership
$st = db()->prepare('SELECT id, author_user_id FROM ads WHERE id=?');
$st->execute([$adId]);
$ad = $st->fetch(PDO::FETCH_ASSOC);
if (!$ad) json_error('NOT_FOUND', 'Ad not found', 404);
if ((int)$ad['author_user_id'] !== $userId) json_error('FORBIDDEN', 'You cannot modify this ad', 403);

// Detect whether array contains ids (int) or urls (string)
$byIds = true;
foreach ($order as $v) {
    if (!is_int($v) && !(is_string($v) && ctype_digit($v))) {
        $byIds = false;
        break;
    }
}

// If urls given, map urls -> ids first
if (!$byIds) {
    // Normalize urls
    $norm = function ($p) {
        $p = trim((string)$p);
        if ($p === '') return '';
        if (preg_match('~/(?:kivou/)?backend/uploads/([^\s?#]+)~i', $p, $m)) return 'uploads/' . $m[1];
        if (strpos($p, '/uploads/') === 0) return ltrim($p, '/');
        if (strpos($p, 'uploads/') === 0) return $p;
        if (preg_match('~/uploads/([^\s?#]+)~i', $p, $m2)) return 'uploads/' . $m2[1];
        return $p;
    };
    $urls = array_map($norm, array_map('strval', $order));
    $in = implode(',', array_fill(0, count($urls), '?'));
    $map = db()->prepare("SELECT id, url FROM ad_images WHERE ad_id=? AND url IN ($in)");
    $map->execute(array_merge([$adId], $urls));
    $dict = [];
    foreach ($map->fetchAll(PDO::FETCH_ASSOC) as $r) {
        $dict[$r['url']] = (int)$r['id'];
    }
    $order = array_values(array_filter(array_map(function ($u) use ($dict) {
        return $dict[$u] ?? null;
    }, $urls), fn($x) => $x !== null));
}

// Apply new sort_order sequentially from 0
$upd = db()->prepare('UPDATE ad_images SET sort_order = ? WHERE ad_id = ? AND id = ?');
$i = 0;
foreach ($order as $imgId) {
    $imgId = (int)$imgId;
    $upd->execute([$i++, $adId, $imgId]);
}

// Ensure thumbnail follows new first image
$first = db()->prepare('SELECT url FROM ad_images WHERE ad_id=? ORDER BY sort_order ASC, id ASC LIMIT 1');
$first->execute([$adId]);
$fr = $first->fetch(PDO::FETCH_ASSOC);
$thumb = $fr ? (string)$fr['url'] : null;
$uu = db()->prepare('UPDATE ads SET image_url = ? WHERE id = ?');
$uu->execute([$thumb, $adId]);

json_ok([
    'ad_id' => $adId,
    'reordered' => count($order),
    'new_thumbnail' => $thumb,
]);
