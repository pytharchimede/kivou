<?php
require_once __DIR__ . '/../../config.php';
$claims = require_auth();
$userId = (int)($claims['id'] ?? 0);

$st = db()->prepare('SELECT id,owner_user_id,name,email,phone,photo_url,description,categories,rating,reviews_count,price_per_hour,latitude,longitude,gallery,available_days,working_start,working_end,is_available,created_at FROM service_providers WHERE owner_user_id = ? ORDER BY created_at DESC');
$st->execute([$userId]);
$rows = $st->fetchAll(PDO::FETCH_ASSOC);

$out = array_map(function ($r) {
    return [
        'id' => (string)$r['id'],
        'owner_user_id' => isset($r['owner_user_id']) ? (int)$r['owner_user_id'] : null,
        'name' => (string)$r['name'],
        'email' => (string)$r['email'],
        'phone' => (string)$r['phone'],
        'photo_url' => (string)($r['photo_url'] ?? ''),
        'description' => (string)($r['description'] ?? ''),
        'categories' => (string)($r['categories'] ?? ''),
        'rating' => (float)($r['rating'] ?? 0),
        'reviews_count' => (int)($r['reviews_count'] ?? 0),
        'price_per_hour' => (float)$r['price_per_hour'],
        'latitude' => (float)$r['latitude'],
        'longitude' => (float)$r['longitude'],
        'gallery' => (string)($r['gallery'] ?? ''),
        'available_days' => (string)($r['available_days'] ?? ''),
        'working_start' => (string)($r['working_start'] ?? ''),
        'working_end' => (string)($r['working_end'] ?? ''),
        'is_available' => (int)($r['is_available'] ?? 1) === 1,
        'created_at' => (string)$r['created_at'],
    ];
}, $rows);

json_ok($out);
